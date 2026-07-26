using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Services;

// Coupon validation + discount math, shared by /coupons/validate and order
// placement so the discount is always computed and enforced server-side.
public static class Coupons
{
    public record Result(bool Valid, int Discount, string? Message, Coupon? Coupon);

    public static string Normalise(string? code) => (code ?? "").Trim().ToUpperInvariant();

    public static async Task<Result> Validate(AppDbContext db, string? code, int itemTotal, string? userId)
    {
        var norm = Normalise(code);
        if (norm.Length == 0) return new Result(false, 0, "Enter a coupon code", null);

        var c = await db.Coupons.FirstOrDefaultAsync(x => x.Code == norm);
        if (c == null || !c.Active) return new Result(false, 0, "Invalid coupon code", null);

        var now = DateTime.UtcNow;
        if (c.ValidFrom != null && now < c.ValidFrom) return new Result(false, 0, "This coupon isn't active yet", null);
        if (c.ValidTo != null && now > c.ValidTo) return new Result(false, 0, "This coupon has expired", null);
        if (c.MinOrder > 0 && itemTotal < c.MinOrder)
            return new Result(false, 0, $"Add ₹{c.MinOrder - itemTotal} more to use this coupon", null);
        if (c.UsageLimit > 0 && c.TimesUsed >= c.UsageLimit)
            return new Result(false, 0, "This coupon has reached its usage limit", null);
        if (c.PerUserLimit > 0 && userId != null)
        {
            var used = await db.Orders.CountAsync(o => o.UserId == userId && o.CouponCode == norm && o.Status != "cancelled");
            if (used >= c.PerUserLimit) return new Result(false, 0, "You've already used this coupon", null);
        }

        var discount = c.Type == "percent"
            ? (int)Math.Floor(itemTotal * (c.Value / 100.0))
            : c.Value;
        if (c.Type == "percent" && c.MaxDiscount > 0) discount = Math.Min(discount, c.MaxDiscount);
        discount = Math.Clamp(discount, 0, itemTotal);   // never exceed the bill

        return new Result(true, discount, $"You saved ₹{discount}", c);
    }
}
