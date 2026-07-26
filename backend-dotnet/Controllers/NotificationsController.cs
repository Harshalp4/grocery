using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// The signed-in customer's notification inbox + device-token registration.
[Authorize(Policy = "Customer")]
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _db;
    public NotificationsController(AppDbContext db) => _db = db;

    // POST /notifications/token { token, platform } -> register/refresh FCM token
    [HttpPost("/notifications/token")]
    public async Task<IActionResult> RegisterToken([FromBody] JsonElement body)
    {
        var uid = this.CustomerId()!;
        var token = body.Str("token");
        if (string.IsNullOrEmpty(token)) return BadRequest(new { error = "token required" });
        var platform = body.StrOr("platform", "android");

        var existing = await _db.DeviceTokens.FirstOrDefaultAsync(t => t.Token == token);
        if (existing != null)
        {
            existing.UserId = uid;
            existing.Platform = platform;
        }
        else
        {
            _db.DeviceTokens.Add(new DeviceToken { UserId = uid, Token = token, Platform = platform });
        }
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // GET /notifications -> inbox (newest first)
    [HttpGet("/notifications")]
    public async Task<IActionResult> List()
    {
        var uid = this.CustomerId();
        var rows = await _db.Notifications.Where(n => n.UserId == uid)
            .OrderByDescending(n => n.CreatedAt).Take(100).ToListAsync();
        return Ok(rows.Select(n => new
        {
            id = n.Id, title = n.Title, body = n.Body, type = n.Type,
            orderId = n.OrderId, read = n.Read, createdAt = n.CreatedAt,
        }));
    }

    // GET /notifications/unread-count -> { count }  (for the badge)
    [HttpGet("/notifications/unread-count")]
    public async Task<IActionResult> UnreadCount()
    {
        var uid = this.CustomerId();
        var count = await _db.Notifications.CountAsync(n => n.UserId == uid && !n.Read);
        return Ok(new { count });
    }

    // POST /notifications/read-all -> mark all read
    [HttpPost("/notifications/read-all")]
    public async Task<IActionResult> ReadAll()
    {
        var uid = this.CustomerId();
        await _db.Notifications.Where(n => n.UserId == uid && !n.Read)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.Read, true));
        return Ok(new { ok = true });
    }

    // POST /notifications/:id/read -> mark one read
    [HttpPost("/notifications/{id}/read")]
    public async Task<IActionResult> ReadOne(string id)
    {
        var uid = this.CustomerId();
        var n = await _db.Notifications.FirstOrDefaultAsync(x => x.Id == id && x.UserId == uid);
        if (n == null) return NotFound(new { error = "Not found" });
        n.Read = true;
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }
}
