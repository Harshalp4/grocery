using System.Net.Http.Json;
using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Services;

// Creates in-app notifications (the customer inbox) and fires a push. Push
// delivery is a no-op stub until FCM is configured — the inbox works either
// way, so the app is fully testable without Firebase.
//
// To go live, set ONE of:
//   FCM_SERVER_KEY               -> legacy HTTP API (simplest; being retired)
//   FIREBASE_SERVICE_ACCOUNT     -> path to a service-account JSON for HTTP v1
// and drop the matching google-services.json / GoogleService-Info.plist into
// the apps. See PUSH_NOTIFICATIONS.md.
public static class Notify
{
    private static readonly HttpClient _http = new();

    private static string? ServerKey =>
        Environment.GetEnvironmentVariable("FCM_SERVER_KEY");
    private static bool FcmConfigured => !string.IsNullOrEmpty(ServerKey);

    public static async Task ToUser(AppDbContext db, string userId, string title, string body,
        string type, string? orderId = null)
    {
        db.Notifications.Add(new Notification
        {
            UserId = userId, Title = title, Body = body, Type = type, OrderId = orderId,
        });
        await db.SaveChangesAsync();
        var tokens = await db.DeviceTokens.Where(t => t.UserId == userId)
            .Select(t => t.Token).ToListAsync();
        Push(tokens, title, body, orderId);
    }

    /// Fan a broadcast out to every user's inbox + push. Returns the user count.
    public static async Task<int> Broadcast(AppDbContext db, string title, string body)
    {
        var userIds = await db.Users.Select(u => u.Id).ToListAsync();
        foreach (var uid in userIds)
            db.Notifications.Add(new Notification { UserId = uid, Title = title, Body = body, Type = "promo" });
        await db.SaveChangesAsync();
        var tokens = await db.DeviceTokens.Select(t => t.Token).ToListAsync();
        Push(tokens, title, body);
        return userIds.Count;
    }

    /// Push-only alert to a delivery partner's devices (no inbox row — the
    /// rider app surfaces these as notifications). Used e.g. on order assignment.
    public static async Task ToPartner(AppDbContext db, string partnerId, string title, string body,
        string? orderId = null)
    {
        var tokens = await db.PartnerDevices.Where(d => d.PartnerId == partnerId)
            .Select(d => d.Token).ToListAsync();
        Push(tokens, title, body, orderId);
    }

    // FCM send seam. Prefers the modern HTTP v1 API (service account), falls
    // back to the legacy server key, else no-ops (just logs). Fire-and-forget so
    // a slow/unreachable FCM never blocks the request.
    private static void Push(IEnumerable<string> tokens, string title, string body,
        string? orderId = null)
    {
        var list = tokens.Where(t => !string.IsNullOrWhiteSpace(t)).Distinct().ToList();
        if (list.Count == 0) return;
        if (Fcm.Configured)
            _ = Fcm.SendAsync(list, title, body, orderId);   // HTTP v1
        else if (FcmConfigured)
            _ = SendFcm(list, title, body, orderId);          // legacy server key
        else
            Console.WriteLine($"[PUSH stub] \"{title}\" -> {list.Count} device(s)");
    }

    /// Legacy FCM HTTP send. For the modern HTTP v1 API, swap the URL to
    /// https://fcm.googleapis.com/v1/projects/{id}/messages:send and mint an
    /// OAuth token from FIREBASE_SERVICE_ACCOUNT instead of the server key.
    private static async Task SendFcm(List<string> tokens, string title, string body, string? orderId)
    {
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Post,
                "https://fcm.googleapis.com/fcm/send");
            req.Headers.TryAddWithoutValidation("Authorization", $"key={ServerKey}");
            req.Content = JsonContent.Create(new
            {
                registration_ids = tokens,
                notification = new { title, body },
                data = new { type = "order", orderId },
            });
            var res = await _http.SendAsync(req);
            Console.WriteLine($"[PUSH] \"{title}\" -> {tokens.Count} device(s): {(int)res.StatusCode}");
        }
        catch (Exception e)
        {
            Console.WriteLine($"[PUSH error] {e.Message}");
        }
    }
}
