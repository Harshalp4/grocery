using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc;

namespace FarmFresh.Api.Controllers;

// Port of backend/src/routes/assistant.ts — placeholder AI planner. To make this
// real, call the Claude API here (server-side, key in env); the response shape
// ({ reply }) stays the same.
public class AssistantController : ControllerBase
{
    // POST /ai/plan -> { reply }
    [HttpPost("/ai/plan")]
    public IActionResult Plan([FromBody] JsonElement body)
    {
        string? prompt = null;
        if (body.ValueKind == JsonValueKind.Object &&
            body.TryGetProperty("prompt", out var p) && p.ValueKind == JsonValueKind.String)
            prompt = p.GetString();

        if (string.IsNullOrEmpty(prompt))
            return BadRequest(new { error = "prompt is required" });

        var lower = prompt.ToLowerInvariant();
        var highProtein = Regex.IsMatch(lower, "protein|fitness|gym|muscle");
        var budget = Regex.IsMatch(lower, "budget|cheap|₹|rupee|save");

        var cart = highProtein
            ? "Soya 1kg · Rajma 2kg · Chana 2kg · Moong 3kg · Peanut 1kg"
            : "Rice 10kg · Atta 15kg · Toor Dal 3kg · Oil 5L · Tea 1kg";
        var tip = highProtein
            ? "add sprouts and paneer for extra protein 💪"
            : "add millets twice a week for fibre 🌱";
        var total = budget ? "₹4,980*" : "₹4,250*";

        var reply =
            "Here's a suggested basket 👇\n\n" +
            $"Suggested cart\n{cart}\n\n" +
            "Est. monthly qty: ~34 kg / 5 L\n" +
            $"Health tip: {tip}\n" +
            $"Est. total: {total} (placeholder)";

        return Ok(new { reply });
    }
}
