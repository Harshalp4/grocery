import Image from "next/image";
import { productImage, type Product } from "@/lib/api";

function discount(p: Product): number | null {
  if (!p.marketPrice || p.marketPrice <= p.price) return null;
  return Math.round(((p.marketPrice - p.price) / p.marketPrice) * 100);
}

export function ProductGrid({ products }: { products: Product[] }) {
  return (
    <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
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
                sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                className="object-cover transition-transform duration-500 group-hover:scale-105"
              />
              {off !== null && (
                <span className="absolute left-2 top-2 rounded-full bg-gold-soft px-2 py-0.5 text-[11px] font-bold text-amber-ink">
                  {off}% OFF
                </span>
              )}
              <span className="absolute right-2 top-2 rounded-full bg-white/90 px-2 py-0.5 text-[10px] font-semibold text-sage-dark">
                {p.grade}
              </span>
            </div>
            <div className="flex flex-1 flex-col p-4">
              <p className="text-sm font-semibold leading-snug text-ink">{p.name}</p>
              <p className="mt-0.5 text-xs text-muted">
                {p.source}
                {p.packSize ? ` · ${p.packSize}` : ""}
              </p>
              <div className="mt-auto flex items-center justify-between pt-3">
                <div className="flex items-baseline gap-1.5">
                  <span className="font-semibold text-ink">₹{p.price}</span>
                  {off !== null && (
                    <span className="text-xs text-muted line-through">₹{p.marketPrice}</span>
                  )}
                </div>
                <a
                  href="/#download"
                  className="rounded-full bg-brand-soft px-3 py-1.5 text-xs font-semibold text-brand transition-colors hover:bg-brand hover:text-white"
                >
                  Add
                </a>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
