import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { PageHeader } from "@/components/PageHeader";
import { Journey } from "@/components/Journey";
import { Quality } from "@/components/Quality";

export const metadata: Metadata = {
  title: "How It Works — FarmFresh",
  description:
    "From partner farms to your door in 48 hours — how FarmFresh sources, grades, packs and delivers groceries you can trust.",
};

const FAQS = [
  {
    q: "Where do you deliver?",
    a: "Across Mumbai and Navi Mumbai today, with new neighbourhoods added every month. Enter your pincode in the app to check same-day availability.",
  },
  {
    q: "How fresh is 'farm-fresh'?",
    a: "Most produce reaches you within 48 hours of harvest. Staples are milled and packed the same day they're dispatched, never left ageing in a warehouse.",
  },
  {
    q: "What does 'quality-graded' mean?",
    a: "Every batch passes 200+ checks — for origin, moisture, purity and grade — before it earns the FarmFresh label. Anything that fails is rejected, not discounted.",
  },
  {
    q: "How do payments work?",
    a: "Cash on delivery today, with UPI and card coming soon. You only pay for what's delivered — short-weight or damaged items are refunded instantly.",
  },
  {
    q: "Can I subscribe instead of ordering each time?",
    a: "Yes. Put milk, bread, produce or your monthly kirana on a schedule, and pause, skip or edit it anytime from the app.",
  },
];

export default function HowItWorksPage() {
  return (
    <>
      <Header />
      <main>
        <PageHeader
          eyebrow="How it works"
          title="From the farm to your home"
          subtitle="We shorten the distance between the field and your kitchen — so you get produce at its freshest, at a price that's fair to farmers."
        />
        <Journey />
        <Quality />

        <section id="faq" className="mx-auto max-w-3xl px-5 py-16 md:py-24">
          <h2 className="text-center font-serif text-3xl font-semibold text-ink sm:text-4xl">
            Frequently asked
          </h2>
          <div className="mt-10 divide-y divide-line rounded-2xl bg-white ring-1 ring-line">
            {FAQS.map((f) => (
              <details key={f.q} className="group px-6 py-5">
                <summary className="flex cursor-pointer list-none items-center justify-between font-semibold text-ink">
                  {f.q}
                  <span className="ml-4 grid h-7 w-7 shrink-0 place-items-center rounded-full bg-brand-soft text-brand transition-transform group-open:rotate-45">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" aria-hidden="true">
                      <path d="M12 5v14M5 12h14" strokeLinecap="round" />
                    </svg>
                  </span>
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-ink/70">{f.a}</p>
              </details>
            ))}
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
