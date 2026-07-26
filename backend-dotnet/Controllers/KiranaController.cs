using System.Globalization;
using System.Text.Json;
using FarmFresh.Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Port of backend/src/routes/kirana.ts — the rule-based Auto Kirana generator
// and "Repeat Last Month" basket.
public class KiranaController : ControllerBase
{
    private readonly AppDbContext _db;
    public KiranaController(AppDbContext db) => _db = db;

    private static readonly CultureInfo InIN = CultureInfo.GetCultureInfo("en-IN");

    private record BaseItem(string Name, string Unit, int Qty, int Rate);

    // Base monthly quantities for a family of ~4, scaled by household size.
    private static readonly BaseItem[] Base =
    {
        new("Rice", "kg", 10, 54),
        new("Wheat Flour", "kg", 15, 51),
        new("Toor Dal", "kg", 3, 160),
        new("Chana Dal", "kg", 2, 130),
        new("Sugar", "kg", 2, 55),
        new("Tea", "kg", 1, 450),
        new("Oil", "L", 5, 230),
    };

    private static string Rupees(int n) => "₹" + n.ToString("#,##0", InIN);

    // POST /kirana/generate -> { title, subtitle, lines[], estimatedTotal }
    [HttpPost("/kirana/generate")]
    public IActionResult Generate([FromBody] JsonElement body)
    {
        string members = "4";
        int adults = 2, children = 2, budget = 4500;
        string preference = "Vegetarian", usage = "Regular cooking";

        if (body.ValueKind == JsonValueKind.Object)
        {
            if (body.TryGetProperty("members", out var m))
                members = m.ValueKind == JsonValueKind.Number ? m.GetRawText() : (m.GetString() ?? "4");
            if (body.TryGetProperty("adults", out var a) && a.ValueKind == JsonValueKind.Number) adults = a.GetInt32();
            if (body.TryGetProperty("children", out var c) && c.ValueKind == JsonValueKind.Number) children = c.GetInt32();
            if (body.TryGetProperty("budget", out var bu) && bu.ValueKind == JsonValueKind.Number) budget = bu.GetInt32();
            if (body.TryGetProperty("preference", out var p) && p.ValueKind == JsonValueKind.String) preference = p.GetString()!;
            if (body.TryGetProperty("usage", out var u) && u.ValueKind == JsonValueKind.String) usage = u.GetString()!;
        }

        // Scale quantities to household size (family of 4 = baseline factor 1.0).
        var headcount = adults + children * 0.6;
        var factor = Math.Max(0.5, headcount / 4.0);

        var lines = Base.Select(b =>
        {
            var qty = Math.Max(1, (int)Math.Round(b.Qty * factor, MidpointRounding.AwayFromZero));
            var cost = qty * b.Rate;
            return new { b.Name, Quantity = $"{qty} {b.Unit}", Cost = cost };
        }).ToList();

        // Trim least-essential items if we blow the budget (keep the first staples).
        var total = lines.Sum(l => l.Cost);
        while (total > budget * 1.05 && lines.Count > 4)
        {
            total -= lines[^1].Cost;
            lines.RemoveAt(lines.Count - 1);
        }

        return Ok(new
        {
            title = $"Family of {members} — Monthly Kirana",
            subtitle = $"{preference} · {usage}",
            lines = lines.Select(l => new { name = l.Name, quantity = l.Quantity, priceLabel = Rupees(l.Cost) }),
            estimatedTotal = total,
        });
    }

    // GET /orders/last -> BasketLine[] (Repeat Last Month)
    [HttpGet("/orders/last")]
    public async Task<IActionResult> Last()
    {
        var rows = await _db.BasketLines
            .Where(r => r.List == "repeat")
            .OrderBy(r => r.SortOrder)
            .ToListAsync();
        return Ok(rows.Select(r => new { name = r.Name, quantity = r.Quantity, priceLabel = r.PriceLabel }));
    }
}
