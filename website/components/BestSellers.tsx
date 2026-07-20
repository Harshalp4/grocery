import Image from "next/image";
import { productImage, type Product } from "@/lib/api";

function discount(p: Product): number | null {
  if (!p.marketPrice || p.marketPrice <= p.price) return null;
  return Math.round(((p.marketPrice - p.price) / p.marketPrice) * 100);
}

export function BestSellers({ products }: { products: Product[] }) {
  return (
    <section className="bg-beige">
      <div className="mx-auto max-w-7xl px-5 py-16 md:py-24">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
              Best sellers
            </p>
            <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
              Freshly packed, premium grade
            </h2>
          </div>
          <a
            href="#download"
            className="hidden rounded-full border border-ink/15 bg-white px-5 py-2.5 text-sm font-semibold text-ink transition-colors hover:border-brand hover:text-brand sm:inline-block"
          >
            View all in app →
          </a>
        </div>

        <div className="mt-10 grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-6">
          {products.map((p) => {
            const off = discount(p);
            return (
              <div
                key={p.id}
                className="group flex flex-col overflow-hidden rounded-2xl bg-white ring-1 ring-line transition-all hover:-translate-y-1 hover:shadow-lg"
              >
                <div className="relative aspect-square w-full overflow-hidden">
                  <Image
                    src={productImage(p)}
                    alt={p.name}
                    fill
                    sizes="(max-width: 768px) 50vw, 16vw"
                    className="object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  {off !== null && (
                    <span className="absolute left-2 top-2 rounded-full bg-gold-soft px-2 py-0.5 text-[11px] font-bold text-amber-ink">
                      {off}% OFF
                    </span>
                  )}
                </div>
                <div className="flex flex-1 flex-col p-3">
                  <p className="line-clamp-2 text-sm font-semibold leading-snug text-ink">
                    {p.name}
                  </p>
                  <p className="mt-0.5 text-xs text-muted">{p.packSize ?? p.grade}</p>
                  <div className="mt-auto flex items-baseline gap-1.5 pt-2">
                    <span className="font-semibold text-ink">₹{p.price}</span>
                    {off !== null && (
                      <span className="text-xs text-muted line-through">₹{p.marketPrice}</span>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
