'use client';

import { useCallback, useEffect, useState } from 'react';
import { Badge, Card, Empty, Field, PageHeader, Select, Table } from '@/components/ui';
import { inventory } from '@/lib/resources';
import type { LowStockItem } from '@/lib/types';

export default function InventoryPage() {
  const [rows, setRows] = useState<LowStockItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [threshold, setThreshold] = useState(5);

  const load = useCallback(async () => {
    setLoading(true);
    setRows(await inventory.lowStock(threshold));
    setLoading(false);
  }, [threshold]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div>
      <PageHeader
        title="Low Stock"
        subtitle="Products and pack sizes at or below the threshold"
        action={
          <div className="w-40">
            <Field label="Threshold">
              <Select
                value={threshold}
                onChange={(e) => setThreshold(Number(e.target.value))}
              >
                <option value={3}>3 or fewer</option>
                <option value={5}>5 or fewer</option>
                <option value={10}>10 or fewer</option>
                <option value={20}>20 or fewer</option>
              </Select>
            </Field>
          </div>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>Nothing low on stock. 🎉</Empty>
        ) : (
          <Table head={['Product', 'Pack', 'Stock']}>
            {rows.map((r, i) => (
              <tr key={i} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{r.product}</td>
                <td className="px-4 py-3 text-muted">{r.variant ?? '—'}</td>
                <td className="px-4 py-3">
                  <Badge tone={r.stock === 0 ? 'gray' : 'gold'}>
                    {r.stock === 0 ? 'Out of stock' : `${r.stock} left`}
                  </Badge>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>
    </div>
  );
}
