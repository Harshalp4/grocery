using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace FarmFresh.Api.Services;

/// Uploads images to Cloudinary when configured (CLOUDINARY_URL), returning the
/// permanent CDN URL. Falls back to local disk (dev / unconfigured) so the app
/// works unchanged. Signed uploads — no SDK dependency.
///
/// CLOUDINARY_URL format: cloudinary://<api_key>:<api_secret>@<cloud_name>
public static class ImageStore
{
    private static readonly HttpClient _http = new();

    // cloudinary://<api_key>:<api_secret>@<cloud_name> — parsed deterministically
    // (System.Uri mishandles the custom scheme and can drop the api_key).
    private static (string cloud, string key, string secret)? Creds()
    {
        var url = Environment.GetEnvironmentVariable("CLOUDINARY_URL")?.Trim();
        if (string.IsNullOrEmpty(url)) return null;
        var m = Regex.Match(url, @"^cloudinary://([^:]+):([^@]+)@(.+)$");
        return m.Success ? (m.Groups[3].Value.Trim(), m.Groups[1].Value.Trim(), m.Groups[2].Value.Trim()) : null;
    }

    public static bool Configured => Creds() != null;

    /// Upload bytes; returns (url, null) on success or (null, error) on failure.
    public static async Task<(string? url, string? error)> UploadAsync(
        byte[] bytes, string ext, string folder, string publicId)
    {
        var c = Creds();
        if (c == null) return (null, "Cloudinary not configured");
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
            var bodyText = await res.Content.ReadAsStringAsync();
            if (!res.IsSuccessStatusCode)
            {
                Console.WriteLine($"[Cloudinary] {(int)res.StatusCode}: {bodyText}");
                return (null, $"cloudinary {(int)res.StatusCode}: {bodyText}");
            }
            var url = JsonDocument.Parse(bodyText).RootElement.GetProperty("secure_url").GetString();
            return (url, null);
        }
        catch (Exception e)
        {
            Console.WriteLine($"[Cloudinary error] {e.Message}");
            return (null, e.Message);
        }
    }

    private static string Sha1Hex(string s)
        => Convert.ToHexString(SHA1.HashData(Encoding.UTF8.GetBytes(s))).ToLowerInvariant();
}
