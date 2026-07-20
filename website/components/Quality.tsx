import Image from "next/image";

const ROWS = [
  { label: "Sourcing", mass: "Warehouse aggregators, unknown origin", ff: "Named partner farms, traceable" },
  { label: "Freshness", mass: "Weeks in storage", ff: "Packed within 48 hours of harvest" },
  { label: "Grading", mass: "Mixed grades, no checks", ff: "200+ quality checks per batch" },
  { label: "Pricing", mass: "Multiple middlemen markups", ff: "Farm-direct, fair to both sides" },
];

export function Quality() {
  return (
    <section id="quality" className="mx-auto max-w-7xl px-5 py-16 md:py-24">
      <div className="grid items-center gap-12 lg:grid-cols-2">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
            Quality &amp; transparency
          </p>
          <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
            Not all groceries are created equal
          </h2>
          <p className="mt-3 text-ink/65">
            See how everyday FarmFresh staples compare to typical mass-market supply.
          </p>

          <div className="mt-8 overflow-hidden rounded-2xl ring-1 ring-line">
            <div className="grid grid-cols-[1.1fr_1fr_1fr] bg-beige-deep/60 text-xs font-semibold uppercase tracking-wide text-ink/70">
              <span className="px-4 py-3">&nbsp;</span>
              <span className="px-4 py-3">Typical</span>
              <span className="bg-sage px-4 py-3 text-white">FarmFresh</span>
            </div>
            {ROWS.map((r, i) => (
              <div
                key={r.label}
                className={`grid grid-cols-[1.1fr_1fr_1fr] items-center text-sm ${
                  i % 2 ? "bg-white" : "bg-beige/40"
                }`}
              >
                <span className="px-4 py-3.5 font-semibold text-ink">{r.label}</span>
                <span className="px-4 py-3.5 text-ink/55">{r.mass}</span>
                <span className="flex items-start gap-1.5 bg-sage-soft/70 px-4 py-3.5 font-medium text-sage-dark">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" className="mt-0.5 shrink-0" aria-hidden="true">
                    <path d="M5 12.5l4 4L19 7" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                  {r.ff}
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="relative order-first lg:order-last">
          <div className="relative aspect-[4/5] w-full overflow-hidden rounded-[28px] shadow-xl ring-1 ring-black/5">
            <Image
              src="/images/quality.jpg"
              alt="Fresh, sorted vegetables laid out for quality inspection"
              fill
              sizes="(max-width: 1024px) 100vw, 45vw"
              className="object-cover"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
