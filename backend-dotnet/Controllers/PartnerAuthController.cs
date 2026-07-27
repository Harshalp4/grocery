using System.Text.Json;
using FarmFresh.Api.Auth;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Delivery-partner authentication + profile. No self-registration — accounts are
// created only via the admin API. Login is anonymous; everything else requires
// a valid, non-revoked partner token.
[Authorize(Policy = "Partner")]
public class PartnerAuthController : PartnerBase
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt;
    private readonly RateLimiter _rl;
    public PartnerAuthController(AppDbContext db, JwtService jwt, RateLimiter rl)
    {
        _db = db; _jwt = jwt; _rl = rl;
    }

    // POST /partner/auth/login { phone, password } -> { token, partner, mustChangePassword }
    [AllowAnonymous]
    [HttpPost("/partner/auth/login")]
    public async Task<IActionResult> Login([FromBody] JsonElement body)
    {
        var phone = new string((body.Str("phone") ?? "").Where(char.IsDigit).ToArray());
        var password = body.Str("password") ?? "";
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        // Throttle; never reveal whether the phone is on the roster.
        if (!_rl.Allow($"partner-login:{phone}", 5, TimeSpan.FromMinutes(15)) ||
            !_rl.Allow($"partner-login-ip:{ip}", 20, TimeSpan.FromMinutes(15)))
            return StatusCode(429, new { error = "Too many attempts. Try again later." });

        var p = await _db.DeliveryPartners.FirstOrDefaultAsync(x => x.Phone == phone && x.Active);
        if (p == null || string.IsNullOrEmpty(p.PasswordHash) || !Passwords.Verify(password, p.PasswordHash))
            return Unauthorized(new { error = "Invalid phone or password" });

        p.LastLoginAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        var token = _jwt.SignPartnerToken(p.Id, p.Phone, p.TokenVersion);
        return Ok(new { token, partner = PartnerDtos.Profile(p), mustChangePassword = p.MustChangePassword });
    }

    // POST /partner/auth/password { currentPassword, newPassword } -> { token, partner }
    [HttpPost("/partner/auth/password")]
    public async Task<IActionResult> ChangePassword([FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db, allowMustChange: true);
        if (err != null) return err;
        var current = body.Str("currentPassword") ?? "";
        var next = body.Str("newPassword") ?? "";
        if (!Passwords.Verify(current, me!.PasswordHash))
            return BadRequest(new { error = "Current password is incorrect" });
        if (next.Length < 8) return BadRequest(new { error = "New password must be at least 8 characters" });
        if (next == current) return BadRequest(new { error = "New password must be different" });
        if (next == me.Phone) return BadRequest(new { error = "Password can't be your phone number" });

        me.PasswordHash = Passwords.Hash(next);
        me.MustChangePassword = false;
        me.TokenVersion++;   // invalidate any other sessions
        await _db.SaveChangesAsync();
        var token = _jwt.SignPartnerToken(me.Id, me.Phone, me.TokenVersion);
        return Ok(new { token, partner = PartnerDtos.Profile(me) });
    }

    // POST /partner/auth/logout { token } -> unregister this device
    [HttpPost("/partner/auth/logout")]
    public async Task<IActionResult> Logout([FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db, allowMustChange: true);
        if (err != null) return err;
        var token = body.Str("token");
        if (!string.IsNullOrEmpty(token))
            await _db.PartnerDevices.Where(d => d.PartnerId == me!.Id && d.Token == token).ExecuteDeleteAsync();
        return Ok(new { ok = true });
    }

    // GET /partner/me
    [HttpGet("/partner/me")]
    public async Task<IActionResult> Me()
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        return Ok(PartnerDtos.Profile(me!));
    }

    // PUT /partner/me/duty { onDuty }
    [HttpPut("/partner/me/duty")]
    public async Task<IActionResult> Duty([FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        me!.OnDuty = body.BoolOr("onDuty", me.OnDuty);
        if (!me.OnDuty) { me.LastLat = null; me.LastLng = null; me.LastLocationAt = null; }
        await _db.SaveChangesAsync();
        return Ok(new { onDuty = me.OnDuty });
    }

    // POST /partner/me/device { token, platform } -> register FCM token
    [HttpPost("/partner/me/device")]
    public async Task<IActionResult> Device([FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        var token = body.Str("token");
        if (string.IsNullOrEmpty(token)) return BadRequest(new { error = "token required" });
        var platform = body.StrOr("platform", "android");
        var existing = await _db.PartnerDevices.FirstOrDefaultAsync(d => d.Token == token);
        if (existing != null) { existing.PartnerId = me!.Id; existing.Platform = platform; }
        else _db.PartnerDevices.Add(new PartnerDevice { PartnerId = me!.Id, Token = token, Platform = platform });
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // POST /partner/me/location { lat, lng } -> live location ping (used by the
    // customer's order-tracking map). Also appends to the location trail.
    [HttpPost("/partner/me/location")]
    public async Task<IActionResult> Location([FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        if (!body.TryGetProperty("lat", out var latEl) || latEl.ValueKind != JsonValueKind.Number ||
            !body.TryGetProperty("lng", out var lngEl) || lngEl.ValueKind != JsonValueKind.Number)
            return BadRequest(new { error = "lat and lng required" });
        var lat = latEl.GetDouble();
        var lng = lngEl.GetDouble();
        me!.LastLat = lat;
        me.LastLng = lng;
        me.LastLocationAt = DateTime.UtcNow;
        _db.PartnerLocations.Add(new PartnerLocation { PartnerId = me.Id, Lat = lat, Lng = lng });
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }
}
