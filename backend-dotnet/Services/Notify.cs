using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Services;

// Creates in-app notifications (the customer inbox) and fires a push. Push
// delivery is a stub until FCM_SERVER_KEY is configured — the inbox works
// either way, so this is fully testable without Firebase.
public static class Notify
{
    private static bool FcmConfigured =>
        !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("FCM_SERVER_KEY"));

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
        Push(tokens, title, body);
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

    // FCM send seam. Logs today; wire the real FCM HTTP v1 call here once
    // FCM_SERVER_KEY (+ a Firebase project) is available.
    private static void Push(IEnumerable<string> tokens, string title, string body)
    {
        var list = tokens.ToList();
        if (list.Count == 0) return;
        var mode = FcmConfigured ? "PUSH" : "PUSH stub";
        Console.WriteLine($"[{mode}] \"{title}\" -> {list.Count} device(s)");
        // TODO(prod): real FCM HTTP v1 send when FcmConfigured.
    }
}
