import Image from "next/image";
import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { PageHeader } from "@/components/PageHeader";

export const metadata: Metadata = {
  title: "About FarmFresh",
  description:
    "FarmFresh brings farm-to-home groceries to Mumbai & Navi Mumbai — sourced direct from partner farms, quality-graded, and fair to farmers.",
};

const VALUES = [
  { icon: "🌾", title: "Farm-direct", text: "We buy straight from partner farms — cutting middlemen so growers earn more and you pay less." },
  { icon: "🔍", title: "Radically transparent", text: "Every product is traceable to its source and graded on 200+ checks. No mystery supply chains." },
  { icon: "🤝", title: "Fair to farmers", text: "Honest prices and steady demand for the people who actually grow your food." },
  { icon: "🌱", title: "Freshness first", text: "Milled, packed and delivered fast — never left ageing in a warehouse." },
];

const STATS = [
  { n: "120+", l: "partner farms" },
  { n: "48h", l: "farm to door" },
  { n: "200+", l: "quality checks" },
  { n: "25k+", l: "happy households" },
];

export default function AboutPage() {
  return (
    <>
      <Header />
      <main>
        <PageHeader
          eyebrow="Our story"
          title="Groceries you don't have to second-guess"
          subtitle="FarmFresh started with a simple frustration — you can never quite trust where your everyday staples come from. So we built a shorter, more honest path from the farm to your home."
        />

        <section className="mx-auto max-w-7xl px-5 py-14 md:py-20">
          <div className="grid items-center gap-12 lg:grid-cols-2">
            <div className="relative aspect-[4/3] w-full overflow-hidden rounded-[28px] shadow-xl ring-1 ring-black/5">
              <Image
                src="/images/farm.jpg"
                alt="A farmer tending fresh produce in the field"
                fill
                sizes="(max-width: 1024px) 100vw, 50vw"
                className="object-cover"
              />
            </div>
            <div>
              <h2 className="font-serif text-3xl font-semibold text-ink">
                Real food, from real farms
              </h2>
              <p className="mt-4 text-ink/70">
                We work directly with growers across Maharashtra, Karnataka and Gujarat —
                buying at fair prices, grading rigorously, and delivering within hours.
                No aggregators, no ageing warehouse stock, no guesswork about what&rsquo;s
                actually in your basket.
              </p>
              <p className="mt-3 text-ink/70">
                Today we serve thousands of families across Mumbai &amp; Navi Mumbai — and
                we&rsquo;re just getting started.
              </p>
              <div className="mt-8 grid grid-cols-4 gap-4">
                {STATS.map((s) => (
                  <div key={s.l}>
                    <p className="font-serif text-2xl font-semibold text-brand">{s.n}</p>
                    <p className="mt-1 text-xs text-muted">{s.l}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        <section className="bg-beige">
          <div className="mx-auto max-w-7xl px-5 py-16 md:py-24">
            <div className="mx-auto max-w-2xl text-center">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
                What we stand for
              </p>
              <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
                Our promise, in four words
              </h2>
            </div>
            <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
              {VALUES.map((v) => (
                <div key={v.title} className="rounded-2xl bg-white p-6 ring-1 ring-line">
                  <div className="grid h-12 w-12 place-items-center rounded-full bg-sage-soft text-2xl">
                    {v.icon}
                  </div>
                  <h3 className="mt-4 font-semibold text-ink">{v.title}</h3>
                  <p className="mt-2 text-sm text-ink/65">{v.text}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="mx-auto max-w-7xl px-5 py-16">
          <div className="overflow-hidden rounded-[32px] bg-brand px-6 py-12 text-center text-white sm:px-12">
            <h2 className="font-serif text-3xl font-semibold sm:text-4xl">
              Taste the difference
            </h2>
            <p className="mx-auto mt-3 max-w-md text-white/80">
              Download the app and get farm-fresh groceries delivered to your door today.
            </p>
            <a
              href="/#download"
              className="mt-6 inline-block rounded-full bg-white px-6 py-3.5 text-sm font-semibold text-brand transition-colors hover:bg-beige"
            >
              Get the app
            </a>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
