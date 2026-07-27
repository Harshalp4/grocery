using System.IdentityModel.Tokens.Jwt;
using System.Text.Json;
using Microsoft.IdentityModel.Tokens;

namespace FarmFresh.Api.Services;

/// Verifies Google / Apple identity tokens server-side. Both need their client
/// id configured (GOOGLE_CLIENT_ID / APPLE_CLIENT_ID, comma-separated for
/// multiple platforms); without it the corresponding provider is disabled and
/// the endpoint returns a clear "not configured" error.
public record SocialUser(string Subject, string? Email, string? Name);

public static class SocialAuth
{
    private static readonly HttpClient _http = new();

    private static string[] Audiences(string envVar) =>
        (Environment.GetEnvironmentVariable(envVar) ?? "")
        .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

    public static bool GoogleConfigured => Audiences("GOOGLE_CLIENT_ID").Length > 0;
    public static bool AppleConfigured => Audiences("APPLE_CLIENT_ID").Length > 0;

    /// Validate a Google ID token via Google's tokeninfo endpoint and check the
    /// audience matches one of our client ids. Returns null if invalid.
    public static async Task<SocialUser?> VerifyGoogle(string idToken)
    {
        var auds = Audiences("GOOGLE_CLIENT_ID");
        if (auds.Length == 0) return null;
        try
        {
            var res = await _http.GetAsync(
                $"https://oauth2.googleapis.com/tokeninfo?id_token={Uri.EscapeDataString(idToken)}");
            if (!res.IsSuccessStatusCode) return null;
            var p = JsonDocument.Parse(await res.Content.ReadAsStringAsync()).RootElement;
            var aud = Str(p, "aud");
            var iss = Str(p, "iss");
            var sub = Str(p, "sub");
            if (sub == null || aud == null || !auds.Contains(aud)) return null;
            if (iss != "accounts.google.com" && iss != "https://accounts.google.com") return null;
            return new SocialUser(sub, Str(p, "email"), Str(p, "name"));
        }
        catch { return null; }
    }

    /// Validate an Apple identity token against Apple's public keys (JWKS) and
    /// check issuer + audience. Apple only returns the name on first sign-in, so
    /// the client passes it separately.
    public static async Task<SocialUser?> VerifyApple(string identityToken, string? name)
    {
        var auds = Audiences("APPLE_CLIENT_ID");
        if (auds.Length == 0) return null;
        try
        {
            var jwks = await _http.GetStringAsync("https://appleid.apple.com/auth/keys");
            var keys = new JsonWebKeySet(jwks).GetSigningKeys();
            var result = new JwtSecurityTokenHandler().ValidateToken(identityToken,
                new TokenValidationParameters
                {
                    ValidIssuer = "https://appleid.apple.com",
                    ValidateIssuer = true,
                    ValidAudiences = auds,
                    ValidateAudience = true,
                    IssuerSigningKeys = keys,
                    ValidateIssuerSigningKey = true,
                    ValidateLifetime = true,
                }, out _);
            var sub = result.FindFirst("sub")?.Value;
            if (sub == null) return null;
            return new SocialUser(sub, result.FindFirst("email")?.Value, name);
        }
        catch { return null; }
    }

    private static string? Str(JsonElement e, string k)
        => e.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
}
