import { type Combo } from "@/lib/api";

export function Combos({ combos }: { combos: Combo[] }) {
  return (
    <section id="combos" className="mx-auto max-w-7xl px-5 py-16 md:py-24">
      <div className="mx-auto max-w-2xl text-center">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
          Combo packs
        </p>
        <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
          Ready-made kirana, bundled to save
        </h2>
        <p className="mt-3 text-ink/65">
          Curated monthly bundles for every household — one tap, one price, everything sorted.
        </p>
      </div>

      <div className="mt-12 grid gap-6 md:grid-cols-3">
        {combos.map((c, i) => (
          <div
            key={c.id}
            className={`relative flex flex-col rounded-[26px] p-7 ring-1 transition-transform hover:-translate-y-1 ${
              i === 0
                ? "bg-brand text-white ring-brand"
                : "bg-white text-ink ring-line"
            }`}
          >
            {i === 0 && (
              <span className="absolute right-6 top-6 rounded-full bg-gold px-3 py-1 text-xs font-bold text-brand-dark">
                Most popular
              </span>
            )}
            <p className={`text-xs font-semibold uppercase tracking-wide ${i === 0 ? "text-gold" : "text-brand"}`}>
              {c.size} · {c.duration}
            </p>
            <h3 className="mt-2 font-serif text-2xl font-semibold">{c.name}</h3>
            <p className={`mt-2 text-sm leading-relaxed ${i === 0 ? "text-white/80" : "text-ink/65"}`}>
              {c.items}
            </p>

            <div className="mt-6 flex items-baseline gap-2">
              <span className="text-3xl font-semibold">₹{c.price.toLocaleString("en-IN")}</span>
              <span className={`text-sm ${i === 0 ? "text-white/70" : "text-muted"}`}>/ {c.duration}</span>
            </div>
            <p className={`mt-1 text-xs font-medium ${i === 0 ? "text-gold" : "text-amber-ink"}`}>
              {c.savingsNote}
            </p>

            <a
              href="#download"
              className={`mt-6 rounded-full px-5 py-3 text-center text-sm font-semibold transition-colors ${
                i === 0
                  ? "bg-white text-brand hover:bg-beige"
                  : "bg-brand text-white hover:bg-brand-dark"
              }`}
            >
              Get this pack
            </a>
          </div>
        ))}
      </div>
    </section>
  );
}
