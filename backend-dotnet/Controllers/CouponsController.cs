using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace FarmFresh.Api.Controllers;

// Customer-facing coupon check. Returns the server-computed discount so the cart
// can show it; the same rules are re-checked at order placement.
public class CouponsController : ControllerBase
{
    private readonly AppDbContext _db;
    public CouponsController(AppDbContext db) => _db = db;

    // POST /coupons/validate { code, cartTotal } -> { valid, discount, message, code }
    [HttpPost("/coupons/validate")]
    public async Task<IActionResult> Validate([FromBody] JsonElement body)
    {
        var code = body.Str("code");
        var cartTotal = body.IntOr("cartTotal", 0);
        var userId = User.FindFirst("role")?.Value == "customer" ? User.FindFirst("sub")?.Value : null;
        var r = await Coupons.Validate(_db, code, cartTotal, userId);
        return Ok(new { valid = r.Valid, discount = r.Discount, message = r.Message, code = r.Coupon?.Code });
    }
}
