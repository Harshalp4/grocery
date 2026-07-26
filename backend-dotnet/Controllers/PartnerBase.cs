using FarmFresh.Api.Data;
using FarmFresh.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FarmFresh.Api.Controllers;

public abstract class PartnerBase : ControllerBase
{
    /// Load + validate the signed-in partner. Rejects if the account is deactivated
    /// or the token version is stale (instant revocation via TokenVersion). Unless
    /// allowMustChange is true, also 409s while a forced password change is pending.
    protected async Task<(DeliveryPartner? me, IActionResult? error)> LoadPartner(
        AppDbContext db, bool allowMustChange = false)
    {
        var id = User.FindFirst("sub")?.Value;
        var tv = int.TryParse(User.FindFirst("tv")?.Value, out var v) ? v : -1;
        var p = id == null ? null : await db.DeliveryPartners.FirstOrDefaultAsync(x => x.Id == id);
        if (p == null || !p.Active || p.TokenVersion != tv)
            return (null, Unauthorized(new { error = "Session expired. Please sign in again." }));
        if (p.MustChangePassword && !allowMustChange)
            return (null, StatusCode(409, new { error = "Password change required", mustChangePassword = true }));
        return (p, null);
    }
}

public static class PartnerDtos
{
    public static object Profile(DeliveryPartner p) => new
    {
        id = p.Id, name = p.Name, phone = p.Phone, active = p.Active, onDuty = p.OnDuty,
        vehicleType = p.VehicleType, vehicleNumber = p.VehicleNumber, zone = p.Zone,
        mustChangePassword = p.MustChangePassword,
    };
}
