import { Logo } from "./Logo";

const COLS = [
  {
    title: "Shop",
    links: [
      { label: "Categories", href: "/categories" },
      { label: "Best Sellers", href: "/products" },
      { label: "Combo Packs", href: "/subscriptions#combos" },
      { label: "Subscriptions", href: "/subscriptions" },
      { label: "Get the App", href: "/#download" },
    ],
  },
  {
    title: "Company",
    links: [
      { label: "About Us", href: "/about" },
      { label: "Our Farmers", href: "/about" },
      { label: "Quality Promise", href: "/how-it-works" },
      { label: "How It Works", href: "/how-it-works" },
      { label: "Partner With Us", href: "/contact" },
    ],
  },
  {
    title: "Support",
    links: [
      { label: "Help Center", href: "/contact" },
      { label: "Track Order", href: "/#download" },
      { label: "Delivery Areas", href: "/contact" },
      { label: "Contact Us", href: "/contact" },
      { label: "FAQs", href: "/how-it-works#faq" },
    ],
  },
];

const SOCIALS = ["Instagram", "X", "LinkedIn", "Facebook"];

export function Footer() {
  return (
    <footer className="bg-espresso text-white/80">
      <div className="mx-auto max-w-7xl px-5 py-14">
        <div className="grid gap-10 md:grid-cols-[1.4fr_1fr_1fr_1fr]">
          <div>
            <Logo light />
            <p className="mt-4 max-w-xs text-sm leading-relaxed text-white/70">
              Farm-to-home groceries you can trust — sourced direct, quality-graded
              and delivered same day across Mumbai &amp; Navi Mumbai.
            </p>
            <div className="mt-5 flex gap-3">
              {SOCIALS.map((s) => (
                <a
                  key={s}
                  href="#"
                  aria-label={s}
                  className="grid h-9 w-9 place-items-center rounded-full bg-white/10 text-xs font-semibold transition-colors hover:bg-gold hover:text-espresso"
                >
                  {s[0]}
                </a>
              ))}
            </div>
          </div>

          {COLS.map((col) => (
            <div key={col.title}>
              <h4 className="text-sm font-semibold text-white">{col.title}</h4>
              <ul className="mt-4 space-y-2.5 text-sm">
                {col.links.map((l) => (
                  <li key={l.label}>
                    <a href={l.href} className="transition-colors hover:text-gold">
                      {l.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-12 flex flex-col items-start justify-between gap-3 border-t border-white/15 pt-6 text-xs text-white/55 sm:flex-row sm:items-center">
          <p>© 2026 FarmFresh Retail Pvt. Ltd. All rights reserved.</p>
          <div className="flex gap-5">
            <a href="/privacy" className="hover:text-gold">Privacy Policy</a>
            <a href="/terms" className="hover:text-gold">Terms of Service</a>
            <a href="/refunds" className="hover:text-gold">Refund Policy</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
