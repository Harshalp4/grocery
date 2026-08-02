using System.Text.Json;
using System.Text.RegularExpressions;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using FarmFresh.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// The rider's own orders. Every handler is scoped to o.DeliveryPartnerId == me.Id,
// so a partner can never read or touch an order that isn't assigned to them.
[Authorize(Policy = "Partner")]
public class PartnerOrdersController : PartnerBase
{
    private readonly AppDbContext _db;
    private readonly IWebHostEnvironment _env;
    public PartnerOrdersController(AppDbContext db, IWebHostEnvironment env) { _db = db; _env = env; }

    private static readonly string[] ActiveScope = { "packed", "picked_up", "out_for_delivery", "failed" };

    private static object Card(Order o) => new
    {
        id = o.Id, code = o.Code, status = o.Status,
        customerName = o.CustomerName, area = o.Address, slot = o.Slot,
        paymentMethod = o.PaymentMethod,
        codToCollect = o.PaymentMethod == "cod" && o.PaymentStatus != "paid" ? o.Total : 0,
        total = o.Total,
        itemCount = (o.Items ?? new()).Sum(i => i.Qty),
        assignedAt = o.AssignedAt,
    };

    private static object Full(Order o) => new
    {
        id = o.Id, code = o.Code, status = o.Status,
        customerName = o.CustomerName, phone = o.Phone, address = o.Address,
        dest = new { lat = o.DestLat, lng = o.DestLng },
        slot = o.Slot, paymentMethod = o.PaymentMethod, total = o.Total,
        codToCollect = o.PaymentMethod == "cod" && o.PaymentStatus != "paid" ? o.Total : 0,
        items = (o.Items ?? new()).Select(i => new { name = i.Name, quantity = i.Quantity, qty = i.Qty, priceLabel = i.PriceLabel }),
        pickedUpAt = o.PickedUpAt, deliveredAt = o.DeliveredAt, failureReason = o.FailureReason,
    };

