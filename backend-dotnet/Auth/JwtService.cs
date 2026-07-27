using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace FarmFresh.Api.Auth;

// Issues/loads the two token kinds the original backend used (see src/auth.ts,
// src/customerAuth.ts): admin { sub, role:'admin' } (12h) and
// customer { sub, phone, role:'customer' } (30d). HS256, loose validation
// (signature + expiry only), matching jsonwebtoken's defaults.
public class JwtService
{
    private readonly string _secret;
    private readonly string _adminEmail;
    private readonly string _adminPassword;

    public JwtService(IConfiguration config)
    {
        _secret = config["Jwt:Secret"] ?? "dev-secret";
        _adminEmail = config["Admin:Email"] ?? "admin@farmfresh.local";
        _adminPassword = config["Admin:Password"] ?? "farmfresh123";
    }

    public string Secret => _secret;

    /// True if the credentials match the env bootstrap admin (superadmin).
    /// Uses fixed-time comparison so login timing doesn't leak the secret.
    public bool IsBootstrapAdmin(string email, string password)
        => FixedTimeEquals(email, _adminEmail) & FixedTimeEquals(password, _adminPassword);

    /// Issue a 12h admin token carrying the back-office role.
    public string IssueAdminToken(string email, string adminRole) => Sign(new[]
    {
        new Claim("sub", email),
        new Claim("role", "admin"),
        new Claim("adminRole", adminRole),
    }, TimeSpan.FromHours(12));

    /// Issue a 30d customer token.
    public string SignCustomerToken(string userId, string phone, int tokenVersion) => Sign(new[]
    {
        new Claim("sub", userId),
        new Claim("phone", phone),
        new Claim("role", "customer"),
        new Claim("tv", tokenVersion.ToString()),   // revocation guard
    }, TimeSpan.FromDays(30));

    /// Issue a 7d delivery-partner token. The `tv` claim enables instant revocation.
    public string SignPartnerToken(string partnerId, string phone, int tokenVersion) => Sign(new[]
    {
        new Claim("sub", partnerId),
        new Claim("phone", phone),
        new Claim("role", "partner"),
        new Claim("tv", tokenVersion.ToString()),
    }, TimeSpan.FromDays(7));

    private static bool FixedTimeEquals(string a, string b)
        => CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(a), Encoding.UTF8.GetBytes(b));

    private string Sign(IEnumerable<Claim> claims, TimeSpan ttl)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            claims: claims,
            expires: DateTime.UtcNow.Add(ttl),
            signingCredentials: creds);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
