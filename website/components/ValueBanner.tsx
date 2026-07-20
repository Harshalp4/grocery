const PROMISES = [
  "NO ADULTERATION",
  "NO STALE STOCK",
  "FARM-DIRECT PRICING",
  "QUALITY-GRADED",
  "TRANSPARENT SOURCING",
  "NO HIDDEN CHEMICALS",
];

export function ValueBanner() {
  // Duplicate the list so the marquee loops seamlessly.
  const loop = [...PROMISES, ...PROMISES];
  return (
    <div className="overflow-hidden border-y border-sage-dark/20 bg-sage py-3.5 text-white">
      <div className="ff-marquee flex w-max items-center gap-8 whitespace-nowrap">
        {loop.map((p, i) => (
          <span key={i} className="flex items-center gap-8 text-sm font-semibold tracking-wide">
            {p}
            <span className="text-gold" aria-hidden="true">
              ✦
            </span>
          </span>
        ))}
      </div>
    </div>
  );
}
