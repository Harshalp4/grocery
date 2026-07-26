import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { PageHeader } from "@/components/PageHeader";
import { ProductGrid } from "@/components/ProductGrid";
import { getAllProducts } from "@/lib/api";

export const metadata: Metadata = {
  title: "Best Sellers & Products — FarmFresh",
  description:
    "Shop farm-fresh, quality-graded staples — rice, dals, flours, cold-pressed oils, paneer, honey and more, delivered across Mumbai & Navi Mumbai.",
};

export default async function ProductsPage() {
  const products = await getAllProducts();

  return (
    <>
      <Header />
      <main>
        <PageHeader
          eyebrow="Best sellers"
          title="Freshly packed, premium grade"
          subtitle="Farm-sourced staples our customers reorder every month — traceable, quality-graded, and honestly priced."
        />
        <section className="mx-auto max-w-7xl px-5 py-14 md:py-20">
          <ProductGrid products={products} />

          <p className="mt-10 text-center text-sm text-muted">
            Prices and availability are live in the FarmFresh app.{" "}
            <a href="/#download" className="font-semibold text-brand hover:text-brand-dark">
              Download to shop the full range →
            </a>
          </p>
        </section>
      </main>
      <Footer />
    </>
  );
}
