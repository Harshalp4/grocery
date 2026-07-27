using System.Text.Json;
using System.Text.RegularExpressions;
using FarmFresh.Api.Auth;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Port of backend/src/routes/admin.ts. Everything except /admin/login requires a
// valid admin token.
[Authorize(Policy = "Admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt;
    private readonly IWebHostEnvironment _env;
    private readonly RateLimiter _rl;
    public AdminController(AppDbContext db, JwtService jwt, IWebHostEnvironment env, RateLimiter rl) { _db = db; _jwt = jwt; _env = env; _rl = rl; }

    // ---- Auth (public) ----
    [AllowAnonymous]
    [HttpPost("/admin/login")]
    public async Task<IActionResult> Login([FromBody] JsonElement body)
    {
        // Throttle brute-force: 10 attempts / 5 min per client IP.
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        if (!_rl.Allow($"admin-login:{ip}", 10, TimeSpan.FromMinutes(5)))
            return StatusCode(429, new { error = "Too many login attempts. Try again later." });

        var email = body.Str("email");
        var password = body.Str("password");
        if (email == null || password == null) return BadRequest(new { error = "Bad request" });

        // Env bootstrap admin (superadmin).
        if (_jwt.IsBootstrapAdmin(email, password))
            return Ok(new { token = _jwt.IssueAdminToken(email, "admin") });

        // Database admin user.
        var norm = email.Trim().ToLowerInvariant();
        var au = await _db.AdminUsers.FirstOrDefaultAsync(a => a.Email == norm && a.Active);
        if (au != null && Services.Passwords.Verify(password, au.PasswordHash))
            return Ok(new { token = _jwt.IssueAdminToken(au.Email, au.Role) });

        return Unauthorized(new { error = "Invalid credentials" });
    }

    private bool IsSuperAdmin => User.FindFirst("adminRole")?.Value == "admin";

    // ---- Dashboard stats ----
    [HttpGet("/admin/stats")]
    public async Task<IActionResult> Stats()
    {
        var products = await _db.Products.CountAsync();
        var categories = await _db.Categories.CountAsync();
        var combos = await _db.ComboPacks.CountAsync();
        var subscriptions = await _db.SubscriptionPlans.CountAsync();
        var reviews = await _db.Reviews.CountAsync();
        var orders = await _db.Orders.CountAsync();

        var revenue = await _db.Orders.Where(o => o.Status != "cancelled").SumAsync(o => (int?)o.Total) ?? 0;
        var byGrade = await _db.Products.GroupBy(p => p.Grade)
            .Select(g => new { grade = g.Key, count = g.Count() }).ToListAsync();
        var byCategory = await _db.Products.GroupBy(p => p.CategorySlug)
            .Select(g => new { categorySlug = g.Key, count = g.Count() }).ToListAsync();
        var hasProducts = products > 0;
        var avg = hasProducts ? await _db.Products.AverageAsync(p => (double)p.Price) : 0;
        var min = hasProducts ? await _db.Products.MinAsync(p => p.Price) : 0;
        var max = hasProducts ? await _db.Products.MaxAsync(p => p.Price) : 0;

        return Ok(new
        {
            counts = new { products, categories, combos, subscriptions, reviews, orders },
            revenue,
            byCategory,
            byGrade,
            price = new { avg = (int)Math.Round(avg), min, max },
        });
    }

    // ---- Products ----
    private static void ApplyProduct(Product row, JsonElement d)
    {
        row.Name = d.StrOr("name", "");
        row.Source = d.StrOr("source", "");
        row.PackedDate = d.StrOr("packedDate", "");
        row.Price = d.IntOr("price", 0);
        row.MarketPrice = d.IntOr("marketPrice", 0);
        row.Grade = d.StrOr("grade", "");
        row.Tags = string.Join(",", d.StrArray("tags"));
        row.HarvestMonth = d.Str("harvestMonth");
        row.PackSize = d.Str("packSize");
        row.Nutrition = d.RawObjectOr("nutrition", "{}");
        row.CategorySlug = d.StrOr("categorySlug", "");
        row.Stock = d.IntOr("stock", 20);
        // imageUrl is managed separately via the image-upload endpoint.
    }

    private static bool ValidProduct(JsonElement d, string id)
        => !string.IsNullOrEmpty(id) && !string.IsNullOrEmpty(d.Str("name")) &&
           !string.IsNullOrEmpty(d.Str("categorySlug"));

    [HttpGet("/admin/products")]
    public async Task<IActionResult> Products()
    {
        var rows = await _db.Products.Include(p => p.Variants).OrderBy(p => p.Name).ToListAsync();
        return Ok(rows.Select(Mappers.ProductDto));
    }

    [HttpPost("/admin/products")]
    public async Task<IActionResult> CreateProduct([FromBody] JsonElement body)
    {
        var id = body.Str("id") ?? "";
        if (!ValidProduct(body, id)) return BadRequest(new { error = "Invalid product" });
        if (await _db.Products.AnyAsync(p => p.Id == id))
            return Conflict(new { error = "Could not create (duplicate id?)" });
        var row = new Product { Id = id };
        ApplyProduct(row, body);
        _db.Products.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, Mappers.ProductDto(row));
    }

    [HttpPut("/admin/products/{id}")]
    public async Task<IActionResult> UpdateProduct(string id, [FromBody] JsonElement body)
    {
        if (!ValidProduct(body, id)) return BadRequest(new { error = "Invalid product" });
        var row = await _db.Products.FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Product not found" });
        ApplyProduct(row, body);
        await _db.SaveChangesAsync();
        return Ok(Mappers.ProductDto(row));
    }

    [HttpDelete("/admin/products/{id}")]
    public async Task<IActionResult> DeleteProduct(string id)
    {
        var row = await _db.Products.FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Product not found" });
        // Cascade handles variants; reviews have no cascade, remove explicitly.
        await _db.Reviews.Where(r => r.ProductId == id).ExecuteDeleteAsync();
        _db.Products.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Product variants ----
    private static bool ValidVariant(JsonElement d) => !string.IsNullOrEmpty(d.Str("label"));

    [HttpPost("/admin/products/{id}/variants")]
    public async Task<IActionResult> CreateVariant(string id, [FromBody] JsonElement body)
    {
        if (!ValidVariant(body)) return BadRequest(new { error = "Invalid variant" });
        if (!await _db.Products.AnyAsync(p => p.Id == id)) return NotFound(new { error = "Product not found" });
        var row = new ProductVariant
        {
            ProductId = id,
            Label = body.StrOr("label", ""),
            Price = body.IntOr("price", 0),
            MarketPrice = body.IntOr("marketPrice", 0),
            Stock = body.IntOr("stock", 20),
            SortOrder = body.IntOr("sortOrder", 0),
        };
        _db.ProductVariants.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, row);
    }

    [HttpPut("/admin/variants/{vid}")]
    public async Task<IActionResult> UpdateVariant(string vid, [FromBody] JsonElement body)
    {
        if (!ValidVariant(body)) return BadRequest(new { error = "Invalid variant" });
        var row = await _db.ProductVariants.FirstOrDefaultAsync(v => v.Id == vid);
        if (row == null) return NotFound(new { error = "Variant not found" });
        row.Label = body.StrOr("label", "");
        row.Price = body.IntOr("price", 0);
        row.MarketPrice = body.IntOr("marketPrice", 0);
        row.Stock = body.IntOr("stock", 20);
        row.SortOrder = body.IntOr("sortOrder", 0);
        await _db.SaveChangesAsync();
        return Ok(row);
    }

    [HttpDelete("/admin/variants/{vid}")]
    public async Task<IActionResult> DeleteVariant(string vid)
    {
        var row = await _db.ProductVariants.FirstOrDefaultAsync(v => v.Id == vid);
        if (row == null) return NotFound(new { error = "Variant not found" });
        _db.ProductVariants.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    [HttpPut("/admin/products/{id}/stock")]
    public async Task<IActionResult> SetStock(string id, [FromBody] JsonElement body)
    {
        if (!body.Has("stock")) return BadRequest(new { error = "Bad stock" });
        var row = await _db.Products.FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Product not found" });
        row.Stock = body.IntOr("stock", row.Stock);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Product image upload (base64 data URL) ----
    [HttpPost("/admin/products/{id}/image")]
    public async Task<IActionResult> UploadImage(string id, [FromBody] JsonElement body)
    {
        var dataUrl = body.Str("dataUrl");
        if (string.IsNullOrEmpty(dataUrl)) return BadRequest(new { error = "Missing image" });
        var match = Regex.Match(dataUrl, @"^data:image/(png|jpe?g|webp);base64,(.+)$");
        if (!match.Success) return BadRequest(new { error = "Unsupported image format" });
        var ext = match.Groups[1].Value == "jpeg" ? "jpg" : match.Groups[1].Value;
        byte[] buf;
        try { buf = Convert.FromBase64String(match.Groups[2].Value); }
        catch { return BadRequest(new { error = "Unsupported image format" }); }
        if (buf.Length > 3_000_000) return StatusCode(413, new { error = "Image too large (max ~3MB)" });

        var row = await _db.Products.FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Product not found" });

        var dir = Path.Combine(_env.ContentRootPath, "uploads");
        Directory.CreateDirectory(dir);
        var file = $"{id}-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}.{ext}";
        await System.IO.File.WriteAllBytesAsync(Path.Combine(dir, file), buf);
        var imageUrl = $"/uploads/{file}";
        row.ImageUrl = imageUrl;
        await _db.SaveChangesAsync();
        return Ok(new { imageUrl });
    }

    // ---- Categories ----
    [HttpGet("/admin/categories")]
    public async Task<IActionResult> Categories()
    {
        var rows = await _db.Categories.OrderBy(c => c.SortOrder).ToListAsync();
        return Ok(rows.Select(Mappers.CategoryDto));
    }

    [HttpPost("/admin/categories")]
    public async Task<IActionResult> CreateCategory([FromBody] JsonElement body)
    {
        var slug = body.Str("slug"); var name = body.Str("name");
        if (string.IsNullOrEmpty(slug) || string.IsNullOrEmpty(name)) return BadRequest(new { error = "Bad request" });
        if (await _db.Categories.AnyAsync(c => c.Slug == slug)) return Conflict(new { error = "Slug already exists" });
        var row = new Category { Slug = slug, Name = name, Emoji = body.StrOr("emoji", ""), SortOrder = body.IntOr("sortOrder", 0) };
        _db.Categories.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, Mappers.CategoryDto(row));
    }

    [HttpPut("/admin/categories/{slug}")]
    public async Task<IActionResult> UpdateCategory(string slug, [FromBody] JsonElement body)
    {
        if (string.IsNullOrEmpty(body.Str("name"))) return BadRequest(new { error = "Bad request" });
        var row = await _db.Categories.FirstOrDefaultAsync(c => c.Slug == slug);
        if (row == null) return NotFound(new { error = "Category not found" });
        row.Name = body.StrOr("name", row.Name);
        row.Emoji = body.StrOr("emoji", "");
        row.SortOrder = body.IntOr("sortOrder", 0);
        await _db.SaveChangesAsync();
        return Ok(Mappers.CategoryDto(row));
    }

    [HttpDelete("/admin/categories/{slug}")]
    public async Task<IActionResult> DeleteCategory(string slug)
    {
        var count = await _db.Products.CountAsync(p => p.CategorySlug == slug);
        if (count > 0) return Conflict(new { error = $"In use by {count} product(s)" });
        var row = await _db.Categories.FirstOrDefaultAsync(c => c.Slug == slug);
        if (row == null) return NotFound(new { error = "Category not found" });
        _db.Categories.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Combo packs ----
    private static bool ValidCombo(JsonElement d, string id)
        => !string.IsNullOrEmpty(id) && !string.IsNullOrEmpty(d.Str("name")) &&
           d.Str("type") is "family" or "health" or "festival";

    private static void ApplyCombo(ComboPack row, JsonElement d)
    {
        row.Name = d.StrOr("name", "");
        row.Type = d.StrOr("type", "");
        row.Price = d.IntOr("price", 0);
        row.Size = d.StrOr("size", "");
        row.Duration = d.StrOr("duration", "");
        row.Items = d.StrOr("items", "");
        row.SavingsNote = d.StrOr("savingsNote", "");
    }

    [HttpGet("/admin/combos")]
    public async Task<IActionResult> Combos()
    {
        var rows = await _db.ComboPacks.OrderBy(c => c.Price).ToListAsync();
        return Ok(rows.Select(Mappers.ComboDto));
    }

    [HttpPost("/admin/combos")]
    public async Task<IActionResult> CreateCombo([FromBody] JsonElement body)
    {
        var id = body.Str("id") ?? "";
        if (!ValidCombo(body, id)) return BadRequest(new { error = "Bad request" });
        if (await _db.ComboPacks.AnyAsync(c => c.Id == id)) return Conflict(new { error = "Duplicate id" });
        var row = new ComboPack { Id = id };
        ApplyCombo(row, body);
        _db.ComboPacks.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, Mappers.ComboDto(row));
    }

    [HttpPut("/admin/combos/{id}")]
    public async Task<IActionResult> UpdateCombo(string id, [FromBody] JsonElement body)
    {
        if (!ValidCombo(body, id)) return BadRequest(new { error = "Bad request" });
        var row = await _db.ComboPacks.FirstOrDefaultAsync(c => c.Id == id);
        if (row == null) return NotFound(new { error = "Combo not found" });
        ApplyCombo(row, body);
        await _db.SaveChangesAsync();
        return Ok(Mappers.ComboDto(row));
    }

    [HttpDelete("/admin/combos/{id}")]
    public async Task<IActionResult> DeleteCombo(string id)
    {
        var row = await _db.ComboPacks.FirstOrDefaultAsync(c => c.Id == id);
        if (row == null) return NotFound(new { error = "Combo not found" });
        _db.ComboPacks.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Subscription plans ----
    [HttpGet("/admin/subscriptions")]
    public async Task<IActionResult> Subscriptions()
    {
        var rows = await _db.SubscriptionPlans.ToListAsync();
        return Ok(rows.Select(Mappers.SubscriptionDto));
    }

    [HttpPost("/admin/subscriptions")]
    public async Task<IActionResult> CreateSubscription([FromBody] JsonElement body)
    {
        var id = body.Str("id") ?? ""; var name = body.Str("name");
        if (string.IsNullOrEmpty(id) || string.IsNullOrEmpty(name)) return BadRequest(new { error = "Bad request" });
        if (await _db.SubscriptionPlans.AnyAsync(s => s.Id == id)) return Conflict(new { error = "Duplicate id" });
        var row = new SubscriptionPlan { Id = id, Name = name, Description = body.StrOr("description", ""), PriceLabel = body.StrOr("priceLabel", "") };
        _db.SubscriptionPlans.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, Mappers.SubscriptionDto(row));
    }

    [HttpPut("/admin/subscriptions/{id}")]
    public async Task<IActionResult> UpdateSubscription(string id, [FromBody] JsonElement body)
    {
        if (string.IsNullOrEmpty(body.Str("name"))) return BadRequest(new { error = "Bad request" });
        var row = await _db.SubscriptionPlans.FirstOrDefaultAsync(s => s.Id == id);
        if (row == null) return NotFound(new { error = "Plan not found" });
        row.Name = body.StrOr("name", row.Name);
        row.Description = body.StrOr("description", "");
        row.PriceLabel = body.StrOr("priceLabel", "");
        await _db.SaveChangesAsync();
        return Ok(Mappers.SubscriptionDto(row));
    }

    [HttpDelete("/admin/subscriptions/{id}")]
    public async Task<IActionResult> DeleteSubscription(string id)
    {
        var row = await _db.SubscriptionPlans.FirstOrDefaultAsync(s => s.Id == id);
        if (row == null) return NotFound(new { error = "Plan not found" });
        _db.SubscriptionPlans.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Reviews (moderation) ----
    [HttpGet("/admin/reviews")]
    public async Task<IActionResult> Reviews()
    {
        var rows = await _db.Reviews.ToListAsync();
        var names = await _db.Products.Select(p => new { p.Id, p.Name }).ToDictionaryAsync(p => p.Id, p => p.Name);
        return Ok(rows.Select(r => new
        {
            id = r.Id,
            productId = r.ProductId,
            productName = names.TryGetValue(r.ProductId, out var n) ? n : r.ProductId,
            initials = r.Initials,
            author = r.Author,
            area = r.Area,
            rating = r.Rating,
            text = r.Text,
        }));
    }

    [HttpDelete("/admin/reviews/{id}")]
    public async Task<IActionResult> DeleteReview(string id)
    {
        var row = await _db.Reviews.FirstOrDefaultAsync(r => r.Id == id);
        if (row == null) return NotFound(new { error = "Review not found" });
        _db.Reviews.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Orders ----
    [HttpGet("/admin/orders")]
    public async Task<IActionResult> Orders()
    {
        var rows = await _db.Orders
            .OrderByDescending(o => o.CreatedAt)
            .Include(o => o.Items).Include(o => o.DeliveryPartner).Include(o => o.ReturnRequest)
            .ToListAsync();
        return Ok(rows.Select(Mappers.OrderDto));
    }

    [HttpGet("/admin/orders/{id}")]
    public async Task<IActionResult> Order(string id)
    {
        var order = await _db.Orders
            .Include(o => o.Items).Include(o => o.Events).Include(o => o.DeliveryPartner).Include(o => o.ReturnRequest)
            .FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound(new { error = "Order not found" });
        return Ok(Mappers.OrderDto(order));
    }

    [HttpPut("/admin/orders/{id}/assign")]
    public async Task<IActionResult> Assign(string id, [FromBody] JsonElement body)
    {
        if (!body.IsObject() || !body.TryGetProperty("partnerId", out _)) return BadRequest(new { error = "Bad request" });
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound(new { error = "Order not found" });
        var partnerId = body.Str("partnerId");
        // §11.1: (re)assigning or unassigning an in-flight/failed order resets the
        // delivery snapshot so a new rider starts clean. COD already collected is kept.
        if (order.Status is "picked_up" or "out_for_delivery" or "failed")
        {
            order.Status = "packed";
            order.PickedUpAt = null;
            order.DeliveryOtp = null;
            order.DeliveryOtpSentAt = null;
            order.DeliveryOtpAttempts = 0;
        }
        if (partnerId != null)
        {
            var partner = await _db.DeliveryPartners.FirstOrDefaultAsync(p => p.Id == partnerId);
            if (partner == null || !partner.Active)
                return BadRequest(new { error = "Partner not found or inactive" });
            order.AssignedAt = DateTime.UtcNow;
            _db.OrderEvents.Add(new OrderEvent { OrderId = order.Id, Status = order.Status, Note = "Assigned to delivery partner" });
            await Services.Notify.ToPartner(_db, partner.Id, "New delivery assigned",
                $"Order {order.Code} is ready for pickup.", order.Id);
        }
        else
        {
            order.AssignedAt = null;
        }
        order.DeliveryPartnerId = partnerId;  // null clears the assignment
        await _db.SaveChangesAsync();
        await _db.Entry(order).Reference(o => o.DeliveryPartner).LoadAsync();
        await _db.Entry(order).Collection(o => o.Items).LoadAsync();
        return Ok(Mappers.OrderDto(order));
    }

    private static readonly string[] OrderStatuses =
        { "placed", "confirmed", "packed", "picked_up", "out_for_delivery", "delivered", "failed", "cancelled" };
    private static readonly string[] PaymentStatuses = { "pending", "paid", "failed" };

    [HttpPut("/admin/orders/{id}/status")]
    public async Task<IActionResult> Status(string id, [FromBody] JsonElement body)
    {
        var status = body.Str("status");
        var paymentStatus = body.Str("paymentStatus");
        if ((status != null && !OrderStatuses.Contains(status)) ||
            (paymentStatus != null && !PaymentStatuses.Contains(paymentStatus)))
            return BadRequest(new { error = "Bad status" });

        var order = await _db.Orders.Include(o => o.Items).Include(o => o.Events).FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound(new { error = "Order not found" });
        if (status != null)
        {
            order.Status = status;
            order.Events.Add(new OrderEvent { OrderId = order.Id, Status = status });  // log a timeline event
        }
        if (paymentStatus != null) order.PaymentStatus = paymentStatus;
        await _db.SaveChangesAsync();

        // Notify the customer of the fulfilment update (inbox + push).
        if (status != null && order.UserId != null)
        {
            var (title, bodyText) = StatusMessage(status, order.Code);
            await Notify.ToUser(_db, order.UserId, title, bodyText, "order", order.Id);
        }
        return Ok(Mappers.OrderDto(order));
    }

    private static (string title, string body) StatusMessage(string status, string code) => status switch
    {
        "confirmed" => ("Order confirmed", $"Your order {code} is confirmed and being prepared."),
        "packed" => ("Order packed", $"Your order {code} is packed and ready to ship."),
        "picked_up" => ("Picked up", $"Your order {code} has been picked up by your delivery partner."),
        "out_for_delivery" => ("Out for delivery", $"Your order {code} is on its way! 🚚"),
        "delivered" => ("Delivered", $"Your order {code} has been delivered. Enjoy! 🌾"),
        "failed" => ("Delivery attempt failed", $"We couldn't deliver order {code}. We'll reach out to reschedule."),
        "cancelled" => ("Order cancelled", $"Your order {code} has been cancelled."),
        _ => ("Order update", $"Your order {code} status is now {status}."),
    };

    // ---- Notifications / campaigns ----
    [HttpPost("/admin/campaigns")]
    public async Task<IActionResult> Broadcast([FromBody] JsonElement body)
    {
        var title = body.Str("title");
        var text = body.Str("body");
        if (string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(text))
            return BadRequest(new { error = "Title and body are required" });
        var sentTo = await Notify.Broadcast(_db, title!.Trim(), text!.Trim());
        return Ok(new { ok = true, sentTo });
    }

    // ---- Customers ----
    [HttpGet("/admin/customers")]
    public async Task<IActionResult> Customers()
    {
        var users = await _db.Users
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new
            {
                u.Id, u.Phone, u.Name, u.CreatedAt,
                OrderCount = u.Orders.Count,
                AddressCount = u.Addresses.Count,
                TotalSpend = u.Orders.Where(o => o.Status != "cancelled").Sum(o => (int?)o.Total) ?? 0,
            })
            .ToListAsync();
        return Ok(users.Select(u => new
        {
            id = u.Id, phone = u.Phone, name = u.Name, createdAt = u.CreatedAt,
            orderCount = u.OrderCount, addressCount = u.AddressCount, totalSpend = u.TotalSpend,
        }));
    }

    [HttpGet("/admin/customers/{id}")]
    public async Task<IActionResult> Customer(string id)
    {
        var user = await _db.Users
            .Include(u => u.Addresses)
            .Include(u => u.Orders).ThenInclude(o => o.Items)
            .FirstOrDefaultAsync(u => u.Id == id);
        if (user == null) return NotFound(new { error = "Customer not found" });
        return Ok(new
        {
            id = user.Id, phone = user.Phone, name = user.Name, createdAt = user.CreatedAt,
            addresses = user.Addresses,
            orders = user.Orders.OrderByDescending(o => o.CreatedAt).Select(Mappers.OrderDto),
        });
    }

    // ---- Delivery slots (CRUD) ----
    [HttpGet("/admin/slots")]
    public async Task<IActionResult> Slots()
        => Ok(await _db.DeliverySlots.OrderBy(s => s.SortOrder).ToListAsync());

    [HttpPost("/admin/slots")]
    public async Task<IActionResult> CreateSlot([FromBody] JsonElement body)
    {
        if (string.IsNullOrEmpty(body.Str("label"))) return BadRequest(new { error = "Bad request" });
        var row = new DeliverySlot { Label = body.StrOr("label", ""), Active = body.BoolOr("active", true), SortOrder = body.IntOr("sortOrder", 0) };
        _db.DeliverySlots.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, row);
    }

    [HttpPut("/admin/slots/{id}")]
    public async Task<IActionResult> UpdateSlot(string id, [FromBody] JsonElement body)
    {
        if (string.IsNullOrEmpty(body.Str("label"))) return BadRequest(new { error = "Bad request" });
        var row = await _db.DeliverySlots.FirstOrDefaultAsync(s => s.Id == id);
        if (row == null) return NotFound(new { error = "Slot not found" });
        row.Label = body.StrOr("label", ""); row.Active = body.BoolOr("active", true); row.SortOrder = body.IntOr("sortOrder", 0);
        await _db.SaveChangesAsync();
        return Ok(row);
    }

    [HttpDelete("/admin/slots/{id}")]
    public async Task<IActionResult> DeleteSlot(string id)
    {
        var row = await _db.DeliverySlots.FirstOrDefaultAsync(s => s.Id == id);
        if (row == null) return NotFound(new { error = "Slot not found" });
        _db.DeliverySlots.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Serviceable areas (CRUD) ----
    [HttpGet("/admin/areas")]
    public async Task<IActionResult> Areas()
        => Ok(await _db.ServiceableAreas.OrderBy(a => a.Pincode).ToListAsync());

    [HttpPost("/admin/areas")]
    public async Task<IActionResult> CreateArea([FromBody] JsonElement body)
    {
        var pincode = body.Str("pincode");
        if (pincode == null || pincode.Length < 3) return BadRequest(new { error = "Bad request" });
        if (await _db.ServiceableAreas.AnyAsync(a => a.Pincode == pincode)) return Conflict(new { error = "Pincode already added" });
        var row = new ServiceableArea { Pincode = pincode, Area = body.Str("area"), City = body.Str("city"), EtaLabel = body.StrOr("etaLabel", "Next day"), Active = body.BoolOr("active", true) };
        _db.ServiceableAreas.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, row);
    }

    [HttpPut("/admin/areas/{id}")]
    public async Task<IActionResult> UpdateArea(string id, [FromBody] JsonElement body)
    {
        var pincode = body.Str("pincode");
        if (pincode == null || pincode.Length < 3) return BadRequest(new { error = "Bad request" });
        var row = await _db.ServiceableAreas.FirstOrDefaultAsync(a => a.Id == id);
        if (row == null) return NotFound(new { error = "Area not found" });
        row.Pincode = pincode; row.Area = body.Str("area"); row.City = body.Str("city");
        row.EtaLabel = body.StrOr("etaLabel", "Next day"); row.Active = body.BoolOr("active", true);
        await _db.SaveChangesAsync();
        return Ok(row);
    }

    [HttpDelete("/admin/areas/{id}")]
    public async Task<IActionResult> DeleteArea(string id)
    {
        var row = await _db.ServiceableAreas.FirstOrDefaultAsync(a => a.Id == id);
        if (row == null) return NotFound(new { error = "Area not found" });
        _db.ServiceableAreas.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Delivery partners (CRUD + credentials) ----
    // Never serialise the entity directly — it holds the password hash.
    private static object PartnerDto(DeliveryPartner p) => new
    {
        id = p.Id, name = p.Name, phone = p.Phone, active = p.Active, onDuty = p.OnDuty,
        vehicleType = p.VehicleType, vehicleNumber = p.VehicleNumber, zone = p.Zone,
        hasCredentials = !string.IsNullOrEmpty(p.PasswordHash),
        mustChangePassword = p.MustChangePassword,
        lastLoginAt = p.LastLoginAt, lastLat = p.LastLat, lastLng = p.LastLng,
        lastLocationAt = p.LastLocationAt, createdAt = p.CreatedAt,
    };

    private static readonly string[] ActiveDeliveryStates =
        { "packed", "picked_up", "out_for_delivery" };

    private static void ApplyPartnerProfile(DeliveryPartner row, JsonElement d)
    {
        row.Name = d.StrOr("name", row.Name);
        row.VehicleType = d.Str("vehicleType");
        row.VehicleNumber = d.Str("vehicleNumber");
        row.Zone = d.Str("zone");
    }

    [HttpGet("/admin/partners")]
    public async Task<IActionResult> Partners()
        => Ok((await _db.DeliveryPartners.OrderBy(p => p.Name).ToListAsync()).Select(PartnerDto));

    [HttpGet("/admin/partners/{id}")]
    public async Task<IActionResult> Partner(string id)
    {
        var p = await _db.DeliveryPartners.FirstOrDefaultAsync(x => x.Id == id);
        if (p == null) return NotFound(new { error = "Partner not found" });
        var active = await _db.Orders.CountAsync(o => o.DeliveryPartnerId == id && ActiveDeliveryStates.Contains(o.Status));
        var todayStart = DateTime.UtcNow.Date;
        var deliveredToday = await _db.Orders.CountAsync(o => o.DeliveryPartnerId == id && o.Status == "delivered" && o.DeliveredAt >= todayStart);
        var codToday = await _db.Orders.Where(o => o.DeliveryPartnerId == id && o.DeliveredAt >= todayStart).SumAsync(o => (int?)o.CodCollected) ?? 0;
        return Ok(new { partner = PartnerDto(p), activeOrders = active, deliveredToday, codToday });
    }

    // Create a partner + issue a one-time temp password (shown once).
    [HttpPost("/admin/partners")]
    public async Task<IActionResult> CreatePartner([FromBody] JsonElement body)
    {
        var name = body.Str("name");
        var phone = new string((body.Str("phone") ?? "").Where(char.IsDigit).ToArray());
        if (string.IsNullOrWhiteSpace(name) || phone.Length < 8)
            return BadRequest(new { error = "Name and a valid phone are required" });
        if (await _db.DeliveryPartners.AnyAsync(p => p.Phone == phone))
            return Conflict(new { error = "A partner with that phone already exists" });

        var temp = Services.Passwords.TempPassword();
        var row = new DeliveryPartner
        {
            Name = name!.Trim(), Phone = phone,
            PasswordHash = Services.Passwords.Hash(temp), MustChangePassword = true,
        };
        ApplyPartnerProfile(row, body);
        _db.DeliveryPartners.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, new { partner = PartnerDto(row), tempPassword = temp });
    }

    // Reset credentials → new one-time password, revokes all sessions.
    [HttpPost("/admin/partners/{id}/reset-password")]
    public async Task<IActionResult> ResetPartnerPassword(string id)
    {
        var row = await _db.DeliveryPartners.FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Partner not found" });
        var temp = Services.Passwords.TempPassword();
        row.PasswordHash = Services.Passwords.Hash(temp);
        row.MustChangePassword = true;
        row.TokenVersion++;   // instant lockout of existing sessions
        await _db.SaveChangesAsync();
        return Ok(new { tempPassword = temp });
    }

    [HttpPut("/admin/partners/{id}")]
    public async Task<IActionResult> UpdatePartner(string id, [FromBody] JsonElement body)
    {
        if (string.IsNullOrWhiteSpace(body.Str("name"))) return BadRequest(new { error = "Name is required" });
        var row = await _db.DeliveryPartners.FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Partner not found" });
        ApplyPartnerProfile(row, body);
        var active = body.BoolOr("active", row.Active);
        if (!active && row.Active)
        {
            row.TokenVersion++;   // deactivate ⇒ revoke sessions

            // §11.2: hand their in-flight/failed orders back to the queue (keep COD).
            var handoff = await _db.Orders
                .Where(o => o.DeliveryPartnerId == id &&
                            (o.Status == "packed" || o.Status == "picked_up" ||
                             o.Status == "out_for_delivery" || o.Status == "failed"))
                .ToListAsync();
            foreach (var o in handoff)
            {
                o.Status = "packed";
                o.DeliveryPartnerId = null;
                o.AssignedAt = null;
                o.PickedUpAt = null;
                o.DeliveryOtp = null;
                o.DeliveryOtpSentAt = null;
                o.DeliveryOtpAttempts = 0;
                _db.OrderEvents.Add(new OrderEvent { OrderId = o.Id, Status = "packed", Note = "Unassigned — partner deactivated" });
            }
        }
        row.Active = active;
        await _db.SaveChangesAsync();
        return Ok(PartnerDto(row));
    }

    [HttpDelete("/admin/partners/{id}")]
    public async Task<IActionResult> DeletePartner(string id)
    {
        var row = await _db.DeliveryPartners.FirstOrDefaultAsync(p => p.Id == id);
        if (row == null) return NotFound(new { error = "Partner not found" });
        var busy = await _db.Orders.CountAsync(o => o.DeliveryPartnerId == id && ActiveDeliveryStates.Contains(o.Status));
        if (busy > 0)
            return Conflict(new { error = $"Partner has {busy} active order(s). Deactivate instead." });
        _db.DeliveryPartners.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Coupons ----
    private static object CouponDto(Coupon c) => new
    {
        id = c.Id, code = c.Code, type = c.Type, value = c.Value,
        minOrder = c.MinOrder, maxDiscount = c.MaxDiscount,
        validFrom = c.ValidFrom, validTo = c.ValidTo,
        usageLimit = c.UsageLimit, perUserLimit = c.PerUserLimit,
        timesUsed = c.TimesUsed, active = c.Active, createdAt = c.CreatedAt,
    };

    private static void ApplyCoupon(Coupon row, JsonElement d)
    {
        row.Type = d.Str("type") == "percent" ? "percent" : "flat";
        row.Value = Math.Max(0, d.IntOr("value", 0));
        row.MinOrder = Math.Max(0, d.IntOr("minOrder", 0));
        row.MaxDiscount = Math.Max(0, d.IntOr("maxDiscount", 0));
        row.UsageLimit = Math.Max(0, d.IntOr("usageLimit", 0));
        row.PerUserLimit = Math.Max(0, d.IntOr("perUserLimit", 0));
        row.Active = d.BoolOr("active", true);
        row.ValidFrom = DateTime.TryParse(d.Str("validFrom"), out var vf) ? vf.ToUniversalTime() : null;
        row.ValidTo = DateTime.TryParse(d.Str("validTo"), out var vt) ? vt.ToUniversalTime() : null;
    }

    [HttpGet("/admin/coupons")]
    public async Task<IActionResult> Coupons()
    {
        var rows = await _db.Coupons.OrderByDescending(c => c.CreatedAt).ToListAsync();
        return Ok(rows.Select(CouponDto));
    }

    [HttpPost("/admin/coupons")]
    public async Task<IActionResult> CreateCoupon([FromBody] JsonElement body)
    {
        var code = Services.Coupons.Normalise(body.Str("code"));
        if (code.Length < 3) return BadRequest(new { error = "Code must be at least 3 characters" });
        if (await _db.Coupons.AnyAsync(c => c.Code == code)) return Conflict(new { error = "Coupon code already exists" });
        var row = new Coupon { Code = code };
        ApplyCoupon(row, body);
        _db.Coupons.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, CouponDto(row));
    }

    [HttpPut("/admin/coupons/{id}")]
    public async Task<IActionResult> UpdateCoupon(string id, [FromBody] JsonElement body)
    {
        var row = await _db.Coupons.FirstOrDefaultAsync(c => c.Id == id);
        if (row == null) return NotFound(new { error = "Coupon not found" });
        ApplyCoupon(row, body);   // code is immutable after creation
        await _db.SaveChangesAsync();
        return Ok(CouponDto(row));
    }

    [HttpDelete("/admin/coupons/{id}")]
    public async Task<IActionResult> DeleteCoupon(string id)
    {
        var row = await _db.Coupons.FirstOrDefaultAsync(c => c.Id == id);
        if (row == null) return NotFound(new { error = "Coupon not found" });
        _db.Coupons.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Support tickets ----
    [HttpGet("/admin/support")]
    public async Task<IActionResult> Support()
    {
        var rows = await _db.SupportTickets.OrderByDescending(t => t.CreatedAt).ToListAsync();
        var uids = rows.Select(r => r.UserId).Distinct().ToList();
        var users = await _db.Users.Where(u => uids.Contains(u.Id)).ToDictionaryAsync(u => u.Id);
        return Ok(rows.Select(t =>
        {
            users.TryGetValue(t.UserId, out var u);
            return new
            {
                id = t.Id, subject = t.Subject, message = t.Message, status = t.Status,
                reply = t.Reply, orderId = t.OrderId, createdAt = t.CreatedAt, updatedAt = t.UpdatedAt,
                customerName = u?.Name, phone = u?.Phone,
            };
        }));
    }

    [HttpPut("/admin/support/{id}")]
    public async Task<IActionResult> UpdateSupport(string id, [FromBody] JsonElement body)
    {
        var t = await _db.SupportTickets.FirstOrDefaultAsync(x => x.Id == id);
        if (t == null) return NotFound(new { error = "Ticket not found" });
        var status = body.Str("status");
        if (status != null && new[] { "open", "resolved", "closed" }.Contains(status)) t.Status = status;
        var reply = body.Str("reply");
        if (reply != null) t.Reply = reply;
        await _db.SaveChangesAsync();
        if (!string.IsNullOrWhiteSpace(reply))
            await Notify.ToUser(_db, t.UserId, "Support replied",
                reply!.Length > 80 ? reply[..80] + "…" : reply, "system");
        return Ok(new { id = t.Id, status = t.Status, reply = t.Reply });
    }

    // ---- Banners (home CMS) ----
    private static object BannerDto(Banner b) => new
    {
        id = b.Id, title = b.Title, subtitle = b.Subtitle, imageUrl = b.ImageUrl,
        actionType = b.ActionType, actionValue = b.ActionValue, active = b.Active, sortOrder = b.SortOrder,
    };

    private static void ApplyBanner(Banner row, JsonElement d)
    {
        row.Title = d.StrOr("title", "");
        row.Subtitle = d.StrOr("subtitle", "");
        row.ImageUrl = d.Str("imageUrl");
        row.ActionType = d.Str("actionType");
        row.ActionValue = d.Str("actionValue");
        row.Active = d.BoolOr("active", true);
        row.SortOrder = d.IntOr("sortOrder", 0);
    }

    [HttpGet("/admin/banners")]
    public async Task<IActionResult> AdminBanners()
        => Ok((await _db.Banners.OrderBy(b => b.SortOrder).ToListAsync()).Select(BannerDto));

    [HttpPost("/admin/banners")]
    public async Task<IActionResult> CreateBanner([FromBody] JsonElement body)
    {
        if (string.IsNullOrWhiteSpace(body.Str("title"))) return BadRequest(new { error = "Title required" });
        var row = new Banner();
        ApplyBanner(row, body);
        _db.Banners.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, BannerDto(row));
    }

    [HttpPut("/admin/banners/{id}")]
    public async Task<IActionResult> UpdateBanner(string id, [FromBody] JsonElement body)
    {
        var row = await _db.Banners.FirstOrDefaultAsync(b => b.Id == id);
        if (row == null) return NotFound(new { error = "Banner not found" });
        ApplyBanner(row, body);
        await _db.SaveChangesAsync();
        return Ok(BannerDto(row));
    }

    [HttpDelete("/admin/banners/{id}")]
    public async Task<IActionResult> DeleteBanner(string id)
    {
        var row = await _db.Banners.FirstOrDefaultAsync(b => b.Id == id);
        if (row == null) return NotFound(new { error = "Banner not found" });
        _db.Banners.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Low stock / inventory ----
    [HttpGet("/admin/low-stock")]
    public async Task<IActionResult> LowStock([FromQuery] int threshold = 5)
    {
        var products = await _db.Products.Include(p => p.Variants).ToListAsync();
        var low = new List<(string productId, string product, string? variant, int stock)>();
        foreach (var p in products)
        {
            if (p.Variants.Count > 0)
            {
                foreach (var v in p.Variants.Where(v => v.Stock <= threshold))
                    low.Add((p.Id, p.Name, v.Label, v.Stock));
            }
            else if (p.Stock <= threshold)
            {
                low.Add((p.Id, p.Name, null, p.Stock));
            }
        }
        return Ok(low.OrderBy(x => x.stock)
            .Select(x => new { productId = x.productId, product = x.product, variant = x.variant, stock = x.stock }));
    }

    // ---- Admin users / roles (superadmin only) ----
    private static object AdminUserDto(AdminUser a) => new
    {
        id = a.Id, email = a.Email, role = a.Role, active = a.Active, createdAt = a.CreatedAt,
    };

    [HttpGet("/admin/admins")]
    public async Task<IActionResult> Admins()
    {
        if (!IsSuperAdmin) return StatusCode(403, new { error = "Admins only" });
        return Ok((await _db.AdminUsers.OrderBy(a => a.Email).ToListAsync()).Select(AdminUserDto));
    }

    [HttpPost("/admin/admins")]
    public async Task<IActionResult> CreateAdmin([FromBody] JsonElement body)
    {
        if (!IsSuperAdmin) return StatusCode(403, new { error = "Admins only" });
        var email = (body.Str("email") ?? "").Trim().ToLowerInvariant();
        var password = body.Str("password");
        var role = body.Str("role") == "admin" ? "admin" : "staff";
        if (email.Length < 3 || string.IsNullOrEmpty(password) || password.Length < 6)
            return BadRequest(new { error = "Email and a 6+ character password are required" });
        if (await _db.AdminUsers.AnyAsync(a => a.Email == email))
            return Conflict(new { error = "That email already exists" });
        var row = new AdminUser { Email = email, PasswordHash = Services.Passwords.Hash(password), Role = role };
        _db.AdminUsers.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, AdminUserDto(row));
    }

    [HttpPut("/admin/admins/{id}")]
    public async Task<IActionResult> UpdateAdmin(string id, [FromBody] JsonElement body)
    {
        if (!IsSuperAdmin) return StatusCode(403, new { error = "Admins only" });
        var row = await _db.AdminUsers.FirstOrDefaultAsync(a => a.Id == id);
        if (row == null) return NotFound(new { error = "Not found" });
        if (body.Has("role")) row.Role = body.Str("role") == "admin" ? "admin" : "staff";
        row.Active = body.BoolOr("active", row.Active);
        var pw = body.Str("password");
        if (!string.IsNullOrEmpty(pw))
        {
            if (pw.Length < 6) return BadRequest(new { error = "Password too short" });
            row.PasswordHash = Services.Passwords.Hash(pw);
        }
        await _db.SaveChangesAsync();
        return Ok(AdminUserDto(row));
    }

    [HttpDelete("/admin/admins/{id}")]
    public async Task<IActionResult> DeleteAdmin(string id)
    {
        if (!IsSuperAdmin) return StatusCode(403, new { error = "Admins only" });
        var row = await _db.AdminUsers.FirstOrDefaultAsync(a => a.Id == id);
        if (row == null) return NotFound(new { error = "Not found" });
        _db.AdminUsers.Remove(row);
        await _db.SaveChangesAsync();
        return Ok(new { ok = true });
    }

    // ---- Returns / refunds queue ----
    private static readonly string[] ReturnStatuses = { "requested", "approved", "rejected", "refunded" };

    [HttpGet("/admin/returns")]
    public async Task<IActionResult> Returns()
    {
        var rows = await _db.ReturnRequests
            .OrderByDescending(r => r.CreatedAt)
            .Include(r => r.Order)
            .ToListAsync();
        return Ok(rows.Select(r => new
        {
            id = r.Id, orderId = r.OrderId, userId = r.UserId, reason = r.Reason,
            status = r.Status, createdAt = r.CreatedAt, updatedAt = r.UpdatedAt,
            order = r.Order == null ? null : new { code = r.Order.Code, customerName = r.Order.CustomerName, total = r.Order.Total },
        }));
    }

    [HttpPut("/admin/returns/{id}")]
    public async Task<IActionResult> UpdateReturn(string id, [FromBody] JsonElement body)
    {
        var status = body.Str("status");
        if (status == null || !ReturnStatuses.Contains(status)) return BadRequest(new { error = "Bad status" });
        var rr = await _db.ReturnRequests.FirstOrDefaultAsync(r => r.Id == id);
        if (rr == null) return NotFound(new { error = "Return not found" });
        rr.Status = status;
        if (status == "refunded")
            await _db.Orders.Where(o => o.Id == rr.OrderId)
                .ExecuteUpdateAsync(s => s.SetProperty(o => o.PaymentStatus, "refunded"));
        await _db.SaveChangesAsync();
        return Ok(new
        {
            id = rr.Id, orderId = rr.OrderId, userId = rr.UserId, reason = rr.Reason,
            status = rr.Status, createdAt = rr.CreatedAt, updatedAt = rr.UpdatedAt,
        });
    }
}
