using System.Text.Json;

namespace FarmFresh.Api.Controllers;

// Small helpers for reading request-body JsonElements the way the original zod
// schemas did (with defaults), keeping the controllers terse.
public static class JsonX
{
    public static bool IsObject(this JsonElement e) => e.ValueKind == JsonValueKind.Object;

    public static string? Str(this JsonElement e, string key)
        => e.ValueKind == JsonValueKind.Object && e.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.String
            ? v.GetString() : null;

    public static string StrOr(this JsonElement e, string key, string def) => e.Str(key) ?? def;

    public static int IntOr(this JsonElement e, string key, int def)
        => e.ValueKind == JsonValueKind.Object && e.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.Number
            ? v.GetInt32() : def;

    public static bool BoolOr(this JsonElement e, string key, bool def)
    {
        if (e.ValueKind == JsonValueKind.Object && e.TryGetProperty(key, out var v))
        {
            if (v.ValueKind == JsonValueKind.True) return true;
            if (v.ValueKind == JsonValueKind.False) return false;
        }
        return def;
    }

    public static bool Has(this JsonElement e, string key)
        => e.ValueKind == JsonValueKind.Object && e.TryGetProperty(key, out var v) && v.ValueKind != JsonValueKind.Null;

    public static string[] StrArray(this JsonElement e, string key)
    {
        if (e.ValueKind == JsonValueKind.Object && e.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.Array)
            return v.EnumerateArray().Where(x => x.ValueKind == JsonValueKind.String).Select(x => x.GetString()!).ToArray();
        return Array.Empty<string>();
    }

    /// The raw JSON text of an object-valued property (for nutrition), or "{}".
    public static string RawObjectOr(this JsonElement e, string key, string def)
        => e.ValueKind == JsonValueKind.Object && e.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.Object
            ? v.GetRawText() : def;
}
