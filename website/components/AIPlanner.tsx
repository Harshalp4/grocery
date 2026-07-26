const SAMPLE = [
  "Family of 4 · veg · ₹4,000/mo",
  "→ 5kg rice, 3kg atta, 2kg toor dal",
  "→ 1L groundnut oil, 12 spices kit",
  "→ tea, sugar, 8 millet packs…",
];

export function AIPlanner() {
  return (
    <section className="bg-espresso text-white">
      <div className="mx-auto grid max-w-7xl items-center gap-12 px-5 py-16 md:grid-cols-2 md:py-24">
        <div>
          <span className="inline-flex items-center gap-2 rounded-full bg-white/10 px-3.5 py-1.5 text-xs font-semibold text-gold">
            <span className="h-1.5 w-1.5 rounded-full bg-gold" />
            Powered by AI
          </span>
          <h2 className="mt-5 font-serif text-3xl font-semibold sm:text-4xl">
            Your monthly kirana, planned in seconds
          </h2>
          <p className="mt-4 max-w-lg text-white/75">
            Tell the FarmFresh app your family size, budget and food preferences — and
            our AI Grocery Planner builds a complete monthly cart for you, balanced for
            nutrition and value. Review it, tweak it, and check out in one tap.
          </p>
          <div className="mt-7 flex flex-wrap gap-3">
            <a
              href="#download"
              className="rounded-full bg-gold px-6 py-3.5 text-sm font-semibold text-espresso transition-transform hover:-translate-y-0.5"
            >
              Try the Planner
            </a>
            <a
              href="#combos"
              className="rounded-full border border-white/25 px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-white/10"
            >
              See combo packs
            </a>
          </div>
        </div>

        <div className="rounded-[26px] bg-white/5 p-6 ring-1 ring-white/15 backdrop-blur">
          <div className="flex items-center gap-2 border-b border-white/10 pb-3">
            <span className="h-2.5 w-2.5 rounded-full bg-white/25" />
            <span className="h-2.5 w-2.5 rounded-full bg-white/25" />
            <span className="h-2.5 w-2.5 rounded-full bg-white/25" />
            <span className="ml-2 text-xs text-white/50">AI Grocery Planner</span>
          </div>
          <div className="space-y-2.5 pt-4 font-mono text-sm">
            {SAMPLE.map((line, i) => (
              <p
                key={i}
                className={
                  i === 0
                    ? "rounded-lg bg-white/10 px-3 py-2 text-white"
                    : "px-3 text-white/80"
                }
              >
                {line}
              </p>
            ))}
            <p className="mt-3 flex items-center justify-between rounded-lg bg-gold/20 px-3 py-2.5 text-white">
              <span className="font-semibold">Optimised cart ready</span>
              <span className="font-semibold text-gold">₹3,940 · save ₹460</span>
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
