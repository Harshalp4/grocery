using System.Text.Json;
using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Customer support tickets.
[Authorize(Policy = "Customer")]
public class SupportController : ControllerBase
{
    private readonly AppDbContext _db;
    public SupportController(AppDbContext db) => _db = db;

    private static object Dto(SupportTicket t) => new
    {
        id = t.Id, subject = t.Subject, message = t.Message, status = t.Status,
        reply = t.Reply, orderId = t.OrderId, createdAt = t.CreatedAt, updatedAt = t.UpdatedAt,
    };

    // GET /support -> my tickets
    [HttpGet("/support")]
    public async Task<IActionResult> List()
    {
        var uid = this.CustomerId();
        var rows = await _db.SupportTickets.Where(t => t.UserId == uid)
            .OrderByDescending(t => t.CreatedAt).ToListAsync();
        return Ok(rows.Select(Dto));
    }

    // POST /support { subject, message, orderId? } -> raise a ticket
    [HttpPost("/support")]
    public async Task<IActionResult> Create([FromBody] JsonElement body)
    {
        var uid = this.CustomerId()!;
        var subject = body.Str("subject");
        var message = body.Str("message");
        if (string.IsNullOrWhiteSpace(subject) || string.IsNullOrWhiteSpace(message))
            return BadRequest(new { error = "Subject and message are required" });
        var row = new SupportTicket
        {
            UserId = uid,
            Subject = subject!.Trim(),
            Message = message!.Trim(),
            OrderId = body.Str("orderId"),
        };
        _db.SupportTickets.Add(row);
        await _db.SaveChangesAsync();
        return StatusCode(201, Dto(row));
    }
}
