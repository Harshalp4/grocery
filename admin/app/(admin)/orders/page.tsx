'use client';

import { useEffect, useState } from 'react';
import { Badge, Button, Card, Empty, Modal, PageHeader, Table } from '@/components/ui';
import { orders as api, partners as partnersApi } from '@/lib/resources';
import type { Order, OrderStatus, Partner } from '@/lib/types';

const STATUSES: OrderStatus[] = [
  'placed',
  'confirmed',
  'packed',
  'out_for_delivery',
  'delivered',
  'cancelled',
];

const STATUS_LABEL: Record<OrderStatus, string> = {
  placed: 'Placed',
  confirmed: 'Confirmed',
  packed: 'Packed',
  out_for_delivery: 'Out for delivery',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
};

function payTone(status: string): 'green' | 'gold' | 'gray' {
  if (status === 'paid') return 'green';
  if (status === 'failed') return 'gray';
  return 'gold';
}

export default function OrdersPage() {
  const [rows, setRows] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewing, setViewing] = useState<Order | null>(null);
  const [partners, setPartners] = useState<Partner[]>([]);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
    partnersApi.list().then(setPartners).catch(() => {});
  }, []);

  async function changeStatus(id: string, status: OrderStatus) {
    const updated = await api.setStatus(id, status);
    setRows((rs) => rs.map((r) => (r.id === id ? updated : r)));
    setViewing((v) => (v && v.id === id ? updated : v));
  }

  async function assignPartner(id: string, partnerId: string | null) {
    const updated = await api.assign(id, partnerId);
    setRows((rs) => rs.map((r) => (r.id === id ? updated : r)));
    setViewing((v) => (v && v.id === id ? updated : v));
  }

  const revenue = rows
    .filter((o) => o.status !== 'cancelled')
    .reduce((s, o) => s + o.total, 0);

  return (
    <div>
      <PageHeader
        title="Orders"
        subtitle={`${rows.length} orders · ₹${revenue.toLocaleString('en-IN')} value`}
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No orders yet. Place one from the app to see it here.</Empty>
        ) : (
          <Table head={['Order', 'Customer', 'Total', 'Payment', 'Status', '']}>
            {rows.map((o) => (
              <tr key={o.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3">
                  <div className="font-semibold text-ink">{o.code}</div>
                  <div className="text-xs text-muted">{o.slot}</div>
                </td>
                <td className="px-4 py-3">
                  <div className="text-ink">{o.customerName}</div>
                  <div className="text-xs text-muted">{o.phone}</div>
                </td>
                <td className="px-4 py-3 font-bold text-brand">
                  ₹{o.total.toLocaleString('en-IN')}
                </td>
                <td className="px-4 py-3">
                  <div className="text-xs uppercase text-muted">{o.paymentMethod}</div>
                  <Badge tone={payTone(o.paymentStatus)}>{o.paymentStatus}</Badge>
                </td>
                <td className="px-4 py-3">
                  <select
                    value={o.status}
                    onChange={(e) =>
                      changeStatus(o.id, e.target.value as OrderStatus)
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
                <td className="px-4 py-3 text-right">
                  <Button
                    variant="outline"
                    className="px-3 py-1"
                    onClick={() => setViewing(o)}
                  >
                    View
                  </Button>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>

      {viewing && (
        <Modal open title={`Order ${viewing.code}`} onClose={() => setViewing(null)}>
          <div className="space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-3">
              <Info label="Customer" value={viewing.customerName} />
              <Info label="Phone" value={viewing.phone} />
              <Info label="Slot" value={viewing.slot} />
              <Info
                label="Payment"
                value={`${viewing.paymentMethod.toUpperCase()} · ${viewing.paymentStatus}`}
              />
            </div>
            <Info label="Address" value={viewing.address} />

            {viewing.returnRequest && (
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold text-muted">Return:</span>
                <Badge tone="gold">{viewing.returnRequest.status}</Badge>
              </div>
            )}

            <div>
              <div className="mb-1 text-xs font-semibold text-muted">Items</div>
              <div className="rounded-xl border border-line">
                {viewing.items.map((it) => (
                  <div
                    key={it.id}
                    className="flex justify-between border-b border-line px-3 py-2 last:border-0"
                  >
                    <span>
                      {it.name} · {it.quantity}
                    </span>
                    <span className="font-semibold text-brand">{it.priceLabel}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-xl bg-beige p-3">
              <Row label="Item total" value={`₹${viewing.itemTotal}`} />
              <Row label="Savings" value={`– ₹${viewing.savings}`} />
              <Row
                label="Delivery"
                value={viewing.deliveryFee === 0 ? 'Free' : `₹${viewing.deliveryFee}`}
              />
              <div className="mt-1 flex justify-between border-t border-line pt-2 font-bold">
                <span>Total</span>
                <span className="text-brand">₹{viewing.total}</span>
              </div>
            </div>

            <div>
              <div className="mb-1 text-xs font-semibold text-muted">Update status</div>
              <select
                value={viewing.status}
                onChange={(e) =>
                  changeStatus(viewing.id, e.target.value as OrderStatus)
                }
                className="w-full rounded-lg border border-line bg-white px-3 py-2 text-sm outline-none focus:border-brand"
              >
                {STATUSES.map((s) => (
                  <option key={s} value={s}>
                    {STATUS_LABEL[s]}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <div className="mb-1 text-xs font-semibold text-muted">
                Delivery partner
              </div>
              <select
                value={viewing.deliveryPartner?.id ?? ''}
                onChange={(e) =>
                  assignPartner(viewing.id, e.target.value || null)
                }
                className="w-full rounded-lg border border-line bg-white px-3 py-2 text-sm outline-none focus:border-brand"
              >
                <option value="">Unassigned</option>
                {partners.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name} · {p.phone}
                  </option>
                ))}
              </select>
            </div>

            {viewing.events && viewing.events.length > 0 && (
              <div>
                <div className="mb-1 text-xs font-semibold text-muted">
                  Timeline
                </div>
                <div className="space-y-2 rounded-xl border border-line p-3">
                  {viewing.events.map((ev) => (
                    <div key={ev.id} className="flex gap-3">
                      <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-brand" />
                      <div>
                        <div className="font-semibold text-ink">
                          {STATUS_LABEL[ev.status as OrderStatus] ?? ev.status}
                        </div>
                        {ev.note && (
                          <div className="text-xs text-muted">{ev.note}</div>
                        )}
                        <div className="text-[11px] text-muted">
                          {new Date(ev.createdAt).toLocaleString('en-IN')}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
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

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between py-0.5">
      <span className="text-muted">{label}</span>
      <span>{value}</span>
    </div>
  );
}
