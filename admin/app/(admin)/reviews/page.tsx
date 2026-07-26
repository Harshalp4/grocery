'use client';

import { useEffect, useState } from 'react';
import { Button, Card, Empty, PageHeader, Table } from '@/components/ui';
import { reviews as api } from '@/lib/resources';
import type { Review } from '@/lib/types';

export default function ReviewsPage() {
  const [rows, setRows] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function onDelete(id: string) {
    if (!confirm('Delete this review?')) return;
    await api.remove(id);
    load();
  }

  return (
    <div>
      <PageHeader title="Reviews" subtitle={`${rows.length} reviews · moderation`} />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No reviews yet.</Empty>
        ) : (
          <Table head={['Product', 'Reviewer', 'Rating', 'Comment', '']}>
            {rows.map((r) => (
              <tr key={r.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{r.productName}</td>
                <td className="px-4 py-3 text-muted">
                  {r.author} · {r.area}
                </td>
                <td className="px-4 py-3 text-gold">
                  {'★'.repeat(r.rating)}
                  <span className="text-line">{'★'.repeat(5 - r.rating)}</span>
                </td>
                <td className="px-4 py-3 text-muted">{r.text}</td>
                <td className="px-4 py-3 text-right">
                  <Button
                    variant="danger"
                    className="px-3 py-1"
                    onClick={() => onDelete(r.id)}
                  >
                    Delete
                  </Button>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>
    </div>
  );
}
