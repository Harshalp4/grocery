using System.Text.Json;
using FarmFresh.Api.Models;

namespace FarmFresh.Api.Services;

// Convert DB rows into the JSON shapes the Flutter app expects (see the app's
// domain/entities) — a port of backend/src/mappers.ts. Notably: `tags` becomes
// a string[] and `nutrition` a parsed object. Returned as plain objects so the
// controllers' System.Text.Json (camelCase) serialises them like the original.
public static class Mappers
{
    public static object VariantDto(ProductVariant v) => new
    {
        id = v.Id,
        label = v.Label,
        price = v.Price,
        marketPrice = v.MarketPrice,
        stock = v.Stock,
        inStock = v.Stock > 0,
    };

    public static object ProductDto(Product p)
    {
        var ordered = (p.Variants ?? new List<ProductVariant>())
            .OrderBy(v => v.SortOrder)
            .ToList();
        var variants = ordered.Select(VariantDto).ToList();
        // With variants: in stock if any variant is; else use the product's stock.
        var inStock = ordered.Count > 0
            ? ordered.Any(v => v.Stock > 0)
            : p.Stock > 0;
        return new
        {
            id = p.Id,
            name = p.Name,
            source = p.Source,
            packedDate = p.PackedDate,
            price = p.Price,
            marketPrice = p.MarketPrice,
            grade = p.Grade,
            tags = string.IsNullOrEmpty(p.Tags)
                ? Array.Empty<string>()
                : p.Tags.Split(',').Where(s => s.Length > 0).ToArray(),
            harvestMonth = p.HarvestMonth,
            packSize = p.PackSize,
            nutrition = SafeJson(p.Nutrition),
            categorySlug = p.CategorySlug,
            imageUrl = p.ImageUrl,
            stock = p.Stock,
            inStock,
            variants,
        };
    }

    public static object CategoryDto(Category c) => new
    {
        id = c.Id,
        slug = c.Slug,
        name = c.Name,
        emoji = c.Emoji,
    };

    public static object ReviewDto(Review r) => new
    {
        initials = r.Initials,
        author = r.Author,
        area = r.Area,
        rating = r.Rating,
        text = r.Text,
    };

    public static object ComboDto(ComboPack c) => new
    {
        id = c.Id,
        name = c.Name,
        type = c.Type,
        price = c.Price,
        size = c.Size,
        duration = c.Duration,
        items = c.Items,
        savingsNote = c.SavingsNote,
    };

    public static object SubscriptionDto(SubscriptionPlan s) => new
    {
        id = s.Id,
        name = s.Name,
        description = s.Description,
        priceLabel = s.PriceLabel,
    };

    // Full order shape matching the original Prisma object (with its includes).
    // Navigations that weren't loaded serialise as empty/null, which the Flutter
    // app and admin panel both tolerate.
    public static object OrderDto(Order o) => new
    {
        id = o.Id,
        code = o.Code,
        userId = o.UserId,
        customerName = o.CustomerName,
        phone = o.Phone,
        address = o.Address,
        slot = o.Slot,
        itemTotal = o.ItemTotal,
        savings = o.Savings,
        deliveryFee = o.DeliveryFee,
        total = o.Total,
        couponCode = o.CouponCode,
        paymentMethod = o.PaymentMethod,
        paymentStatus = o.PaymentStatus,
        paymentRef = o.PaymentRef,
        status = o.Status,
        eta = o.Eta,
        destLat = o.DestLat,                  // delivery location (customer map)
        destLng = o.DestLng,
        deliveryOtp = o.DeliveryOtp,          // shown to the customer once out for delivery
        deliveredAt = o.DeliveredAt,
        deliveryPartnerId = o.DeliveryPartnerId,
        createdAt = o.CreatedAt,
        updatedAt = o.UpdatedAt,
        items = (o.Items ?? new()).Select(i => new
        {
            id = i.Id,
            orderId = i.OrderId,
            productId = i.ProductId,
            variantId = i.VariantId,
            name = i.Name,
            quantity = i.Quantity,
            priceLabel = i.PriceLabel,
            price = i.Price,
            qty = i.Qty,
        }),
        events = (o.Events ?? new()).OrderBy(e => e.CreatedAt).Select(e => new
        {
            id = e.Id,
            orderId = e.OrderId,
            status = e.Status,
            note = e.Note,
            createdAt = e.CreatedAt,
        }),
        deliveryPartner = o.DeliveryPartner == null ? null : new
        {
            id = o.DeliveryPartner.Id,
            name = o.DeliveryPartner.Name,
            phone = o.DeliveryPartner.Phone,
            active = o.DeliveryPartner.Active,
            // Live location for the customer's tracking map (only meaningful
            // while the rider is on duty and out for delivery).
            lastLat = o.DeliveryPartner.LastLat,
            lastLng = o.DeliveryPartner.LastLng,
            lastLocationAt = o.DeliveryPartner.LastLocationAt,
        },
        returnRequest = o.ReturnRequest == null ? null : new
        {
            id = o.ReturnRequest.Id,
            orderId = o.ReturnRequest.OrderId,
            userId = o.ReturnRequest.UserId,
            reason = o.ReturnRequest.Reason,
            status = o.ReturnRequest.Status,
            createdAt = o.ReturnRequest.CreatedAt,
            updatedAt = o.ReturnRequest.UpdatedAt,
        },
    };

    public static Dictionary<string, string> SafeJson(string s)
    {
        try
        {
            var v = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(s);
            if (v == null) return new();
            var result = new Dictionary<string, string>();
            foreach (var kv in v)
                result[kv.Key] = kv.Value.ValueKind == JsonValueKind.String
                    ? kv.Value.GetString() ?? ""
                    : kv.Value.ToString();
            return result;
        }
        catch
        {
            return new();
        }
    }
}
