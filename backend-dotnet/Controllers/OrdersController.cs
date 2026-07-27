using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Port of backend/src/routes/orders.ts — guest checkout: create the order and
// settle payment, decrementing stock atomically first.
public class OrdersController : ControllerBase
{
    private readonly AppDbContext _db;
    public OrdersController(AppDbContext db) => _db = db;

    private record ItemInput(string Name, string Quantity, string PriceLabel, int Price, int Qty, string? ProductId, string? VariantId);

    private static string OrderCode(int seq)
    {
        var d = DateTime.Now;
        return $"FF-{d:yyyyMMdd}-{seq:D4}";
    }

    // POST /orders
    [HttpPost("/orders")]
    public async Task<IActionResult> Create([FromBody] JsonElement body)
    {
        if (body.ValueKind != JsonValueKind.Object)
            return BadRequest(new { error = "Invalid order" });

        string? Str(string k) => body.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
        int Int(string k, int def = 0) => body.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetInt32() : def;
        double? Dbl(string k) => body.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetDouble() : null;

        var destLat = Dbl("destLat");
        var destLng = Dbl("destLng");
        var customerName = Str("customerName");
        var phone = Str("phone");
        var address = Str("address");
        var slot = Str("slot");
        var paymentMethod = Str("paymentMethod");
        if (string.IsNullOrEmpty(customerName) || string.IsNullOrEmpty(phone) ||
            string.IsNullOrEmpty(address) || string.IsNullOrEmpty(slot) ||
            paymentMethod is not ("upi" or "card" or "cod"))
            return BadRequest(new { error = "Invalid order" });

        if (!body.TryGetProperty("items", out var itemsEl) || itemsEl.ValueKind != JsonValueKind.Array || itemsEl.GetArrayLength() < 1)
            return BadRequest(new { error = "Invalid order" });

        var items = new List<ItemInput>();
        foreach (var it in itemsEl.EnumerateArray())
        {
            string? S(string k) => it.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
            int N(string k) => it.TryGetProperty(k, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetInt32() : 0;
            var q = Math.Max(1, N("qty") == 0 ? 1 : N("qty"));
            items.Add(new ItemInput(S("name") ?? "", S("quantity") ?? "", S("priceLabel") ?? "", N("price"), q, S("productId"), S("variantId")));
        }

        // Item prices, discount and total are all recomputed server-side (never
        // trust the client's money). The delivery fee is clamped.
        var clientDeliveryFee = Int("deliveryFee");
        var couponCode = body.Str("couponCode");

        // Count how many of each product/variant this order needs (one line = one unit).
        var need = new Dictionary<string, (bool variant, int qty)>();
        foreach (var it in items)
        {
            if (!string.IsNullOrEmpty(it.VariantId))
            {
                var k = $"v:{it.VariantId}";
                need[k] = (true, (need.TryGetValue(k, out var e) ? e.qty : 0) + it.Qty);
            }
            else if (!string.IsNullOrEmpty(it.ProductId))
            {
                var k = $"p:{it.ProductId}";
                need[k] = (false, (need.TryGetValue(k, out var e) ? e.qty : 0) + it.Qty);
            }
        }

        await using var tx = await _db.Database.BeginTransactionAsync();

        // Load referenced rows once; verify stock and capture authoritative prices.
        var variantById = new Dictionary<string, ProductVariant>();
        var productById = new Dictionary<string, Product>();
        foreach (var (key, val) in need)
        {
            var id = key[2..];
            if (val.variant)
            {
                var row = await _db.ProductVariants.FirstOrDefaultAsync(v => v.Id == id);
                if (row == null) continue;   // unknown/legacy line — leave alone
                variantById[id] = row;
                if (row.Stock < val.qty)
                    return Conflict(new { error = "Out of stock", name = (string?)null });
            }
            else
            {
                var row = await _db.Products.FirstOrDefaultAsync(p => p.Id == id);
                if (row == null) continue;
                productById[id] = row;
                if (row.Stock < val.qty)
                    return Conflict(new { error = "Out of stock", name = row.Name });
            }
        }

        // Decrement stock for known ids only.
        foreach (var (key, val) in need)
        {
            var id = key[2..];
            if (val.variant && variantById.ContainsKey(id))
                await _db.ProductVariants.Where(v => v.Id == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(v => v.Stock, v => v.Stock - val.qty));
            else if (!val.variant && productById.ContainsKey(id))
                await _db.Products.Where(p => p.Id == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(p => p.Stock, p => p.Stock - val.qty));
        }

        // Authoritative per-line price from the catalog. Only combos / ad-hoc lines
        // (no productId/variantId in the catalog) fall back to the client price.
        int PriceFor(ItemInput i)
        {
            if (!string.IsNullOrEmpty(i.VariantId) && variantById.TryGetValue(i.VariantId, out var v)) return v.Price;
            if (!string.IsNullOrEmpty(i.ProductId) && productById.TryGetValue(i.ProductId, out var p)) return p.Price;
            return Math.Max(0, i.Price);
        }
        var priced = items.Select(i => (item: i, price: PriceFor(i))).ToList();

        var itemTotal = priced.Sum(x => x.price * x.item.Qty);
        var deliveryFee = Math.Clamp(clientDeliveryFee, 0, 1000);

        // Discount comes from a validated coupon only (server-computed); no
        // client-supplied savings are trusted.
        var userId = User.FindFirst("role")?.Value == "customer" ? User.FindFirst("sub")?.Value : null;
        var coupon = await Coupons.Validate(_db, couponCode, itemTotal, userId);
        var savings = coupon.Valid ? coupon.Discount : 0;
        var appliedCoupon = coupon.Valid ? coupon.Coupon!.Code : null;
        var total = Math.Max(0, itemTotal + deliveryFee - savings);

        if (coupon.Valid && coupon.Coupon != null)
            await _db.Coupons.Where(x => x.Id == coupon.Coupon.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(x => x.TimesUsed, x => x.TimesUsed + 1));

        var payment = Payments.Charge(paymentMethod, total);
        var seq = await _db.Orders.CountAsync() + 1;

        var order = new Order
        {
            Code = OrderCode(seq),
            UserId = userId,
            CustomerName = customerName,
            Phone = phone,
            Address = address,
            Slot = slot,
            ItemTotal = itemTotal,
            Savings = savings,
            DeliveryFee = deliveryFee,
            Total = total,
            CouponCode = appliedCoupon,
            PaymentMethod = paymentMethod,
            PaymentStatus = payment.Status,
            PaymentRef = payment.Ref,
            Status = "placed",
            Eta = $"Delivery {slot}",
            DestLat = destLat,
            DestLng = destLng,
            Items = priced.Select(x => new OrderItem
            {
                Name = x.item.Name,
                Quantity = x.item.Quantity,
                PriceLabel = x.item.PriceLabel,
                Price = x.price,               // authoritative unit price
                Qty = x.item.Qty,
                ProductId = x.item.ProductId,
                VariantId = x.item.VariantId,
            }).ToList(),
            Events = { new OrderEvent { Status = "placed", Note = "Order placed" } },
        };
        _db.Orders.Add(order);
        await _db.SaveChangesAsync();
        await tx.CommitAsync();

        // Empty the signed-in customer's persistent cart now it's been ordered.
        if (userId != null)
            await _db.CartItems.Where(c => c.UserId == userId).ExecuteDeleteAsync();

        return StatusCode(201, new
        {
            id = order.Id,
            code = order.Code,
            status = order.Status,
            paymentStatus = order.PaymentStatus,
            total = order.Total,
            slot = order.Slot,
        });
    }

    // GET /orders/id/:id -> fetch a single order (for the confirmation screen)
    [HttpGet("/orders/id/{id}")]
    public async Task<IActionResult> ById(string id)
    {
        var order = await _db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == id);
        if (order == null) return NotFound(new { error = "Order not found" });
        return Ok(Mappers.OrderDto(order));
    }
}
