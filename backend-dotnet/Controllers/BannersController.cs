using FarmFresh.Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

// Public home-screen banners (managed from the admin CMS).
public class BannersController : ControllerBase
{
    private readonly AppDbContext _db;
    public BannersController(AppDbContext db) => _db = db;

    // GET /banners -> active banners, ordered
    [HttpGet("/banners")]
    public async Task<IActionResult> Get()
    {
        var rows = await _db.Banners.Where(b => b.Active)
            .OrderBy(b => b.SortOrder).ToListAsync();
        return Ok(rows.Select(b => new
        {
            id = b.Id, title = b.Title, subtitle = b.Subtitle, imageUrl = b.ImageUrl,
            actionType = b.ActionType, actionValue = b.ActionValue,
        }));
    }
}
