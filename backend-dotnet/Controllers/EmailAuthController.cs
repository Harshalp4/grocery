using System.Text.Json;
using FarmFresh.Api.Auth;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// New sign-in: email OTP (Resend) + Google/Apple, plus the mandatory
// name/mobile profile step. The legacy phone SMS-OTP flow in AuthController is
// left intact for later use.
public class EmailAuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt;
    private readonly RateLimiter _rl;
    public EmailAuthController(AppDbContext db, JwtService jwt, RateLimiter rl)
        { _db = db; _jwt = jwt; _rl = rl; }

    private static readonly TimeSpan OtpTtl = TimeSpan.FromMinutes(5);

    private static string? Str(JsonElement b, string k)
        => b.ValueKind == JsonValueKind.Object && b.TryGetProperty(k, out var v)
           && v.ValueKind == JsonValueKind.String ? v.GetString() : null;

    private static string NormEmail(string? raw) => (raw ?? "").Trim().ToLowerInvariant();
    private static bool ValidEmail(string e) =>
        e.Length is >= 5 and <= 254 && e.Contains('@') && e.IndexOf('@') > 0 && e.Contains('.');

    private object AuthResult(User u) => new
    {
        token = _jwt.SignCustomerToken(u.Id, u.Phone, u.TokenVersion),
        profileComplete = u.ProfileComplete,
        user = new { id = u.Id, email = u.Email, phone = u.Phone, name = u.Name },
    };

    // POST /auth/email/request { email } -> { sent, retryIn, devOtp? }
    [HttpPost("/auth/email/request")]
    public async Task<IActionResult> RequestEmailOtp([FromBody] JsonElement body)
    {
        var email = NormEmail(Str(body, "email"));
        if (!ValidEmail(email)) return BadRequest(new { error = "Enter a valid email" });

        if (!_rl.Allow($"eotp-gap:{email}", 1, TimeSpan.FromSeconds(30)))
            return StatusCode(429, new { error = "Please wait before requesting another code", retryIn = 30 });
        if (!_rl.Allow($"eotp-req:{email}", 5, TimeSpan.FromMinutes(15)))
            return StatusCode(429, new { error = "Too many code requests. Try again later." });

        var code = Otp.Generate6();
        await _db.OtpCodes.Where(o => o.Email == email && !o.Consumed)
            .ExecuteUpdateAsync(s => s.SetProperty(o => o.Consumed, true));
        _db.OtpCodes.Add(new OtpCode { Email = email, Code = code, ExpiresAt = DateTime.UtcNow.Add(OtpTtl) });
        await _db.SaveChangesAsync();
        Mailer.SendOtp(email, code);

        return Ok(Otp.DevMode
            ? new { sent = true, retryIn = 30, devOtp = (string?)code }
            : new { sent = true, retryIn = 30, devOtp = (string?)null });
    }

    // POST /auth/email/verify { email, code } -> { token, profileComplete, user }
    [HttpPost("/auth/email/verify")]
    public async Task<IActionResult> VerifyEmailOtp([FromBody] JsonElement body)
    {
        var email = NormEmail(Str(body, "email"));
        var code = Str(body, "code");
        if (!ValidEmail(email) || string.IsNullOrEmpty(code) || code.Length is < 4 or > 6)
            return BadRequest(new { error = "Bad request" });

        if (!_rl.Allow($"eotp-verify:{email}", 6, TimeSpan.FromMinutes(15)))
            return StatusCode(429, new { error = "Too many attempts. Request a new code." });

        var otp = await _db.OtpCodes
            .Where(o => o.Email == email && o.Code == code && !o.Consumed && o.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(o => o.CreatedAt).FirstOrDefaultAsync();
        if (otp == null) return Unauthorized(new { error = "Invalid or expired code" });
        otp.Consumed = true;

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null)
        {
            user = new User { Email = email };
            _db.Users.Add(user);
        }
        await _db.SaveChangesAsync();
        return Ok(AuthResult(user));
    }

    // POST /auth/google { idToken } -> { token, profileComplete, user }
    [HttpPost("/auth/google")]
    public async Task<IActionResult> Google([FromBody] JsonElement body)
    {
        if (!SocialAuth.GoogleConfigured)
            return StatusCode(501, new { error = "Google sign-in isn't configured on the server" });
        var idToken = Str(body, "idToken");
        if (string.IsNullOrEmpty(idToken)) return BadRequest(new { error = "idToken required" });
        var info = await SocialAuth.VerifyGoogle(idToken);
        if (info == null) return Unauthorized(new { error = "Invalid Google token" });
        return Ok(AuthResult(await LinkOrCreate("google", info)));
    }

    // POST /auth/apple { identityToken, name? } -> { token, profileComplete, user }
    [HttpPost("/auth/apple")]
    public async Task<IActionResult> Apple([FromBody] JsonElement body)
    {
        if (!SocialAuth.AppleConfigured)
            return StatusCode(501, new { error = "Apple sign-in isn't configured on the server" });
        var idToken = Str(body, "identityToken");
        if (string.IsNullOrEmpty(idToken)) return BadRequest(new { error = "identityToken required" });
        var info = await SocialAuth.VerifyApple(idToken, Str(body, "name"));
        if (info == null) return Unauthorized(new { error = "Invalid Apple token" });
        return Ok(AuthResult(await LinkOrCreate("apple", info)));
    }

    // POST /auth/complete-profile { name, phone } (authed) -> { user, profileComplete }
    [Authorize(Policy = "Customer")]
    [HttpPost("/auth/complete-profile")]
    public async Task<IActionResult> CompleteProfile([FromBody] JsonElement body)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == this.CustomerId());
        if (user == null) return NotFound(new { error = "User not found" });
        var name = (Str(body, "name") ?? "").Trim();
        var phone = new string((Str(body, "phone") ?? "").Where(char.IsDigit).ToArray());
        if (name.Length < 2) return BadRequest(new { error = "Enter your name" });
        if (phone.Length is < 8 or > 15) return BadRequest(new { error = "Enter a valid mobile number" });
        user.Name = name;
        user.Phone = phone;
        await _db.SaveChangesAsync();
        return Ok(new { profileComplete = user.ProfileComplete,
            user = new { id = user.Id, email = user.Email, phone = user.Phone, name = user.Name } });
    }

    /// Find the user by provider id, else by email (link accounts), else create.
    private async Task<User> LinkOrCreate(string provider, SocialUser info)
    {
        var email = NormEmail(info.Email);
        var user = provider == "google"
            ? await _db.Users.FirstOrDefaultAsync(u => u.GoogleId == info.Subject)
            : await _db.Users.FirstOrDefaultAsync(u => u.AppleId == info.Subject);
        user ??= email.Length > 0
            ? await _db.Users.FirstOrDefaultAsync(u => u.Email == email)
            : null;
        if (user == null)
        {
            user = new User { Email = email.Length > 0 ? email : null };
            _db.Users.Add(user);
        }
        if (email.Length > 0 && string.IsNullOrEmpty(user.Email)) user.Email = email;
        if (provider == "google") user.GoogleId = info.Subject; else user.AppleId = info.Subject;
        if (string.IsNullOrWhiteSpace(user.Name) && !string.IsNullOrWhiteSpace(info.Name))
            user.Name = info.Name!.Trim();
        await _db.SaveChangesAsync();
        return user;
    }
}
