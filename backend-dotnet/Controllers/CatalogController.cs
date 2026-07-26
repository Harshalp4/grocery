using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Public catalog endpoints — port of backend/src/routes/catalog.ts.
public class CatalogController : ControllerBase
{
    private readonly AppDbContext _db;
    public CatalogController(AppDbContext db) => _db = db;

    [HttpGet("/categories")]
    public async Task<IActionResult> Categories()
    {
        var rows = await _db.Categories.OrderBy(c => c.SortOrder).ToListAsync();
        return Ok(rows.Select(Mappers.CategoryDto));
    }

    [HttpGet("/products")]
    public async Task<IActionResult> Products(
        [FromQuery] string? category, [FromQuery] string? tag, [FromQuery] string? q,
        [FromQuery] int? priceMin, [FromQuery] int? priceMax, [FromQuery] string? sort,
        [FromQuery] int? limit, [FromQuery] int? offset)
    {
        var query = _db.Products.Include(p => p.Variants).AsQueryable();
        if (!string.IsNullOrEmpty(category)) query = query.Where(p => p.CategorySlug == category);
        if (!string.IsNullOrEmpty(tag)) query = query.Where(p => EF.Functions.Like(p.Tags, $"%{tag}%"));
        if (!string.IsNullOrEmpty(q))
            query = query.Where(p => EF.Functions.ILike(p.Name, $"%{q}%") || EF.Functions.ILike(p.Source, $"%{q}%"));
        if (priceMin.HasValue) query = query.Where(p => p.Price >= priceMin.Value);
        if (priceMax.HasValue) query = query.Where(p => p.Price <= priceMax.Value);

        query = sort switch
        {
            "price_asc" => query.OrderBy(p => p.Price),
            "price_desc" => query.OrderByDescending(p => p.Price),
            "discount" => query.OrderByDescending(p => p.MarketPrice - p.Price),
            _ => query.OrderBy(p => p.Name),
        };

        if (offset is > 0) query = query.Skip(offset.Value);
        if (limit is > 0) query = query.Take(limit.Value);

        var rows = await query.ToListAsync();
        return Ok(rows.Select(Mappers.ProductDto));
    }

    [HttpGet("/products/{id}")]
    public async Task<IActionResult> Product(string id)
    {
        var row = await _db.Products.Include(p => p.Variants)
            .FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Product not found" });
        return Ok(Mappers.ProductDto(row));
    }

    [HttpGet("/products/{id}/reviews")]
    public async Task<IActionResult> Reviews(string id)
    {
        var rows = await _db.Reviews.Where(r => r.ProductId == id).ToListAsync();
        return Ok(rows.Select(Mappers.ReviewDto));
    }

    // POST /products/:id/reviews — a signed-in customer leaves a rating + text.
    [Authorize(Policy = "Customer")]
    [HttpPost("/products/{id}/reviews")]
    public async Task<IActionResult> AddReview(string id, [FromBody] JsonElement body)
    {
        var rating = body.IntOr("rating", 0);
        var text = body.Str("text");
        if (rating < 1 || rating > 5 || string.IsNullOrWhiteSpace(text))
            return BadRequest(new { error = "A rating (1–5) and a comment are required" });
        if (!await _db.Products.AnyAsync(p => p.Id == id))
            return NotFound(new { error = "Product not found" });

        var user = await _db.Users.FindAsync(this.CustomerId());
        var author = string.IsNullOrWhiteSpace(user?.Name) ? "Customer" : user!.Name!;
        var review = new Review
        {
            ProductId = id,
            Rating = rating,
            Text = text!.Trim(),
            Author = author,
            Initials = ReviewInitials(author),
            Area = body.StrOr("area", ""),
        };
        _db.Reviews.Add(review);
        await _db.SaveChangesAsync();
        return StatusCode(201, Mappers.ReviewDto(review));
    }

    private static string ReviewInitials(string name)
    {
        var parts = name.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return "C";
        if (parts.Length == 1) return parts[0][..1].ToUpperInvariant();
        return (parts[0][..1] + parts[1][..1]).ToUpperInvariant();
    }

    [HttpGet("/combos")]
    public async Task<IActionResult> Combos([FromQuery] string? type)
    {
        type ??= "family";
        var rows = await _db.ComboPacks.Where(c => c.Type == type).ToListAsync();
        return Ok(rows.Select(Mappers.ComboDto));
    }

    [HttpGet("/subscriptions")]
    public async Task<IActionResult> Subscriptions()
    {
        var rows = await _db.SubscriptionPlans.ToListAsync();
        return Ok(rows.Select(Mappers.SubscriptionDto));
    }
}
