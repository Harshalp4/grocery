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
        Environment.GetEnvironmentVariable("RESEND_FROM") ?? "Green Epicure <onboarding@resend.dev>";
    public static bool Configured => !string.IsNullOrEmpty(ApiKey);

    // Where new-order alerts go. Prefer a dedicated ORDER_ALERT_EMAIL (a real
    // inbox); fall back to the admin login email if that's a real address.
    private static string? AlertRecipient =>
        Environment.GetEnvironmentVariable("ORDER_ALERT_EMAIL")
        ?? Environment.GetEnvironmentVariable("Admin__Email");

    /// Send the login code. Fire-and-forget: a slow mail provider never blocks
    /// the request, and dev flows read the code from the response instead.
    public static void SendOtp(string email, string code)
    {
        if (!Configured)
        {
            Console.WriteLine($"[EMAIL OTP stub] {email} -> {code}");
            return;
        }
        _ = SendAsync(email, "Your Green Epicure code",
            $"""
             <div style="font-family:system-ui,sans-serif;max-width:420px;margin:auto">
               <h2 style="color:#2F6B46">Green Epicure</h2>
               <p>Your one-time sign-in code is:</p>
               <p style="font-size:30px;font-weight:800;letter-spacing:6px;color:#16241b">{code}</p>
               <p style="color:#6c7871;font-size:13px">This code expires in 5 minutes. If you didn't
               request it, you can ignore this email.</p>
             </div>
             """);
    }

    /// Alert the shop that a new order arrived. Fire-and-forget; no-ops (logs)
    /// until RESEND_API_KEY + a recipient are set. Customer-supplied text is
    /// HTML-encoded so a name/address can't inject markup into the email.
    public static void SendOrderAlert(string code, int total, int itemQty,
        string customerName, string phone, string address, string slot,
        string paymentMethod)
    {
        var to = AlertRecipient;
        if (!Configured || string.IsNullOrWhiteSpace(to))
        {
            Console.WriteLine($"[ORDER ALERT stub] {code} ₹{total} -> {to ?? "(no recipient)"}");
            return;
        }
        string Esc(string s) => System.Net.WebUtility.HtmlEncode(s);
        _ = SendAsync(to, $"🛒 New order {code} · ₹{total}",
            $"""
             <div style="font-family:system-ui,sans-serif;max-width:480px;margin:auto">
               <h2 style="color:#2F6B46;margin-bottom:4px">New order {Esc(code)}</h2>
               <p style="font-size:22px;font-weight:800;color:#16241b;margin:0">₹{total} · {itemQty} item(s)</p>
               <table style="margin-top:14px;font-size:14px;color:#2b342e;border-collapse:collapse">
                 <tr><td style="padding:3px 12px 3px 0;color:#6c7871">Customer</td><td>{Esc(customerName)} · {Esc(phone)}</td></tr>
                 <tr><td style="padding:3px 12px 3px 0;color:#6c7871">Address</td><td>{Esc(address)}</td></tr>
                 <tr><td style="padding:3px 12px 3px 0;color:#6c7871">Slot</td><td>{Esc(slot)}</td></tr>
                 <tr><td style="padding:3px 12px 3px 0;color:#6c7871">Payment</td><td>{Esc(paymentMethod).ToUpperInvariant()}</td></tr>
               </table>
               <p style="color:#6c7871;font-size:13px;margin-top:16px">Open the admin panel to accept &amp; assign a rider.</p>
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
