import Image from "next/image";
import { categoryImage, type Category } from "@/lib/api";

export function Categories({ categories }: { categories: Category[] }) {
  return (
    <section id="categories" className="mx-auto max-w-7xl px-5 py-16 md:py-24">
      <div className="mx-auto max-w-2xl text-center">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
          Shop by category
        </p>
        <h2 className="mt-3 font-serif text-3xl font-semibold text-ink sm:text-4xl">
          Everything your kitchen runs on
        </h2>
        <p className="mt-3 text-ink/65">
          From daily staples to farm-fresh specials — hand-picked and quality-graded.
        </p>
      </div>

      <div className="mt-12 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
        {categories.map((c) => (
          <a
            key={c.id}
            href="#download"
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
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                className="text-muted transition-all group-hover:translate-x-0.5 group-hover:text-brand"
                aria-hidden="true"
              >
                <path d="M5 12h14M13 6l6 6-6 6" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </a>
        ))}
      </div>
    </section>
  );
}
