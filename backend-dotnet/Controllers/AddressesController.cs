using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Port of backend/src/routes/addresses.ts — all routes require a signed-in customer.
[Authorize(Policy = "Customer")]
public class AddressesController : ControllerBase
{
    private readonly AppDbContext _db;
    public AddressesController(AppDbContext db) => _db = db;

    private record AddressInput(string Label, string Line, string? Area, string? City, string? Pincode,
        bool IsDefault, double? Lat, double? Lng);

    private static AddressInput? Parse(JsonElement b)
    {
        if (b.ValueKind != JsonValueKind.Object) return null;
        string? Str(string k) => b.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
        double? Dbl(string k) => b.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetDouble() : null;
        var line = Str("line");
        if (line == null || line.Length < 3) return null;  // zod: line min 3
        var label = Str("label") ?? "Home";
        var isDefault = b.TryGetProperty("isDefault", out var d) && d.ValueKind == JsonValueKind.True;
        return new AddressInput(label, line, Str("area"), Str("city"), Str("pincode"), isDefault,
            Dbl("lat"), Dbl("lng"));
    }

    // GET /addresses -> the user's saved addresses (default first)
    [HttpGet("/addresses")]
    public async Task<IActionResult> List()
    {
        var uid = this.CustomerId();
        var rows = await _db.Addresses
            .Where(a => a.UserId == uid)
            .OrderByDescending(a => a.IsDefault).ThenByDescending(a => a.CreatedAt)
            .ToListAsync();
        return Ok(rows);
    }

    // POST /addresses -> add a new address
    [HttpPost("/addresses")]
    public async Task<IActionResult> Create([FromBody] JsonElement body)
    {
        var p = Parse(body);
        if (p == null) return BadRequest(new { error = "Invalid address" });
        var uid = this.CustomerId()!;

        var count = await _db.Addresses.CountAsync(a => a.UserId == uid);
        var makeDefault = p.IsDefault || count == 0;   // first one is default
        if (makeDefault)
            await _db.Addresses.Where(a => a.UserId == uid)
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDefault, false));

        var row = new Address
        {
            UserId = uid,
            Label = p.Label,
            Line = p.Line,
            Area = p.Area,
            City = p.City,
            Pincode = p.Pincode,
            IsDefault = makeDefault,
            Lat = p.Lat,
            Lng = p.Lng,
        };
        _db.Addresses.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, row);
    }

    // PUT /addresses/:id -> edit
    [HttpPut("/addresses/{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] JsonElement body)
    {
        var p = Parse(body);
        if (p == null) return BadRequest(new { error = "Invalid address" });
        var uid = this.CustomerId()!;
        var existing = await _db.Addresses.FirstOrDefaultAsync(a => a.Id == id && a.UserId == uid);
        if (existing == null) return NotFound(new { error = "Address not found" });

        if (p.IsDefault)
            await _db.Addresses.Where(a => a.UserId == uid)
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDefault, false));

        existing.Label = p.Label;
        existing.Line = p.Line;
        existing.Area = p.Area;
        existing.City = p.City;
        existing.Pincode = p.Pincode;
        existing.IsDefault = p.IsDefault;
        if (p.Lat.HasValue) existing.Lat = p.Lat;
        if (p.Lng.HasValue) existing.Lng = p.Lng;
        await _db.SaveChangesAsync();
        return Ok(existing);
    }

    // DELETE /addresses/:id
    [HttpDelete("/addresses/{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var uid = this.CustomerId()!;
        var existing = await _db.Addresses.FirstOrDefaultAsync(a => a.Id == id && a.UserId == uid);
        if (existing == null) return NotFound(new { error = "Address not found" });
        _db.Addresses.Remove(existing);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }
}