    // GET /partner/orders?scope=active|history
    [HttpGet("/partner/orders")]
    public async Task<IActionResult> Orders([FromQuery] string? scope)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        var q = _db.Orders.Where(o => o.DeliveryPartnerId == me!.Id).Include(o => o.Items);
        List<Order> rows;
        if (scope == "history")
            rows = await q.Where(o => o.Status == "delivered" || o.Status == "failed")
                .OrderByDescending(o => o.UpdatedAt).Take(100).ToListAsync();
        else
            rows = await q.Where(o => ActiveScope.Contains(o.Status))
                .OrderBy(o => o.AssignedAt).ToListAsync();
        return Ok(rows.Select(Card));
    }

    // GET /partner/orders/{id}
    [HttpGet("/partner/orders/{id}")]
    public async Task<IActionResult> Detail(string id)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        var o = await _db.Orders.Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.Id == id && x.DeliveryPartnerId == me!.Id);
        if (o == null) return NotFound(new { error = "Order not found" });
        return Ok(Full(o));
    }

    // POST /partner/orders/{id}/status { status }  — picked_up | out_for_delivery
    [HttpPost("/partner/orders/{id}/status")]
    public async Task<IActionResult> SetStatus(string id, [FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == id && o.DeliveryPartnerId == me!.Id);
        if (order == null) return NotFound(new { error = "Order not found" });
        var status = body.Str("status");

        if (status == "picked_up")
        {
            if (order.Status != "packed") return Conflict(new { error = "Order isn't ready to pick up" });
            order.Status = "picked_up";
            order.PickedUpAt = DateTime.UtcNow;
        }
        else if (status == "out_for_delivery")
        {
            if (order.Status != "picked_up") return Conflict(new { error = "Pick the order up first" });
            order.Status = "out_for_delivery";
            order.DeliveryOtp = Random.Shared.Next(1000, 10000).ToString();
            order.DeliveryOtpSentAt = DateTime.UtcNow;
            order.DeliveryOtpAttempts = 0;
        }
        else
        {
            return BadRequest(new { error = "A rider can only set picked_up or out_for_delivery" });
        }

        _db.OrderEvents.Add(new OrderEvent { OrderId = order.Id, Status = order.Status });
        await _db.SaveChangesAsync();
        await NotifyCustomer(order);
        return Ok(Full(order));
    }

    // POST /partner/orders/{id}/deliver { otp, codCollected, note?, photoDataUrl? }
    [HttpPost("/partner/orders/{id}/deliver")]
    public async Task<IActionResult> Deliver(string id, [FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == id && o.DeliveryPartnerId == me!.Id);
        if (order == null) return NotFound(new { error = "Order not found" });
        if (order.Status != "out_for_delivery")
            return Conflict(new { error = "Start the delivery before completing it" });

        var otp = body.Str("otp") ?? "";
        var photo = body.Str("photoDataUrl");
        if (otp != order.DeliveryOtp)
        {
            order.DeliveryOtpAttempts++;
            await _db.SaveChangesAsync();
            if (order.DeliveryOtpAttempts < 3)
                return BadRequest(new { error = "Incorrect delivery code", attemptsLeft = 3 - order.DeliveryOtpAttempts });
            // After 3 failures, allow completion only with a proof photo.
            if (string.IsNullOrEmpty(photo))
                return BadRequest(new { error = "Code failed 3×. Capture a delivery photo to complete." });
        }

        if (!string.IsNullOrEmpty(photo))
        {
            var url = await SaveProof(order.Id, photo);
            if (url == null) return BadRequest(new { error = "Unsupported photo (png/jpg/webp, max 3 MB)" });
            order.ProofPhotoUrl = url;
        }

        order.Status = "delivered";
        order.DeliveredAt = DateTime.UtcNow;
        order.CodCollected = order.PaymentMethod == "cod" ? Math.Max(0, body.IntOr("codCollected", order.Total)) : 0;
        order.DeliveryNote = body.Str("note");
        _db.OrderEvents.Add(new OrderEvent { OrderId = order.Id, Status = "delivered", Note = "Delivered by rider" });
        await _db.SaveChangesAsync();
        await NotifyCustomer(order);
        return Ok(Full(order));
    }

    // POST /partner/orders/{id}/fail { reason }
    [HttpPost("/partner/orders/{id}/fail")]
    public async Task<IActionResult> Fail(string id, [FromBody] JsonElement body)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == id && o.DeliveryPartnerId == me!.Id);
        if (order == null) return NotFound(new { error = "Order not found" });
        if (order.Status is not ("picked_up" or "out_for_delivery"))
            return Conflict(new { error = "Order can't be marked failed from its current state" });
        var reason = body.Str("reason");
        if (string.IsNullOrWhiteSpace(reason)) return BadRequest(new { error = "A reason is required" });

        order.Status = "failed";
        order.FailureReason = reason!.Trim();
        _db.OrderEvents.Add(new OrderEvent { OrderId = order.Id, Status = "failed", Note = reason.Trim() });
        await _db.SaveChangesAsync();
        await NotifyCustomer(order);
        return Ok(Full(order));
    }

    // GET /partner/summary?date=yyyy-MM-dd  (defaults to today, UTC)
    [HttpGet("/partner/summary")]
    public async Task<IActionResult> Summary([FromQuery] string? date)
    {
        var (me, err) = await LoadPartner(_db);
        if (err != null) return err;
        var day = DateTime.TryParse(date, out var d) ? d.Date : DateTime.UtcNow.Date;
        var next = day.AddDays(1);
        var delivered = await _db.Orders
            .Where(o => o.DeliveryPartnerId == me!.Id && o.DeliveredAt >= day && o.DeliveredAt < next).ToListAsync();
        var failed = await _db.Orders.CountAsync(o => o.DeliveryPartnerId == me!.Id
            && o.Status == "failed" && o.UpdatedAt >= day && o.UpdatedAt < next);
        return Ok(new
        {
            date = day,
            delivered = delivered.Count,
            failed,
            codCollected = delivered.Sum(o => o.CodCollected),
            firstAt = delivered.Min(o => (DateTime?)o.DeliveredAt),
            lastAt = delivered.Max(o => (DateTime?)o.DeliveredAt),
        });
    }

    private async Task NotifyCustomer(Order order)
    {
        if (order.UserId == null) return;
        var (title, bodyText) = order.Status switch
        {
            "picked_up" => ("Picked up", $"Your order {order.Code} has been picked up."),
            "out_for_delivery" => ("Out for delivery", $"Your order {order.Code} is on its way! Share code {order.DeliveryOtp} with your delivery partner."),
            "delivered" => ("Delivered", $"Your order {order.Code} has been delivered. Enjoy! 🌾"),
            "failed" => ("Delivery attempt failed", $"We couldn't deliver order {order.Code}. We'll reach out to reschedule."),
            _ => ("Order update", $"Your order {order.Code} is now {order.Status}."),
        };
        await Notify.ToUser(_db, order.UserId, title, bodyText, "order", order.Id);
    }

    private async Task<string?> SaveProof(string orderId, string dataUrl)
    {
        var m = Regex.Match(dataUrl, @"^data:image/(png|jpe?g|webp);base64,(.+)$");
        if (!m.Success) return null;
        var ext = m.Groups[1].Value == "jpeg" ? "jpg" : m.Groups[1].Value;
        byte[] buf;
        try { buf = Convert.FromBase64String(m.Groups[2].Value); } catch { return null; }
        if (buf.Length > 3_000_000) return null;

        if (Services.ImageStore.Configured)
            return await Services.ImageStore.UploadAsync(buf, ext, "farmfresh/proof", $"{orderId}-{Guid.NewGuid():N}");

        var dir = Path.Combine(_env.ContentRootPath, "uploads", "proof");
        Directory.CreateDirectory(dir);
        var file = $"{orderId}-{Guid.NewGuid():N}.{ext}";
        System.IO.File.WriteAllBytes(Path.Combine(dir, file), buf);
        return $"/uploads/proof/{file}";
    }
}
