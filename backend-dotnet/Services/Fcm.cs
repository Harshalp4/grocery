using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace FarmFresh.Api.Services;

/// Sends push via the FCM HTTP v1 API, authenticated with a Firebase
/// service-account JSON (the modern replacement for the retired server key).
///
/// Provide the service account in env var FIREBASE_SERVICE_ACCOUNT — either the
/// raw JSON, or a path to the .json file. Unconfigured = no-op.
public static class Fcm
{
    private static readonly HttpClient _http = new();

    private sealed class ServiceAccount
    {
        [JsonPropertyName("project_id")] public string ProjectId { get; set; } = "";
        [JsonPropertyName("client_email")] public string ClientEmail { get; set; } = "";
        [JsonPropertyName("private_key")] public string PrivateKey { get; set; } = "";
        [JsonPropertyName("token_uri")] public string TokenUri { get; set; } = "https://oauth2.googleapis.com/token";
    }

    private static readonly Lazy<ServiceAccount?> _sa = new(() =>
    {
        var raw = Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT");
        if (string.IsNullOrWhiteSpace(raw)) return null;
        try
        {
            var json = raw.TrimStart().StartsWith('{') ? raw
                       : (File.Exists(raw) ? File.ReadAllText(raw) : null);
            return json == null ? null : JsonSerializer.Deserialize<ServiceAccount>(json);
        }
        catch (Exception e) { Console.WriteLine($"[FCM] bad service account: {e.Message}"); return null; }
    });

    public static bool Configured => _sa.Value != null;

    private static string? _accessToken;
    private static DateTime _tokenExpiry;
    private static readonly SemaphoreSlim _tokenLock = new(1, 1);

    /// Send a notification to each device token (HTTP v1 is one token per call).
    public static async Task SendAsync(IEnumerable<string> tokens, string title, string body, string? orderId)
    {
        var sa = _sa.Value;
        if (sa == null) return;
        var access = await GetAccessTokenAsync(sa);
        if (access == null) return;

        var data = new Dictionary<string, string> { ["type"] = "order" };
        if (!string.IsNullOrEmpty(orderId)) data["orderId"] = orderId;

        foreach (var token in tokens)
        {
            try
            {
                using var req = new HttpRequestMessage(HttpMethod.Post,
                    $"https://fcm.googleapis.com/v1/projects/{sa.ProjectId}/messages:send");
                req.Headers.TryAddWithoutValidation("Authorization", $"Bearer {access}");
                req.Content = JsonContent.Create(new
                {
                    message = new { token, notification = new { title, body }, data },
                });
                var res = await _http.SendAsync(req);
                if (!res.IsSuccessStatusCode)
                    Console.WriteLine($"[FCM] {(int)res.StatusCode}: {await res.Content.ReadAsStringAsync()}");
            }
            catch (Exception e) { Console.WriteLine($"[FCM error] {e.Message}"); }
        }
    }

    /// OAuth2 access token from the service account (JWT-bearer grant), cached.
    private static async Task<string?> GetAccessTokenAsync(ServiceAccount sa)
    {
        if (_accessToken != null && DateTime.UtcNow < _tokenExpiry) return _accessToken;
        await _tokenLock.WaitAsync();
        try
        {
            if (_accessToken != null && DateTime.UtcNow < _tokenExpiry) return _accessToken;
            var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            var header = B64Url(Encoding.UTF8.GetBytes("""{"alg":"RS256","typ":"JWT"}"""));
            var claims = B64Url(JsonSerializer.SerializeToUtf8Bytes(new
            {
                iss = sa.ClientEmail,
                scope = "https://www.googleapis.com/auth/firebase.messaging",
                aud = sa.TokenUri,
                iat = now,
                exp = now + 3600,
            }));
            var unsigned = $"{header}.{claims}";
            using var rsa = RSA.Create();
            rsa.ImportFromPem(sa.PrivateKey);
            var sig = rsa.SignData(Encoding.UTF8.GetBytes(unsigned), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
            var jwt = $"{unsigned}.{B64Url(sig)}";

            var res = await _http.PostAsync(sa.TokenUri, new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer",
                ["assertion"] = jwt,
            }));
            if (!res.IsSuccessStatusCode)
            {
                Console.WriteLine($"[FCM] token {(int)res.StatusCode}: {await res.Content.ReadAsStringAsync()}");
                return null;
            }
            var json = JsonDocument.Parse(await res.Content.ReadAsStringAsync()).RootElement;
            _accessToken = json.GetProperty("access_token").GetString();
            _tokenExpiry = DateTime.UtcNow.AddSeconds(json.GetProperty("expires_in").GetInt32() - 60);
            return _accessToken;
        }
        catch (Exception e) { Console.WriteLine($"[FCM token error] {e.Message}"); return null; }
        finally { _tokenLock.Release(); }
    }

    private static string B64Url(byte[] b) =>
        Convert.ToBase64String(b).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
