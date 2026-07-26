using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// A signed-in customer's wishlist / favorites.
[Authorize(Policy = "Customer")]
public class WishlistController : ControllerBase
{
    private readonly AppDbContext _db;
    public WishlistController(AppDbContext db) => _db = db;

    // GET /wishlist -> the wishlisted products (full product DTOs)
    [HttpGet("/wishlist")]
    public async Task<IActionResult> Get()
    {
        var uid = this.CustomerId();
        var ids = await _db.WishlistItems.Where(w => w.UserId == uid)
            .OrderByDescending(w => w.CreatedAt).Select(w => w.ProductId).ToListAsync();
        var products = await _db.Products.Include(p => p.Variants)
            .Where(p => ids.Contains(p.Id)).ToListAsync();
        // Preserve wishlist order (most-recent first).
        var byId = products.ToDictionary(p => p.Id);
        var ordered = ids.Where(byId.ContainsKey).Select(i => byId[i]);
        return Ok(ordered.Select(Mappers.ProductDto));
    }

    // POST /wishlist { productId } -> add (idempotent)
    [HttpPost("/wishlist")]
    public async Task<IActionResult> Add([FromBody] JsonElement body)
    {
        var uid = this.CustomerId()!;
        var productId = body.Str("productId");
        if (string.IsNullOrEmpty(productId)) return BadRequest(new { error = "productId required" });
        if (!await _db.Products.AnyAsync(p => p.Id == productId))
            return NotFound(new { error = "Product not found" });
        if (!await _db.WishlistItems.AnyAsync(w => w.UserId == uid && w.ProductId == productId))
        {
            _db.WishlistItems.Add(new WishlistItem { UserId = uid, ProductId = productId });
            await _db.SaveChangesAsync();
        }
        return Ok(new { ok = true, productId });
    }

    // DELETE /wishlist/:productId
    [HttpDelete("/wishlist/{productId}")]
    public async Task<IActionResult> Remove(string productId)
    {
        var uid = this.CustomerId();
        await _db.WishlistItems.Where(w => w.UserId == uid && w.ProductId == productId)
            .ExecuteDeleteAsync();
        return Ok(new { ok = true });
    }
}
