'use client';

import { useEffect, useState } from 'react';
import {
  Badge,
  Button,
  Card,
  Empty,
  Modal,
  PageHeader,
  Table,
} from '@/components/ui';
import { customers as api } from '@/lib/resources';
import type { Customer, CustomerDetail } from '@/lib/types';

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

export default function CustomersPage() {
  const [rows, setRows] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [detail, setDetail] = useState<CustomerDetail | null>(null);
  const [loadingId, setLoadingId] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function view(id: string) {
    setLoadingId(id);
    try {
      setDetail(await api.get(id));
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setLoadingId(null);
    }
  }

  return (
    <div>
      <PageHeader title="Customers" subtitle={`${rows.length} customers`} />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No customers yet.</Empty>
        ) : (
          <Table head={['Name', 'Phone', 'Orders', 'Spend', 'Joined', '']}>
            {rows.map((c) => (
              <tr key={c.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">
                  {c.name || '—'}
                </td>
                <td className="px-4 py-3 text-muted">{c.phone}</td>
                <td className="px-4 py-3 text-ink">{c.orderCount}</td>
                <td className="px-4 py-3 font-semibold text-brand">
                  ₹{c.totalSpend.toLocaleString('en-IN')}
                </td>
                <td className="px-4 py-3 text-muted">{fmtDate(c.createdAt)}</td>
                <td className="px-4 py-3 text-right">
                  <Button
                    variant="outline"
                    className="px-3 py-1"
                    disabled={loadingId === c.id}
                    onClick={() => view(c.id)}
                  >
                    {loadingId === c.id ? 'Loading…' : 'View'}
                  </Button>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>

      {detail && (
        <Modal
          open
          title={detail.name || detail.phone}
          onClose={() => setDetail(null)}
        >
          <div className="space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-3">
              <Info label="Phone" value={detail.phone} />
              <Info label="Joined" value={fmtDate(detail.createdAt)} />
            </div>

            <div>
              <div className="mb-1 text-xs font-semibold text-muted">
                Addresses ({detail.addresses.length})
              </div>
              {detail.addresses.length === 0 ? (
                <div className="rounded-xl border border-line px-3 py-2 text-muted">
                  No saved addresses.
                </div>
              ) : (
                <div className="rounded-xl border border-line">
                  {detail.addresses.map((a) => (
                    <div
                      key={a.id}
                      className="border-b border-line px-3 py-2 last:border-0"
                    >
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-ink">{a.label}</span>
                        {a.isDefault && <Badge tone="gold">Default</Badge>}
                      </div>
                      <div className="text-muted">
                        {a.line}, {a.area}, {a.city} — {a.pincode}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div>
              <div className="mb-1 text-xs font-semibold text-muted">
                Orders ({detail.orders.length})
              </div>
              {detail.orders.length === 0 ? (
                <div className="rounded-xl border border-line px-3 py-2 text-muted">
                  No orders yet.
                </div>
              ) : (
                <div className="rounded-xl border border-line">
                  {detail.orders.map((o) => (
                    <div
                      key={o.id}
                      className="flex items-center justify-between border-b border-line px-3 py-2 last:border-0"
                    >
                      <div>
                        <div className="font-semibold text-ink">{o.code}</div>
                        <div className="text-xs text-muted">
                          {fmtDate(o.createdAt)} · {o.status}
                        </div>
                      </div>
                      <span className="font-semibold text-brand">
                        ₹{o.total.toLocaleString('en-IN')}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-xs font-semibold text-muted">{label}</div>
      <div className="text-ink">{value}</div>
    </div>
  );
}
