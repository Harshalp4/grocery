'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { ReactNode, useEffect, useState } from 'react';
import { auth } from '@/lib/api';

const NAV = [
  { href: '/', label: 'Dashboard' },
  { href: '/orders', label: 'Orders' },
  { href: '/customers', label: 'Customers' },
  { href: '/products', label: 'Products' },
  { href: '/categories', label: 'Categories' },
  { href: '/combos', label: 'Combo Packs' },
  { href: '/subscriptions', label: 'Subscriptions' },
  { href: '/reviews', label: 'Reviews' },
  { href: '/slots', label: 'Delivery Slots' },
  { href: '/areas', label: 'Serviceable Areas' },
  { href: '/partners', label: 'Delivery Partners' },
  { href: '/returns', label: 'Returns' },
];

export default function AppShell({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!auth.isAuthed) {
      router.replace('/login');
    } else {
      setReady(true);
    }
  }, [router]);

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center text-muted">
        Loading…
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      {/* Sidebar */}
      <aside className="hidden w-60 shrink-0 flex-col bg-brand-dark px-4 py-6 text-white md:flex">
        <div className="mb-8 flex items-center gap-2 px-2">
          <Logo />
          <div className="leading-tight">
            <div className="text-base font-extrabold">FarmFresh</div>
            <div className="text-[10px] uppercase tracking-widest text-white/60">
              Admin
            </div>
          </div>
        </div>
        <nav className="flex flex-1 flex-col gap-1">
          {NAV.map((item) => {
            const active =
              item.href === '/'
                ? pathname === '/'
                : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`rounded-lg px-3 py-2 text-sm font-medium transition ${
                  active
                    ? 'bg-white/15 text-white'
                    : 'text-white/70 hover:bg-white/10 hover:text-white'
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
        <button
          onClick={() => {
            auth.clear();
            router.replace('/login');
          }}
          className="mt-4 rounded-lg px-3 py-2 text-left text-sm font-medium text-white/70 hover:bg-white/10 hover:text-white"
        >
          Log out
        </button>
      </aside>

      {/* Main */}
      <div className="flex min-w-0 flex-1 flex-col">
        {/* Mobile top bar */}
        <header className="flex items-center gap-2 bg-brand-dark px-4 py-3 text-white md:hidden">
          <Logo />
          <span className="font-bold">FarmFresh Admin</span>
        </header>
        <main className="mx-auto w-full max-w-5xl flex-1 p-5 md:p-8">
          {children}
        </main>
      </div>
    </div>
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
