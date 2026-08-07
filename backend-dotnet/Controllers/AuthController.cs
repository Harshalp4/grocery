using System.Text.Json;
using FarmFresh.Api.Auth;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Port of backend/src/routes/auth.ts — phone+OTP login and the signed-in
// customer's profile / order history / cancel / return.
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt;
    private readonly RateLimiter _rl;
    public AuthController(AppDbContext db, JwtService jwt, RateLimiter rl) { _db = db; _jwt = jwt; _rl = rl; }

    private static readonly TimeSpan OtpTtl = TimeSpan.FromMinutes(5);

    private static string NormalisePhone(string? raw)
        => new string((raw ?? "").Where(char.IsDigit).ToArray());

    // POST /auth/otp/request { phone } -> { sent, retryIn, devOtp? }
    [HttpPost("/auth/otp/request")]
    public async Task<IActionResult> RequestOtp([FromBody] JsonElement body)
    {
        var phone = NormalisePhone(GetString(body, "phone"));
        if (phone.Length < 8 || phone.Length > 15)
            return BadRequest(new { error = "Invalid phone" });

        // Throttle: at most one code per 30s, and 5 per 15 min, per phone.
        if (!_rl.Allow($"otp-gap:{phone}", 1, TimeSpan.FromSeconds(30)))
            return StatusCode(429, new { error = "Please wait before requesting another code", retryIn = 30 });
        if (!_rl.Allow($"otp-req:{phone}", 5, TimeSpan.FromMinutes(15)))
            return StatusCode(429, new { error = "Too many code requests. Try again later." });

        var code = Otp.Generate();
        var expiresAt = DateTime.UtcNow.Add(OtpTtl);

        // Invalidate previous unconsumed codes, then store the new one.
        await _db.OtpCodes.Where(o => o.Phone == phone && !o.Consumed)
            .ExecuteUpdateAsync(s => s.SetProperty(o => o.Consumed, true));
        _db.OtpCodes.Add(new OtpCode { Phone = phone, Code = code, ExpiresAt = expiresAt });
        await _db.SaveChangesAsync();
        Otp.SendSms(phone, code);

        if (Otp.DevMode)
            return Ok(new { sent = true, retryIn = 30, devOtp = code });
        return Ok(new { sent = true, retryIn = 30 });
    }

    // POST /auth/otp/verify { phone, code, name? } -> { token, user }
    [HttpPost("/auth/otp/verify")]
    public async Task<IActionResult> VerifyOtp([FromBody] JsonElement body)
    {
        var phone = NormalisePhone(GetString(body, "phone"));
        var code = GetString(body, "code");
        var name = GetString(body, "name");
        if (phone.Length < 8 || string.IsNullOrEmpty(code) || code.Length < 4 || code.Length > 6)
            return BadRequest(new { error = "Bad request" });

        // Cap verify attempts per phone (6 per 15 min) so a 4-digit code can't be
        // brute-forced within its 5-minute lifetime.
        if (!_rl.Allow($"otp-verify:{phone}", 6, TimeSpan.FromMinutes(15)))
            return StatusCode(429, new { error = "Too many attempts. Request a new code." });

        var otp = await _db.OtpCodes
            .Where(o => o.Phone == phone && o.Code == code && !o.Consumed && o.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync();
        if (otp == null) return Unauthorized(new { error = "Invalid or expired code" });

        otp.Consumed = true;

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Phone == phone);
        if (user == null)
        {
            user = new User { Phone = phone, Name = string.IsNullOrEmpty(name) ? null : name };
            _db.Users.Add(user);
        }
        else if (!string.IsNullOrEmpty(name))
        {
            user.Name = name;
        }
        await _db.SaveChangesAsync();

        var token = _jwt.SignCustomerToken(user.Id, user.Phone, user.TokenVersion);
        return Ok(new { token, user = new { id = user.Id, phone = user.Phone, name = user.Name } });
    }

    // GET /auth/me -> current user
    [Authorize(Policy = "Customer")]
    [HttpGet("/auth/me")]
    public async Task<IActionResult> Me()
    {
        var user = await _db.Users.FindAsync(this.CustomerId());
        if (user == null) return NotFound(new { error = "User not found" });
        return Ok(new { id = user.Id, email = user.Email, phone = user.Phone,
            name = user.Name, profileComplete = user.ProfileComplete });
    }

    // PUT /auth/me -> update the signed-in user's profile (name + optional mobile)
    [Authorize(Policy = "Customer")]
    [HttpPut("/auth/me")]
    public async Task<IActionResult> UpdateMe([FromBody] JsonElement body)
    {
        var name = GetString(body, "name")?.Trim();
        if (string.IsNullOrEmpty(name) || name.Length > 60)
            return BadRequest(new { error = "Enter your name" });
        var user = await _db.Users.FindAsync(this.CustomerId());
        if (user == null) return NotFound(new { error = "User not found" });
        user.Name = name;

        // Optional mobile update — same rule as the profile step (8–15 digits).
        var rawPhone = GetString(body, "phone");
        if (rawPhone != null)
        {
            var phone = NormalisePhone(rawPhone);
            if (phone.Length < 8 || phone.Length > 15)
                return BadRequest(new { error = "Enter a valid mobile number" });
            if (await _db.Users.AnyAsync(u => u.Phone == phone && u.Id != user.Id))
                return Conflict(new { error = "This mobile number is already registered to another account." });
            user.Phone = phone;
        }
        await _db.SaveChangesAsync();
        return Ok(new { id = user.Id, email = user.Email, phone = user.Phone,
            name = user.Name, profileComplete = user.ProfileComplete });
    }

    // DELETE /auth/me -> delete the signed-in customer's account (App-Store req).
    // Past orders are kept for records but detached from the user.
    [Authorize(Policy = "Customer")]
    [HttpDelete("/auth/me")]
    public async Task<IActionResult> DeleteMe()
    {
        var uid = this.CustomerId();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == uid);
        if (user == null) return NotFound(new { error = "User not found" });
        await _db.Orders.Where(o => o.UserId == uid)
            .ExecuteUpdateAsync(s => s.SetProperty(o => o.UserId, (string?)null));
        _db.Users.Remove(user);   // cascades addresses, cart, wishlist
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // GET /auth/orders -> the signed-in user's order history
    [Authorize(Policy = "Customer")]
    [HttpGet("/auth/orders")]
    public async Task<IActionResult> MyOrders()
    {
        var uid = this.CustomerId();
        var orders = await _db.Orders
            .Where(o => o.UserId == uid)
            .OrderByDescending(o => o.CreatedAt)
            .Include(o => o.Items)
            .Include(o => o.ReturnRequest)
            .ToListAsync();
        return Ok(orders.Select(Mappers.OrderDto));
    }

    // GET /auth/orders/:id -> one order with its tracking timeline
    [Authorize(Policy = "Customer")]
    [HttpGet("/auth/orders/{id}")]
    public async Task<IActionResult> OrderDetail(string id)
    {
        var uid = this.CustomerId();
        var order = await _db.Orders
            .Include(o => o.Items)
            .Include(o => o.Events)
            .Include(o => o.DeliveryPartner)
            .Include(o => o.ReturnRequest)
            .FirstOrDefaultAsync(o => o.Id == id && o.UserId == uid);
        if (order == null) return NotFound(new { error = "Order not found" });
        return Ok(Mappers.OrderDto(order));
    }

    // POST /auth/orders/:id/cancel -> customer cancels (only before dispatch)
    private static readonly string[] Cancellable = { "placed", "confirmed" };

    [Authorize(Policy = "Customer")]
    [HttpPost("/auth/orders/{id}/cancel")]
    public async Task<IActionResult> Cancel(string id)
    {
        var uid = this.CustomerId();
        var order = await _db.Orders
            .Include(o => o.Items)
            .Include(o => o.Events)
            .FirstOrDefaultAsync(o => o.Id == id && o.UserId == uid);
        if (order == null) return NotFound(new { error = "Order not found" });
        if (!Cancellable.Contains(order.Status))
            return Conflict(new { error = "This order can no longer be cancelled" });

        order.Status = "cancelled";
        order.Events.Add(new OrderEvent { OrderId = order.Id, Status = "cancelled", Note = "Cancelled by customer" });
        await _db.SaveChangesAsync();
        return Ok(Mappers.OrderDto(order));
    }

    // POST /auth/orders/:id/return -> report an issue / request a return
    [Authorize(Policy = "Customer")]
    [HttpPost("/auth/orders/{id}/return")]
    public async Task<IActionResult> Return(string id, [FromBody] JsonElement body)
    {
        var reason = GetString(body, "reason");
        if (reason == null || reason.Length < 3) return BadRequest(new { error = "Reason required" });
        var uid = this.CustomerId();
        var order = await _db.Orders.Include(o => o.ReturnRequest)
            .FirstOrDefaultAsync(o => o.Id == id && o.UserId == uid);
        if (order == null) return NotFound(new { error = "Order not found" });
        if (order.ReturnRequest != null)
            return Conflict(new { error = "A request already exists for this order" });

        var rr = new ReturnRequest { OrderId = order.Id, UserId = uid, Reason = reason };
        _db.ReturnRequests.Add(rr);
        await _db.SaveChangesAsync();
        return StatusCode(201, new
        {
            id = rr.Id,
            orderId = rr.OrderId,
            userId = rr.UserId,
            reason = rr.Reason,
            status = rr.Status,
            createdAt = rr.CreatedAt,
            updatedAt = rr.UpdatedAt,
        });
    }

    private static string? GetString(JsonElement body, string prop)
        => body.ValueKind == JsonValueKind.Object &&
           body.TryGetProperty(prop, out var v) && v.ValueKind == JsonValueKind.String
            ? v.GetString() : null;
}
