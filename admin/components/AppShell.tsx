'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { ReactNode, useEffect, useState } from 'react';
import { auth } from '@/lib/api';

type Item = { href: string; label: string; icon: string };
type Section = { title?: string; items: Item[] };

const SECTIONS: Section[] = [
  { items: [{ href: '/', label: 'Dashboard', icon: '📊' }] },
  {
    title: 'Sales',
    items: [
      { href: '/orders', label: 'Orders', icon: '🧾' },
      { href: '/returns', label: 'Returns', icon: '↩️' },
      { href: '/customers', label: 'Customers', icon: '👥' },
      { href: '/support', label: 'Support', icon: '💬' },
    ],
  },
  {
    title: 'Catalog',
    items: [
      { href: '/products', label: 'Products', icon: '📦' },
      { href: '/categories', label: 'Categories', icon: '🏷️' },
      { href: '/combos', label: 'Combo Packs', icon: '🎁' },
      { href: '/inventory', label: 'Inventory', icon: '⚠️' },
      { href: '/reviews', label: 'Reviews', icon: '⭐' },
    ],
  },
  {
    title: 'Marketing',
    items: [
      { href: '/coupons', label: 'Coupons', icon: '🎟️' },
      { href: '/banners', label: 'Banners', icon: '🖼️' },
      { href: '/campaigns', label: 'Campaigns', icon: '📣' },
    ],
  },
  {
    title: 'Delivery',
    items: [
      { href: '/slots', label: 'Delivery Slots', icon: '🕑' },
      { href: '/areas', label: 'Serviceable Areas', icon: '📍' },
      { href: '/partners', label: 'Delivery Partners', icon: '🛵' },
    ],
  },
];

const FOOTER: Item = { href: '/admins', label: 'Admin Users', icon: '⚙️' };

const STORAGE_KEY = 'nav_collapsed';

export default function AppShell({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [ready, setReady] = useState(false);
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({});

  useEffect(() => {
    if (!auth.isAuthed) {
      router.replace('/login');
      return;
    }
    try {
      setCollapsed(JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}'));
    } catch {
      /* ignore */
    }
    setReady(true);
  }, [router]);

  const isActive = (href: string) =>
    href === '/' ? pathname === '/' : pathname.startsWith(href);

  function toggle(title: string) {
    setCollapsed((prev) => {
      const next = { ...prev, [title]: !prev[title] };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
      return next;
    });
  }

  // A section shows expanded if the user hasn't collapsed it, OR it contains the
  // active route (so you always see where you are).
  const sectionOpen = (s: Section) =>
    !s.title ||
    s.items.some((i) => isActive(i.href)) ||
    !collapsed[s.title];

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center text-muted">
        Loading…
      </div>
    );
  }

  const NavLink = ({ item }: { item: Item }) => {
    const active = isActive(item.href);
    return (
      <Link
        href={item.href}
        className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition ${
          active
            ? 'bg-white/15 text-white'
            : 'text-white/70 hover:bg-white/10 hover:text-white'
        }`}
      >
        <span className="w-5 shrink-0 text-center text-[15px] leading-none">
          {item.icon}
        </span>
        <span className="truncate">{item.label}</span>
      </Link>
    );
  };

  return (
    <div className="flex min-h-screen">
      {/* Sidebar */}
      <aside className="hidden w-60 shrink-0 flex-col bg-brand-dark px-3 py-6 text-white md:flex">
        <div className="mb-6 flex items-center gap-2 px-2">
          <Logo />
          <div className="leading-tight">
            <div className="text-base font-extrabold">Green Epicure</div>
            <div className="text-[10px] uppercase tracking-widest text-white/60">
              Admin
            </div>
          </div>
        </div>

        <nav className="flex flex-1 flex-col gap-1 overflow-y-auto">
          {SECTIONS.map((section, i) => {
            if (!section.title) {
              return (
                <div key={i} className="mb-1">
                  {section.items.map((item) => (
                    <NavLink key={item.href} item={item} />
                  ))}
                </div>
              );
            }
            const open = sectionOpen(section);
            return (
              <div key={section.title} className="mt-2">
                <button
                  onClick={() => toggle(section.title!)}
                  className="flex w-full items-center justify-between rounded-lg px-3 py-1.5 text-[10px] font-bold uppercase tracking-widest text-white/40 transition hover:text-white/70"
                >
                  <span>{section.title}</span>
                  <Chevron open={open} />
                </button>
                {open && (
                  <div className="mt-0.5 space-y-0.5">
                    {section.items.map((item) => (
                      <NavLink key={item.href} item={item} />
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </nav>

        <div className="mt-4 border-t border-white/10 pt-3">
          <NavLink item={FOOTER} />
          <button
            onClick={() => {
              auth.clear();
              router.replace('/login');
            }}
            className="mt-1 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium text-white/70 hover:bg-white/10 hover:text-white"
          >
            <span className="w-5 shrink-0 text-center text-[15px] leading-none">⎋</span>
            <span>Log out</span>
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center gap-2 bg-brand-dark px-4 py-3 text-white md:hidden">
          <Logo />
          <span className="font-bold">Green Epicure Admin</span>
        </header>
        <main className="mx-auto w-full max-w-5xl flex-1 p-5 md:p-8">
          {children}
        </main>
      </div>
    </div>
  );
}

function Chevron({ open }: { open: boolean }) {
  return (
    <svg
      width="12"
      height="12"
      viewBox="0 0 24 24"
      fill="none"
      className={`transition-transform ${open ? 'rotate-90' : ''}`}
    >
      <path
        d="M9 6l6 6-6 6"
        stroke="currentColor"
        strokeWidth="2.4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function Logo() {
  return (
    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-white/15">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
        <path
          d="M12 21c0-6 0-9 5-12-0.5 6-2.5 9-5 12Zm0 0c0-6 0-9-5-12 0.5 6 2.5 9 5 12Z"
          fill="#e8c779"
        />
        <path d="M12 21v-6" stroke="#c9a24b" strokeWidth="1.6" strokeLinecap="round" />
      </svg>
    </div>
  );
}
