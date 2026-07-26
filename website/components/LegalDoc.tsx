import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { PageHeader } from "@/components/PageHeader";

export type LegalSection = {
  id: string;
  heading: string;
  body: (string | { list: string[] })[];
};

export function LegalDoc({
  eyebrow,
  title,
  updated,
  intro,
  sections,
}: {
  eyebrow: string;
  title: string;
  updated: string;
  intro: string;
  sections: LegalSection[];
}) {
  return (
    <>
      <Header />
      <main>
        <PageHeader eyebrow={eyebrow} title={title} subtitle={intro} />

        <section className="mx-auto max-w-7xl px-5 py-14 md:py-20">
          <div className="grid gap-10 lg:grid-cols-[220px_1fr]">
            {/* Table of contents */}
            <aside className="hidden lg:block">
              <div className="sticky top-24">
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-muted">
                  On this page
                </p>
                <nav className="mt-3 space-y-1.5">
                  {sections.map((s, i) => (
                    <a
                      key={s.id}
                      href={`#${s.id}`}
                      className="block text-sm text-ink/65 transition-colors hover:text-brand"
                    >
                      {i + 1}. {s.heading}
                    </a>
                  ))}
                </nav>
              </div>
            </aside>

            {/* Body */}
            <div className="max-w-3xl">
              <p className="mb-8 text-sm text-muted">Last updated: {updated}</p>

              <div className="mb-10 flex gap-3 rounded-2xl bg-gold-soft px-5 py-4 ring-1 ring-gold/30">
                <span className="text-lg" aria-hidden="true">
                  ⚖️
                </span>
                <p className="text-sm leading-relaxed text-amber-ink">
                  This document is a template provided for information only and does not
                  constitute legal advice. Please have it reviewed by a qualified legal
                  professional and adapt the company details before publishing.
                </p>
              </div>

              <div className="space-y-10">
                {sections.map((s, i) => (
                  <section key={s.id} id={s.id} className="scroll-mt-24">
                    <h2 className="font-serif text-2xl font-semibold text-ink">
                      {i + 1}. {s.heading}
                    </h2>
                    <div className="mt-3 space-y-3">
                      {s.body.map((b, j) =>
                        typeof b === "string" ? (
                          <p key={j} className="text-sm leading-relaxed text-ink/75">
                            {b}
                          </p>
                        ) : (
                          <ul key={j} className="space-y-2">
                            {b.list.map((item, k) => (
                              <li
                                key={k}
                                className="flex gap-2.5 text-sm leading-relaxed text-ink/75"
                              >
                                <span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-sage" />
                                {item}
                              </li>
                            ))}
                          </ul>
                        ),
                      )}
                    </div>
                  </section>
                ))}
              </div>

              <div className="mt-12 rounded-2xl bg-beige px-6 py-6 ring-1 ring-line">
                <p className="text-sm font-semibold text-ink">Questions about this policy?</p>
                <p className="mt-1 text-sm text-ink/70">
                  Email us at{" "}
                  <a href="/contact" className="font-semibold text-brand hover:text-brand-dark">
                    hello@farmfresh.example
                  </a>{" "}
                  or reach out via our{" "}
                  <a href="/contact" className="font-semibold text-brand hover:text-brand-dark">
                    contact page
                  </a>
                  .
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
