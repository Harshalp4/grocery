using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace FarmFresh.Api.Services;

/// Uploads images to Cloudinary when configured (CLOUDINARY_URL), returning the
/// permanent CDN URL. Falls back to local disk (dev / unconfigured) so the app
/// works unchanged. Signed uploads — no SDK dependency.
///
/// CLOUDINARY_URL format: cloudinary://<api_key>:<api_secret>@<cloud_name>
public static class ImageStore
{
    private static readonly HttpClient _http = new();

    private static (string cloud, string key, string secret)? Creds()
    {
        var url = Environment.GetEnvironmentVariable("CLOUDINARY_URL");
        if (string.IsNullOrWhiteSpace(url)) return null;
        try
        {
            var u = new Uri(url);
            var parts = u.UserInfo.Split(':', 2);
            if (parts.Length < 2 || string.IsNullOrEmpty(u.Host)) return null;
            return (u.Host, Uri.UnescapeDataString(parts[0]), Uri.UnescapeDataString(parts[1]));
        }
        catch { return null; }
    }

    public static bool Configured => Creds() != null;

    /// Upload bytes and return the secure CDN URL, or null on failure.
    public static async Task<string?> UploadAsync(byte[] bytes, string ext, string folder, string publicId)
    {
        var c = Creds();
        if (c == null) return null;
        var (cloud, key, secret) = c.Value;
        try
        {
            var ts = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
            // Signature = SHA1 of the signed params (sorted) + api_secret.
            var signature = Sha1Hex($"folder={folder}&public_id={publicId}&timestamp={ts}{secret}");

            using var form = new MultipartFormDataContent();
            var file = new ByteArrayContent(bytes);
            file.Headers.ContentType = new MediaTypeHeaderValue($"image/{ext}");
            form.Add(file, "file", $"{publicId}.{ext}");
            form.Add(new StringContent(key), "api_key");
            form.Add(new StringContent(ts), "timestamp");
            form.Add(new StringContent(folder), "folder");
            form.Add(new StringContent(publicId), "public_id");
            form.Add(new StringContent(signature), "signature");

            var res = await _http.PostAsync(
                $"https://api.cloudinary.com/v1_1/{cloud}/image/upload", form);
            if (!res.IsSuccessStatusCode)
            {
                Console.WriteLine($"[Cloudinary] upload failed: {(int)res.StatusCode}");
                return null;
            }
            var json = JsonDocument.Parse(await res.Content.ReadAsStringAsync()).RootElement;
            return json.GetProperty("secure_url").GetString();
        }
        catch (Exception e)
        {
            Console.WriteLine($"[Cloudinary error] {e.Message}");
            return null;
        }
    }

    private static string Sha1Hex(string s)
        => Convert.ToHexString(SHA1.HashData(Encoding.UTF8.GetBytes(s))).ToLowerInvariant();
}
