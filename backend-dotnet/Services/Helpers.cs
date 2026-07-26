namespace FarmFresh.Api.Services;

// Port of backend/src/payments.ts + the OTP helpers in customerAuth.ts.
public static class Payments
{
    public record Result(string Status, string? Ref);

    private static bool HasRazorpay =>
        !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RAZORPAY_KEY_ID")) &&
        !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("RAZORPAY_KEY_SECRET"));

    // COD is real (collected on delivery); online (upi/card) is a test stub that
    // simulates an instant successful capture, so the full flow is testable.
    public static Result Charge(string method, int amountRupees)
    {
        if (method == "cod") return new Result("pending", null);
        if (HasRazorpay) throw new NotImplementedException("Razorpay integration not implemented yet");
        var re = $"SIMULATED-{method.ToUpperInvariant()}-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
        return new Result("paid", re);
    }
}

public static class Otp
{
    private static readonly Random Rng = new();

    /// Dev mode returns the OTP in the response so login is testable without SMS.
    public static bool DevMode =>
        Environment.GetEnvironmentVariable("OTP_DEV_MODE") != "false";

    /// A 4-digit OTP (1000–9999).
    public static string Generate() => (1000 + Rng.Next(9000)).ToString();

    /// Deliver the OTP. In dev this just logs it; wire MSG91/Twilio here for prod.
    public static void SendSms(string phone, string code)
        => Console.WriteLine($"[OTP] {phone} -> {code}");
}
