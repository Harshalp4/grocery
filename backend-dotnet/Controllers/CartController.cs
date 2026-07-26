using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Persistent per-customer cart. Requires a signed-in customer; guests keep a
// local cart and sync it here after login.
[Authorize(Policy = "Customer")]
public class CartController : ControllerBase
{
    private readonly AppDbContext _db;
    public CartController(AppDbContext db) => _db = db;

    private static object Dto(CartItem c) => new
    {
        id = c.Id,
        productId = c.ProductId,
        variantId = c.VariantId,
        name = c.Name,
        quantity = c.Quantity,
        priceLabel = c.PriceLabel,
        price = c.Price,
        qty = c.Qty,
    };

    [HttpGet("/cart")]
    public async Task<IActionResult> Get()
    {
        var uid = this.CustomerId();
        var rows = await _db.CartItems.Where(c => c.UserId == uid)
            .OrderBy(c => c.CreatedAt).ToListAsync();
        return Ok(rows.Select(Dto));
    }

    // POST /cart -> add (or merge into an existing product+variant line)
    [HttpPost("/cart")]
    public async Task<IActionResult> Add([FromBody] JsonElement body)
    {
        var uid = this.CustomerId()!;
        var productId = body.Str("productId");
        var variantId = body.Str("variantId");
        var qty = Math.Max(1, body.IntOr("qty", 1));

        var existing = await _db.CartItems.FirstOrDefaultAsync(c =>
            c.UserId == uid && c.ProductId == productId && c.VariantId == variantId);
        if (existing != null)
        {
            existing.Qty += qty;
            await _db.SaveChangesAsync();
            return Ok(Dto(existing));
        }

        var row = new CartItem
        {
            UserId = uid,
            ProductId = productId,
            VariantId = variantId,
            Name = body.StrOr("name", ""),
            Quantity = body.StrOr("quantity", ""),
            PriceLabel = body.StrOr("priceLabel", ""),
            Price = Math.Max(0, body.IntOr("price", 0)),
            Qty = qty,
        };
        _db.CartItems.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, Dto(row));
    }

    // PUT /cart -> replace the whole cart with the provided items (bulk sync)
    [HttpPut("/cart")]
    public async Task<IActionResult> Replace([FromBody] JsonElement body)
    {
        var uid = this.CustomerId()!;
        await _db.CartItems.Where(c => c.UserId == uid).ExecuteDeleteAsync();
        if (body.TryGetProperty("items", out var items) && items.ValueKind == JsonValueKind.Array)
        {
            foreach (var it in items.EnumerateArray())
            {
                string? S(string k) => it.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
                int N(string k, int d) => it.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetInt32() : d;
                _db.CartItems.Add(new CartItem
                {
                    UserId = uid,
                    ProductId = S("productId"),
                    VariantId = S("variantId"),
                    Name = S("name") ?? "",
                    Quantity = S("quantity") ?? "",
                    PriceLabel = S("priceLabel") ?? "",
                    Price = Math.Max(0, N("price", 0)),
                    Qty = Math.Max(1, N("qty", 1)),
                });
            }
        }
        await _db.SaveChangesAsync();
        var rows = await _db.CartItems.Where(c => c.UserId == uid)
            .OrderBy(c => c.CreatedAt).ToListAsync();
        return Ok(rows.Select(Dto));
    }

    // PATCH /cart/:id -> set quantity (0 removes the line)
    [HttpPatch("/cart/{id}")]
    public async Task<IActionResult> SetQty(string id, [FromBody] JsonElement body)
    {
        var uid = this.CustomerId();
        var row = await _db.CartItems.FirstOrDefaultAsync(c => c.Id == id && c.UserId == uid);
        if (row == null) return NotFound(new { error = "Item not found" });
        var qty = body.IntOr("qty", row.Qty);
        if (qty <= 0)
        {
            _db.CartItems.Remove(row);
            await _db.SaveChangesAsync();
            return Ok(new { ok = true, removed = true });
        }
        row.Qty = qty;
        await _db.SaveChangesAsync();
        return Ok(Dto(row));
    }

    [HttpDelete("/cart/{id}")]
    public async Task<IActionResult> Remove(string id)
    {
        var uid = this.CustomerId();
        var row = await _db.CartItems.FirstOrDefaultAsync(c => c.Id == id && c.UserId == uid);
        if (row == null) return NotFound(new { error = "Item not found" });
        _db.CartItems.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    [HttpDelete("/cart")]
    public async Task<IActionResult> Clear()
    {
        var uid = this.CustomerId();
        await _db.CartItems.Where(c => c.UserId == uid).ExecuteDeleteAsync();
        return Ok(new { ok = true });
    }
}
