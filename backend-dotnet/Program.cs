using System.IdentityModel.Tokens.Jwt;
using System.Text;
using System.Text.Json.Serialization;
using FarmFresh.Api.Auth;
using FarmFresh.Api.Data;
using FarmFresh.Api.Seeding;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

// Keep raw JWT claim names ("sub", "role", "phone") instead of the SOAP-style
// mapping .NET applies by default — matches how jsonwebtoken signed them.
JwtSecurityTokenHandler.DefaultMapInboundClaims = false;

// Load a local, gitignored .env into the process environment for dev secrets
// (RESEND_API_KEY, FIREBASE_PROJECT_ID, ...) so they never live in the repo.
// Real env vars always win. In production, set these on the host instead.
if (File.Exists(".env"))
{
    foreach (var raw in File.ReadAllLines(".env"))
    {
        var line = raw.Trim();
        var eq = line.IndexOf('=');
        if (line.Length == 0 || line.StartsWith('#') || eq <= 0) continue;
        var key = line[..eq].Trim();
        var val = line[(eq + 1)..].Trim().Trim('"');
        if (Environment.GetEnvironmentVariable(key) is null)
            Environment.SetEnvironmentVariable(key, val);
    }
}

var builder = WebApplication.CreateBuilder(args);

// Hosts (Render/Railway/Fly) inject the port to listen on. Bind to it on all
// interfaces; local dev falls back to the appsettings "Urls" (localhost:4000).
var port = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrEmpty(port)) builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

// --- Database: PostgreSQL via EF Core (Npgsql) ---
// Prefer a managed-Postgres URL (DATABASE_URL, e.g. from Render), then a
// configured connection string (ConnectionStrings:Default / ConnectionStrings__Default),
// then the local dev default.
var connString = ConnFromDatabaseUrl()
                 ?? builder.Configuration.GetConnectionString("Default")
                 ?? "Host=localhost;Port=5432;Database=farmfresh;Username=postgres;Password=postgres";
builder.Services.AddDbContext<AppDbContext>(opts => opts.UseNpgsql(connString));

static string? ConnFromDatabaseUrl()
{
    var url = Environment.GetEnvironmentVariable("DATABASE_URL");
    if (string.IsNullOrEmpty(url)) return null;
    var uri = new Uri(url);
    var creds = uri.UserInfo.Split(':', 2);
    return new NpgsqlConnectionStringBuilder
    {
        Host = uri.Host,
        Port = uri.Port > 0 ? uri.Port : 5432,
        Username = Uri.UnescapeDataString(creds[0]),
        Password = creds.Length > 1 ? Uri.UnescapeDataString(creds[1]) : "",
        Database = uri.AbsolutePath.TrimStart('/'),
        SslMode = SslMode.Require,          // managed Postgres requires TLS
    }.ConnectionString;
}

builder.Services.AddSingleton<JwtService>();
builder.Services.AddSingleton<RateLimiter>();

// --- CORS: allow any origin by default (JWT-in-header API, no cookies), or lock
// down to a comma-separated ALLOWED_ORIGINS list (e.g. your Vercel admin URL). ---
var allowedOrigins = Environment.GetEnvironmentVariable("ALLOWED_ORIGINS");
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
{
    if (!string.IsNullOrWhiteSpace(allowedOrigins))
        p.WithOrigins(allowedOrigins.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .AllowAnyHeader().AllowAnyMethod();
    else
        p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
}));

// --- Auth: HS256, validate signature + expiry only (loose, like jsonwebtoken) ---
var jwtSecret = builder.Configuration["Jwt:Secret"] ?? "dev-secret";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ClockSkew = TimeSpan.FromMinutes(1),
        };
        // Server-side revocation for customer tokens: reject if the user was
        // deleted, or if their TokenVersion has moved on (logout-everywhere).
        // Admin tokens have no user row and partner tokens self-validate in
        // LoadPartner, so both are skipped.
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async ctx =>
            {
                if (ctx.Principal?.FindFirst("role")?.Value != "customer") return;
                var sub = ctx.Principal.FindFirst("sub")?.Value;
                var tv = ctx.Principal.FindFirst("tv")?.Value;
                var db = ctx.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
                var current = await db.Users.AsNoTracking()
                    .Where(u => u.Id == sub)
                    .Select(u => (int?)u.TokenVersion)
                    .FirstOrDefaultAsync();
                if (current == null || tv != current.Value.ToString())
                    ctx.Fail("Token no longer valid");
            },
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("Admin", p => p.RequireClaim("role", "admin"));
    options.AddPolicy("Customer", p => p.RequireClaim("role", "customer"));
    options.AddPolicy("Partner", p => p.RequireClaim("role", "partner"));
});

// Controllers with camelCase JSON (ASP.NET Core's default), nulls preserved so
// responses match the original Express/Prisma output byte-for-byte where it matters.
builder.Services.AddControllers().AddJsonOptions(o =>
{
    o.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.Never;
    // EF relationship fixup creates parent<->child cycles; break them instead of throwing.
    o.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
});

var app = builder.Build();

// Apply EF Core migrations (creates/updates the schema) and seed the demo data.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    SeedData.Run(db);
}

app.UseCors();

// Serve uploaded product images at /uploads (analog of express.static('uploads')).
var uploadsPath = Path.Combine(app.Environment.ContentRootPath, "uploads");
Directory.CreateDirectory(uploadsPath);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsPath),
    RequestPath = "/uploads",
});

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Json(new { ok = true, service = "farmfresh" }));
app.MapControllers();

// 404 fallback with the same JSON body as the original.
app.MapFallback(() => Results.Json(new { error = "Not found" }, statusCode: 404));

app.Run();
