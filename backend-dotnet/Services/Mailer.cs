using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace FarmFresh.Api.Services;

/// Transactional email via Resend (https://resend.com). No-ops in dev (logs the
/// code) until RESEND_API_KEY is set, so email-OTP login is testable without an
/// account. The OTP is also returned in the API response while Otp.DevMode is on.
public static class Mailer
{
    private static readonly HttpClient _http = new();

    private static string? ApiKey => Environment.GetEnvironmentVariable("RESEND_API_KEY");
    private static string From =>
        Environment.GetEnvironmentVariable("RESEND_FROM") ?? "FarmFresh <onboarding@resend.dev>";
    public static bool Configured => !string.IsNullOrEmpty(ApiKey);

    /// Send the login code. Fire-and-forget: a slow mail provider never blocks
    /// the request, and dev flows read the code from the response instead.
    public static void SendOtp(string email, string code)
    {
        if (!Configured)
        {
            Console.WriteLine($"[EMAIL OTP stub] {email} -> {code}");
            return;
        }
        _ = SendAsync(email, "Your FarmFresh code",
            $"""
             <div style="font-family:system-ui,sans-serif;max-width:420px;margin:auto">
               <h2 style="color:#2F6B46">FarmFresh</h2>
               <p>Your one-time sign-in code is:</p>
               <p style="font-size:30px;font-weight:800;letter-spacing:6px;color:#16241b">{code}</p>
               <p style="color:#6c7871;font-size:13px">This code expires in 5 minutes. If you didn't
               request it, you can ignore this email.</p>
             </div>
             """);
    }

    private static async Task SendAsync(string to, string subject, string html)
    {
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, "https://api.resend.com/emails");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ApiKey);
            req.Content = JsonContent.Create(new { from = From, to = new[] { to }, subject, html });
            var res = await _http.SendAsync(req);
            Console.WriteLine($"[EMAIL] {to} \"{subject}\": {(int)res.StatusCode}");
        }
        catch (Exception e)
        {
            Console.WriteLine($"[EMAIL error] {e.Message}");
        }
    }
}
