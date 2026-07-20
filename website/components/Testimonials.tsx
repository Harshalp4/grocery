import Image from "next/image";

const REVIEWS = [
  {
    avatar: "/images/avatar-1.jpg",
    name: "Priya Deshpande",
    area: "Powai, Mumbai",
    rating: 5,
    text: "The atta and dals actually taste different — you can tell it&rsquo;s fresh. Monthly kirana lands on the same day every time.",
  },
  {
    avatar: "/images/avatar-2.jpg",
    name: "Rahul Menon",
    area: "Vashi, Navi Mumbai",
    rating: 5,
    text: "The AI planner built my whole month&rsquo;s cart in under a minute and saved me around ₹500. Genuinely useful, not a gimmick.",
  },
  {
    avatar: "/images/avatar-3.jpg",
    name: "Sneha Kulkarni",
    area: "Chembur, Mumbai",
    rating: 5,
    text: "Cold-pressed oil and forest honey are pantry staples now. Quality is consistent and delivery is quick every single time.",
  },
];

function Stars({ n }: { n: number }) {
  return (
    <div className="flex gap-0.5 text-gold" aria-label={`${n} out of 5 stars`}>
      {Array.from({ length: 5 }).map((_, i) => (
        <svg key={i} width="15" height="15" viewBox="0 0 24 24" fill={i < n ? "currentColor" : "none"} stroke="currentColor" strokeWidth="1.5" aria-hidden="true">
          <path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.8 6.1 20.5l1.2-6.5-4.8-4.6 6.6-.9z" strokeLinejoin="round" />
        </svg>
      ))}
    </div>
  );
}

export function Testimonials() {
  return (
    <section className="bg-beige">
      <div className="mx-auto max-w-7xl px-5 py-16 md:py-24">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
            Loved across the city
          </p>
          <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
            What Mumbai &amp; Navi Mumbai say
          </h2>
        </div>

        <div className="mt-12 grid gap-6 md:grid-cols-3">
          {REVIEWS.map((r) => (
            <figure key={r.name} className="flex flex-col rounded-2xl bg-white p-6 ring-1 ring-line">
              <Stars n={r.rating} />
              <blockquote
                className="mt-4 flex-1 text-sm leading-relaxed text-ink/75"
                dangerouslySetInnerHTML={{ __html: `&ldquo;${r.text}&rdquo;` }}
              />
              <figcaption className="mt-5 flex items-center gap-3">
                <span className="relative h-10 w-10 overflow-hidden rounded-full ring-1 ring-line">
                  <Image src={r.avatar} alt={r.name} fill sizes="40px" className="object-cover" />
                </span>
                <span>
                  <span className="block text-sm font-semibold text-ink">{r.name}</span>
                  <span className="block text-xs text-muted">{r.area}</span>
                </span>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
