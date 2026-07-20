import Image from "next/image";

const MODELS = [
  {
    img: "/images/quick-delivery.jpg",
    tag: "Quick Delivery",
    title: "Groceries in hours, not days",
    text: "Order what you need and get it delivered the same day — fresh produce, dairy and daily essentials at your door.",
    points: ["Same-day slots", "Live order tracking", "No minimum order"],
    cta: "Order now",
  },
  {
    img: "/images/subscription-box.jpg",
    tag: "Mornings",
    title: "Set it once, never run out",
    text: "Subscribe to milk, bread, fruits or your monthly kirana and we&rsquo;ll refill it automatically — pause or edit anytime.",
    points: ["Flexible schedules", "Pause or skip freely", "Member-only pricing"],
    cta: "Start a subscription",
  },
];

export function ServiceModels() {
  return (
    <section id="subscriptions" className="mx-auto max-w-7xl px-5 py-16 md:py-24">
      <div className="mx-auto max-w-2xl text-center">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
          Two ways to shop
        </p>
        <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
          Delivered your way
        </h2>
      </div>

      <div className="mt-12 grid gap-6 md:grid-cols-2">
        {MODELS.map((m) => (
          <div
            key={m.tag}
            className="group overflow-hidden rounded-[26px] bg-white ring-1 ring-line transition-shadow hover:shadow-xl"
          >
            <div className="relative aspect-[16/9] w-full overflow-hidden">
              <Image
                src={m.img}
                alt={m.title}
                fill
                sizes="(max-width: 768px) 100vw, 50vw"
                className="object-cover transition-transform duration-500 group-hover:scale-105"
              />
              <span className="absolute left-4 top-4 rounded-full bg-white/90 px-3 py-1 text-xs font-bold uppercase tracking-wide text-brand shadow-sm">
                {m.tag}
              </span>
            </div>
            <div className="p-6">
              <h3 className="font-serif text-2xl font-semibold text-ink">{m.title}</h3>
              <p
                className="mt-2 text-sm leading-relaxed text-ink/65"
                dangerouslySetInnerHTML={{ __html: m.text }}
              />
              <ul className="mt-4 flex flex-wrap gap-x-5 gap-y-2">
                {m.points.map((pt) => (
                  <li key={pt} className="flex items-center gap-1.5 text-sm font-medium text-ink/75">
                    <span className="h-1.5 w-1.5 rounded-full bg-gold" />
                    {pt}
                  </li>
                ))}
              </ul>
              <a
                href="#download"
                className="mt-6 inline-flex items-center gap-1.5 text-sm font-semibold text-brand hover:text-brand-dark"
              >
                {m.cta}
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                  <path d="M5 12h14M13 6l6 6-6 6" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </a>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
