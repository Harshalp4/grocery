using System.IdentityModel.Tokens.Jwt;
using System.Text.Json;
using Microsoft.IdentityModel.Tokens;

namespace FarmFresh.Api.Services;

/// Verifies identity tokens server-side. The app signs Google/Apple in through
/// Firebase Authentication and sends the resulting Firebase ID token, which is
/// verified here (VerifyFirebase, needs FIREBASE_PROJECT_ID). The direct Google
/// tokeninfo / Apple JWKS paths are kept as alternatives.
public record SocialUser(string Subject, string? Email, string? Name, string? Provider = null);

public static class SocialAuth
{
    private static readonly HttpClient _http = new();

    private static string[] Audiences(string envVar) =>
        (Environment.GetEnvironmentVariable(envVar) ?? "")
        .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

    public static bool GoogleConfigured => Audiences("GOOGLE_CLIENT_ID").Length > 0;
    public static bool AppleConfigured => Audiences("APPLE_CLIENT_ID").Length > 0;
    public static bool FirebaseConfigured =>
        !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("FIREBASE_PROJECT_ID"));

    /// Validate a Firebase Authentication ID token (Google/Apple sign-in flow
    /// through Firebase). Checks issuer + audience against FIREBASE_PROJECT_ID
    /// and the signature against Google's securetoken public keys.
    public static async Task<SocialUser?> VerifyFirebase(string idToken)
    {
        var projectId = Environment.GetEnvironmentVariable("FIREBASE_PROJECT_ID");
        if (string.IsNullOrEmpty(projectId)) return null;
        try
        {
            var jwks = await _http.GetStringAsync(
                "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com");
            var keys = new JsonWebKeySet(jwks).GetSigningKeys();
            var result = new JwtSecurityTokenHandler().ValidateToken(idToken,
                new TokenValidationParameters
                {
                    ValidIssuer = $"https://securetoken.google.com/{projectId}",
                    ValidateIssuer = true,
                    ValidAudience = projectId,
                    ValidateAudience = true,
                    IssuerSigningKeys = keys,
                    ValidateIssuerSigningKey = true,
                    ValidateLifetime = true,
                }, out _);
            var sub = result.FindFirst("sub")?.Value ?? result.FindFirst("user_id")?.Value;
            if (sub == null) return null;

            // The provider (google.com / apple.com) is nested under the "firebase" claim.
            string? provider = null;
            var fb = result.FindFirst("firebase")?.Value;
            if (fb != null)
                try { provider = JsonDocument.Parse(fb).RootElement
                    .GetProperty("sign_in_provider").GetString(); }
                catch { /* leave null */ }

            return new SocialUser(sub, result.FindFirst("email")?.Value,
                result.FindFirst("name")?.Value,
                provider switch { "google.com" => "google", "apple.com" => "apple", _ => null });
        }
        catch { return null; }
    }

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
