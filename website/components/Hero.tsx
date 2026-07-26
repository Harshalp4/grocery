import Image from "next/image";

const CHIPS = ["100% Farm-Sourced", "Same-Day Delivery", "Quality-Graded"];

export function Hero() {
  return (
    <section id="top" className="relative overflow-hidden bg-beige">
      <div className="mx-auto grid max-w-7xl items-center gap-10 px-5 py-14 md:grid-cols-2 md:py-20">
        <div className="ff-rise">
          <span className="inline-flex items-center gap-2 rounded-full border border-gold/40 bg-gold-soft px-3.5 py-1.5 text-xs font-semibold text-amber-ink">
            <span className="h-1.5 w-1.5 rounded-full bg-gold" />
            Curated Slow. Delivered Fast.
          </span>
          <h1 className="mt-5 font-serif text-4xl font-semibold leading-[1.08] tracking-tight text-ink sm:text-5xl lg:text-6xl">
            Farm-fresh groceries you{" "}
            <span className="text-brand">don&rsquo;t have to</span> second-guess.
          </h1>
          <p className="mt-5 max-w-lg text-base leading-relaxed text-ink/70 sm:text-lg">
            Only trusted, tasted and tested staples — sourced straight from farms,
            quality-graded, and delivered to your door across Mumbai &amp; Navi Mumbai.
          </p>

          <div className="mt-7 flex flex-wrap items-center gap-3">
            <a
              href="#download"
              className="rounded-full bg-brand px-6 py-3.5 text-sm font-semibold text-white shadow-md transition-transform hover:-translate-y-0.5 hover:bg-brand-dark"
            >
              Download the App
            </a>
            <a
              href="#categories"
              className="rounded-full border border-ink/15 bg-white px-6 py-3.5 text-sm font-semibold text-ink transition-colors hover:border-brand hover:text-brand"
            >
              Browse Categories
            </a>
          </div>

          <ul className="mt-8 flex flex-wrap gap-x-6 gap-y-3">
            {CHIPS.map((c) => (
              <li key={c} className="flex items-center gap-2 text-sm font-medium text-ink/75">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" className="text-sage" aria-hidden="true">
                  <circle cx="12" cy="12" r="11" fill="currentColor" opacity="0.12" />
                  <path d="M7 12.5l3.2 3.2L17 9" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
                {c}
              </li>
            ))}
          </ul>
        </div>

        <div className="ff-rise relative" style={{ animationDelay: "0.1s" }}>
          <div className="relative aspect-[4/5] w-full overflow-hidden rounded-[28px] shadow-2xl ring-1 ring-black/5 sm:aspect-[5/5]">
            <Image
              src="/images/hero.jpg"
              alt="A basket of fresh farm vegetables and produce"
              fill
              priority
              sizes="(max-width: 768px) 100vw, 45vw"
              className="object-cover"
            />
          </div>

          {/* Floating trust card */}
          <div className="absolute -bottom-5 -left-3 flex items-center gap-3 rounded-2xl bg-white/95 px-4 py-3 shadow-xl ring-1 ring-black/5 backdrop-blur sm:-left-6">
            <div className="grid h-11 w-11 place-items-center rounded-full bg-brand-soft text-lg">🌾</div>
            <div>
              <p className="text-sm font-semibold text-ink">200+ quality checks</p>
              <p className="text-xs text-muted">on every batch we deliver</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
