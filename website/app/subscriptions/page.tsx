import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { PageHeader } from "@/components/PageHeader";
import { Combos } from "@/components/Combos";
import { getCombos, getSubscriptions } from "@/lib/api";

export const metadata: Metadata = {
  title: "Subscriptions & Combo Packs — FarmFresh",
  description:
    "Set it once and never run out — daily milk & bread, weekly produce, or a monthly kirana refill. Plus ready-made combo packs bundled to save.",
};

export default async function SubscriptionsPage() {
  const [subscriptions, combos] = await Promise.all([
    getSubscriptions(),
    getCombos(),
  ]);

  return (
    <>
      <Header />
      <main>
        <PageHeader
          eyebrow="Subscriptions"
          title="Set it once, never run out"
          subtitle="Put your essentials on autopilot. Choose a schedule, pause or skip anytime, and enjoy member-only pricing on every delivery."
        />

        <section className="mx-auto max-w-7xl px-5 py-14 md:py-20">
          <div className="grid gap-6 md:grid-cols-3">
            {subscriptions.map((s) => (
              <div
                key={s.id}
                className="flex flex-col rounded-[26px] bg-white p-7 ring-1 ring-line transition-transform hover:-translate-y-1 hover:shadow-lg"
              >
                <span className="grid h-12 w-12 place-items-center rounded-full bg-sage-soft text-xl">
                  🗓️
                </span>
                <h2 className="mt-4 font-serif text-2xl font-semibold text-ink">
                  {s.name}
                </h2>
                <p className="mt-2 flex-1 text-sm leading-relaxed text-ink/65">
                  {s.description}
                </p>
                <p className="mt-4 text-lg font-semibold text-brand">{s.priceLabel}</p>
                <a
                  href="/#download"
                  className="mt-5 rounded-full bg-brand px-5 py-3 text-center text-sm font-semibold text-white transition-colors hover:bg-brand-dark"
                >
                  Start subscription
                </a>
              </div>
            ))}
          </div>

          <ul className="mt-10 flex flex-wrap justify-center gap-x-8 gap-y-3 text-sm font-medium text-ink/75">
            {["Flexible schedules", "Pause or skip freely", "Member-only pricing", "No lock-in"].map(
              (f) => (
                <li key={f} className="flex items-center gap-2">
                  <span className="h-1.5 w-1.5 rounded-full bg-gold" />
                  {f}
                </li>
              ),
            )}
          </ul>
        </section>

        <Combos combos={combos} />
      </main>
      <Footer />
    </>
  );
}
