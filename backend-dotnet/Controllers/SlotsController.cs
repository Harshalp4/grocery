using FarmFresh.Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Port of backend/src/routes/slots.ts + serviceable.ts.
public class SlotsController : ControllerBase
{
    private readonly AppDbContext _db;
    public SlotsController(AppDbContext db) => _db = db;

    // GET /slots -> active delivery slots (used by the checkout screen)
    [HttpGet("/slots")]
    public async Task<IActionResult> Slots()
    {
        var rows = await _db.DeliverySlots
            .Where(s => s.Active)
            .OrderBy(s => s.SortOrder)
            .ToListAsync();
        return Ok(rows.Select(s => new { id = s.Id, label = s.Label }));
    }

    // GET /serviceable?pincode=400703 -> { serviceable, etaLabel?, area? }
    [HttpGet("/serviceable")]
    public async Task<IActionResult> Serviceable([FromQuery] string? pincode)
    {
        var digits = new string((pincode ?? "").Where(char.IsDigit).ToArray());
        var total = await _db.ServiceableAreas.CountAsync(a => a.Active);
        if (total == 0)
            return Ok(new { serviceable = true, etaLabel = "Next day", configured = false });
        if (string.IsNullOrEmpty(digits))
            return Ok(new { serviceable = false, configured = true });
        var area = await _db.ServiceableAreas
            .FirstOrDefaultAsync(a => a.Pincode == digits && a.Active);
        return Ok(new
        {
            serviceable = area != null,
            etaLabel = area?.EtaLabel,
            area = area?.Area,
            configured = true,
        });
    }
}
