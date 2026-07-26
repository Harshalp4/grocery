using Microsoft.AspNetCore.Mvc;

namespace FarmFresh.Api.Controllers;

public static class ControllerExtensions
{
    /// The signed-in customer's user id (the JWT "sub" claim), or null.
    public static string? CustomerId(this ControllerBase c)
        => c.User.FindFirst("sub")?.Value;
}
