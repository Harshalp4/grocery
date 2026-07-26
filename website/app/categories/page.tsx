import Image from "next/image";
import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { PageHeader } from "@/components/PageHeader";
import { categoryImage, getCategories } from "@/lib/api";

export const metadata: Metadata = {
  title: "Shop by Category — FarmFresh",
  description:
    "Browse FarmFresh categories — rice, dals, flours, oils & ghee, spices, millets, tea & coffee and more, all farm-sourced and quality-graded.",
};

export default async function CategoriesPage() {
  const categories = await getCategories();

  return (
    <>
      <Header />
      <main>
        <PageHeader
          eyebrow="Shop by category"
          title="Everything your kitchen runs on"
          subtitle="From daily staples to farm-fresh specials — every category hand-picked, quality-graded and delivered across Mumbai & Navi Mumbai."
        />

        <section className="mx-auto max-w-7xl px-5 py-14 md:py-20">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {categories.map((c) => (
              <a
                key={c.id}
                href="/products"
                className="group relative overflow-hidden rounded-2xl bg-beige ring-1 ring-line transition-all hover:-translate-y-1 hover:shadow-lg"
              >
                <div className="relative aspect-[4/3] w-full overflow-hidden">
                  <Image
                    src={categoryImage(c.slug)}
                    alt={c.name}
                    fill
                    sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                    className="object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/45 to-transparent" />
                  <span className="absolute left-3 top-3 grid h-9 w-9 place-items-center rounded-full bg-white/90 text-lg shadow-sm">
                    {c.emoji}
                  </span>
                </div>
                <div className="flex items-center justify-between px-4 py-3.5">
                  <span className="font-semibold text-ink">{c.name}</span>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-muted transition-all group-hover:translate-x-0.5 group-hover:text-brand" aria-hidden="true">
                    <path d="M5 12h14M13 6l6 6-6 6" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
              </a>
            ))}
          </div>

          <div className="mt-12 rounded-3xl bg-brand-soft px-6 py-10 text-center ring-1 ring-brand/15">
            <h2 className="font-serif text-2xl font-semibold text-ink">
              Can&rsquo;t find what you need?
            </h2>
            <p className="mx-auto mt-2 max-w-md text-sm text-ink/70">
              The full FarmFresh catalogue lives in the app — with hundreds of SKUs,
              live prices and same-day delivery.
            </p>
            <a
              href="/#download"
              className="mt-5 inline-block rounded-full bg-brand px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-brand-dark"
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
