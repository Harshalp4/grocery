const CARDS = [
  {
    icon: "🎁",
    title: "Refer a family",
    text: "Invite friends and you both get ₹150 off your next order. No limits.",
  },
  {
    icon: "🏢",
    title: "Society bulk orders",
    text: "Get your building on FarmFresh for wholesale pricing on monthly staples.",
  },
  {
    icon: "🚚",
    title: "Group delivery",
    text: "Neighbours order together, split one slot, and save on every basket.",
  },
];

export function Referrals() {
  return (
    <section className="mx-auto max-w-7xl px-5 py-16 md:py-24">
      <div className="overflow-hidden rounded-[32px] bg-gold-soft px-6 py-12 ring-1 ring-gold/30 sm:px-12">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-serif text-3xl font-semibold text-ink sm:text-4xl">
            Better together
          </h2>
          <p className="mt-3 text-ink/65">
            Refer a friend, rally your building, or buy as a group — FarmFresh rewards
            every way of shopping together.
          </p>
        </div>

        <div className="mt-10 grid gap-5 md:grid-cols-3">
          {CARDS.map((c) => (
            <div key={c.title} className="rounded-2xl bg-white p-6 text-center ring-1 ring-line">
              <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-sage-soft text-2xl">
                {c.icon}
              </div>
              <h3 className="mt-4 font-semibold text-ink">{c.title}</h3>
              <p className="mt-2 text-sm text-ink/65">{c.text}</p>
            </div>
          ))}
        </div>

        <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <a
            href="#download"
            className="rounded-full bg-brand px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-brand-dark"
          >
            Refer &amp; earn
          </a>
          <a
            href="https://wa.me/919000000000"
            className="inline-flex items-center gap-2 rounded-full border border-ink/15 bg-white px-6 py-3.5 text-sm font-semibold text-ink transition-colors hover:border-brand hover:text-brand"
          >
            <span aria-hidden="true">💬</span> Order on WhatsApp
          </a>
        </div>
      </div>
    </section>
  );
}
