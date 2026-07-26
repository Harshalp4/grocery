'use client';

import { useEffect, useState } from 'react';
import { Badge, Card, Empty, PageHeader, Table } from '@/components/ui';
import { returns as api } from '@/lib/resources';
import type { ReturnRequest, ReturnStatus } from '@/lib/types';

const STATUSES: ReturnStatus[] = [
  'requested',
  'approved',
  'rejected',
  'refunded',
];

const STATUS_LABEL: Record<ReturnStatus, string> = {
  requested: 'Requested',
  approved: 'Approved',
  rejected: 'Rejected',
  refunded: 'Refunded',
};

function statusTone(status: ReturnStatus): 'green' | 'gold' | 'gray' {
  if (status === 'approved' || status === 'refunded') return 'green';
  if (status === 'rejected') return 'gray';
  return 'gold';
}

export default function ReturnsPage() {
  const [rows, setRows] = useState<ReturnRequest[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function changeStatus(id: string, status: ReturnStatus) {
    const updated = await api.setStatus(id, status);
    setRows((rs) => rs.map((r) => (r.id === id ? updated : r)));
  }

  return (
    <div>
      <PageHeader title="Returns" subtitle={`${rows.length} requests`} />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No return requests yet.</Empty>
        ) : (
          <Table head={['Order', 'Customer', 'Reason', 'Status', 'Update']}>
            {rows.map((r) => (
              <tr key={r.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3">
                  <div className="font-semibold text-ink">{r.order.code}</div>
                  <div className="text-xs text-muted">
                    ₹{r.order.total.toLocaleString('en-IN')}
                  </div>
                </td>
                <td className="px-4 py-3 text-ink">{r.order.customerName}</td>
                <td className="px-4 py-3 text-muted">{r.reason}</td>
                <td className="px-4 py-3">
                  <Badge tone={statusTone(r.status)}>
                    {STATUS_LABEL[r.status]}
                  </Badge>
                </td>
                <td className="px-4 py-3">
                  <select
                    value={r.status}
                    onChange={(e) =>
                      changeStatus(r.id, e.target.value as ReturnStatus)
                    }
                    className="rounded-lg border border-line bg-white px-2 py-1 text-xs font-semibold outline-none focus:border-brand"
                  >
                    {STATUSES.map((s) => (
                      <option key={s} value={s}>
                        {STATUS_LABEL[s]}
                      </option>
                    ))}
                  </select>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>
    </div>
  );
}
