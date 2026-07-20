export function PageHeader({
  eyebrow,
  title,
  subtitle,
}: {
  eyebrow: string;
  title: string;
  subtitle?: string;
}) {
  return (
    <section className="border-b border-line bg-beige">
      <div className="mx-auto max-w-7xl px-5 py-14 md:py-20">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-brand">
          {eyebrow}
        </p>
        <h1 className="mt-3 max-w-3xl font-serif text-4xl font-semibold leading-[1.1] tracking-tight text-ink sm:text-5xl">
          {title}
        </h1>
        {subtitle && (
          <p className="mt-4 max-w-2xl text-base leading-relaxed text-ink/70 sm:text-lg">
            {subtitle}
          </p>
        )}
      </div>
    </section>
  );
}
