'use client';

import { useEffect, useState } from 'react';
import { Card, Empty, PageHeader } from '@/components/ui';
import { stats as statsApi } from '@/lib/resources';
import type { Stats } from '@/lib/types';

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    statsApi
      .get()
      .then(setStats)
      .catch((e) => setError(e.message));
  }, []);

  if (error) return <Empty>Could not load stats: {error}</Empty>;
  if (!stats) return <Empty>Loading dashboard…</Empty>;

  const tiles = [
    { label: 'Orders', value: stats.counts.orders },
    { label: 'Revenue', value: `₹${stats.revenue.toLocaleString('en-IN')}` },
    { label: 'Products', value: stats.counts.products },
    { label: 'Combo Packs', value: stats.counts.combos },
    { label: 'Subscriptions', value: stats.counts.subscriptions },
    { label: 'Categories', value: stats.counts.categories },
    { label: 'Reviews', value: stats.counts.reviews },
  ];
  const maxCat = Math.max(1, ...stats.byCategory.map((c) => c.count));

  return (
    <div>
      <PageHeader title="Dashboard" subtitle="Overview of your FarmFresh catalog" />

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        {tiles.map((t) => (
          <Card key={t.label} className="p-4">
            <div className="text-3xl font-extrabold text-brand">{t.value}</div>
            <div className="mt-1 text-xs font-semibold uppercase tracking-wide text-muted">
              {t.label}
            </div>
          </Card>
        ))}
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-2">
        <Card className="p-5">
          <h3 className="mb-4 text-sm font-bold text-ink">Products by category</h3>
          <div className="space-y-2">
            {stats.byCategory.map((c) => (
              <div key={c.categorySlug} className="flex items-center gap-3">
                <div className="w-28 shrink-0 truncate text-xs text-muted">
                  {c.categorySlug}
                </div>
                <div className="h-3 flex-1 rounded-full bg-brand-soft">
                  <div
                    className="h-3 rounded-full bg-brand"
                    style={{ width: `${(c.count / maxCat) * 100}%` }}
                  />
                </div>
                <div className="w-6 text-right text-xs font-semibold">{c.count}</div>
              </div>
            ))}
          </div>
        </Card>

        <Card className="p-5">
          <h3 className="mb-4 text-sm font-bold text-ink">Pricing (₹)</h3>
          <div className="grid grid-cols-3 gap-3 text-center">
            {[
              { label: 'Lowest', value: stats.price.min },
              { label: 'Average', value: stats.price.avg },
              { label: 'Highest', value: stats.price.max },
            ].map((p) => (
              <div key={p.label} className="rounded-xl bg-beige p-4">
                <div className="text-xl font-extrabold text-brand">
                  ₹{p.value.toLocaleString('en-IN')}
                </div>
                <div className="mt-1 text-[11px] uppercase tracking-wide text-muted">
                  {p.label}
                </div>
              </div>
            ))}
          </div>
          <h3 className="mb-2 mt-5 text-sm font-bold text-ink">By grade</h3>
          <div className="flex flex-wrap gap-2">
            {stats.byGrade.map((g) => (
              <span
                key={g.grade}
                className="rounded-full bg-gold-soft px-3 py-1 text-xs font-semibold text-[#8a6a16]"
              >
                {g.grade}: {g.count}
              </span>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
