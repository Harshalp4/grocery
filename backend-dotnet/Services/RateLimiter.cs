using System.Collections.Concurrent;

namespace FarmFresh.Api.Services;

// Small in-memory sliding-window rate limiter, keyed by an arbitrary string
// (phone, IP, …). Sufficient for a single-instance backend; for a multi-instance
// deployment back this with Redis so the window is shared across nodes.
public class RateLimiter
{
    private readonly ConcurrentDictionary<string, List<DateTime>> _hits = new();

    /// Records a hit and returns true if under the limit, false if over it.
    public bool Allow(string key, int max, TimeSpan window)
    {
        var now = DateTime.UtcNow;
        var list = _hits.GetOrAdd(key, _ => new List<DateTime>());
        lock (list)
        {
            list.RemoveAll(t => now - t > window);
            if (list.Count >= max) return false;
            list.Add(now);
            return true;
        }
    }
}
