import Image from "next/image";

const STEPS = [
  { icon: "🌱", title: "Sourced Direct", text: "Bought straight from partner farms — no middlemen, fair prices." },
  { icon: "🔍", title: "Quality-Graded", text: "Every batch inspected and graded before it earns the FarmFresh label." },
  { icon: "📦", title: "Freshly Packed", text: "Cleaned, weighed and sealed the same day for peak freshness." },
  { icon: "🛵", title: "Delivered Fast", text: "At your door within hours, across Mumbai & Navi Mumbai." },
];

export function Journey() {
  return (
    <section id="journey" className="bg-beige">
      <div className="mx-auto max-w-7xl px-5 py-16 md:py-24">
        <div className="grid items-center gap-12 lg:grid-cols-2">
          <div className="relative">
            <div className="relative aspect-[4/3] w-full overflow-hidden rounded-[28px] shadow-xl ring-1 ring-black/5">
              <Image
                src="/images/farm.jpg"
                alt="A farmer harvesting fresh produce in the field"
                fill
                sizes="(max-width: 1024px) 100vw, 50vw"
                className="object-cover"
              />
            </div>
            <div className="absolute -right-3 -top-4 rounded-2xl bg-white px-4 py-3 shadow-lg ring-1 ring-black/5 sm:-right-5">
              <p className="text-2xl font-semibold text-brand">48h</p>
              <p className="text-xs text-muted">farm → your door</p>
            </div>
          </div>

          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
              The FarmFresh journey
            </p>
            <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
              From the farm to your home
            </h2>
            <p className="mt-3 text-ink/65">
              We shorten the distance between the field and your kitchen — so you get
              produce at its freshest, at a price that&rsquo;s fair to farmers.
            </p>

            <ol className="mt-8 space-y-5">
              {STEPS.map((s, i) => (
                <li key={s.title} className="flex gap-4">
                  <div className="relative flex flex-col items-center">
                    <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-white text-lg shadow-sm ring-1 ring-line">
                      {s.icon}
                    </span>
                    {i < STEPS.length - 1 && (
                      <span className="mt-1 w-px flex-1 bg-line" aria-hidden="true" />
                    )}
                  </div>
                  <div className="pb-1">
                    <h3 className="font-semibold text-ink">{s.title}</h3>
                    <p className="mt-1 text-sm text-ink/65">{s.text}</p>
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </div>
      </div>
    </section>
  );
}
