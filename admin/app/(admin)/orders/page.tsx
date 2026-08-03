'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { Badge, Button, Card, Empty, Modal, PageHeader, Table } from '@/components/ui';
import { orders as api, partners as partnersApi } from '@/lib/resources';
import type { Order, OrderStatus, Partner } from '@/lib/types';

const STATUSES: OrderStatus[] = [
  'placed',
  'confirmed',
  'packed',
  'picked_up',
  'out_for_delivery',
  'delivered',
  'failed',
  'cancelled',
];

const STATUS_LABEL: Record<OrderStatus, string> = {
  placed: 'Placed',
  confirmed: 'Confirmed',
  packed: 'Packed',
  picked_up: 'Picked up',
  out_for_delivery: 'Out for delivery',
  delivered: 'Delivered',
  failed: 'Delivery failed',
  cancelled: 'Cancelled',
};

// How often to check the API for new orders while the panel is open.
const POLL_MS = 15000;

function payTone(status: string): 'green' | 'gold' | 'gray' {
  if (status === 'paid') return 'green';
  if (status === 'failed') return 'gray';
  return 'gold';
}

// A single shared AudioContext, unlocked on the first user gesture — browsers
// block audio until the user has interacted with the page. Reused per chime;
// a fresh context per beep would stay suspended and never play.
let _audioCtx: AudioContext | null = null;

function ensureAudio(): AudioContext | null {
  if (typeof window === 'undefined') return null;
  try {
    if (!_audioCtx) {
      const Ctx =
        window.AudioContext ||
        (window as unknown as { webkitAudioContext: typeof AudioContext })
          .webkitAudioContext;
      if (!Ctx) return null;
      _audioCtx = new Ctx();
    }
    if (_audioCtx.state === 'suspended') void _audioCtx.resume();
    return _audioCtx;
  } catch {
    return null;
  }
}

/// A short two-tone chime via the Web Audio API — no asset to bundle.
function playChime() {
  const ctx = ensureAudio();
  if (!ctx || ctx.state !== 'running') return; // still locked — banner covers it
  try {
    const notes = [880, 1174.66]; // A5 → D6
    notes.forEach((freq, i) => {
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.connect(g);
      g.connect(ctx.destination);
      o.type = 'sine';
      o.frequency.value = freq;
      const t = ctx.currentTime + i * 0.16;
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(0.28, t + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, t + 0.32);
      o.start(t);
      o.stop(t + 0.34);
    });
  } catch {
    /* ignore */
  }
}

export default function OrdersPage() {
  const [rows, setRows] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewing, setViewing] = useState<Order | null>(null);
  const [partners, setPartners] = useState<Partner[]>([]);
  // Ids of orders that arrived since the admin last acknowledged — drives the
  // banner, the unseen count, and the per-row highlight.
  const [newIds, setNewIds] = useState<Set<string>>(new Set());
  const [muted, setMuted] = useState(false);

  const knownIds = useRef<Set<string>>(new Set());
  const firstLoad = useRef(true);
  const inFlight = useRef(false);
  const mutedRef = useRef(false);

  // Restore the mute preference.
  useEffect(() => {
    const saved =
      typeof window !== 'undefined' &&
      localStorage.getItem('orderSoundMuted') === '1';
    setMuted(saved);
    mutedRef.current = saved;
  }, []);

  // Unlock audio on the first user interaction (browser autoplay policy blocks
  // sound until the page has been interacted with at least once).
  useEffect(() => {
    const unlock = () => ensureAudio();
    window.addEventListener('pointerdown', unlock);
    window.addEventListener('keydown', unlock);
    return () => {
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };
  }, []);

  function toggleMuted() {
    setMuted((m) => {
      const next = !m;
      mutedRef.current = next;
      localStorage.setItem('orderSoundMuted', next ? '1' : '0');
      // Turning sound on: unlock + a confirmation beep so it's audibly working.
      if (!next) {
        ensureAudio();
        setTimeout(playChime, 80);
      }
      return next;
    });
  }

  const refresh = useCallback(async () => {
    if (inFlight.current) return;
    inFlight.current = true;
    try {
      const list = await api.list();
      const incoming = list.map((o) => o.id);
      if (firstLoad.current) {
        firstLoad.current = false;
        knownIds.current = new Set(incoming);
      } else {
        const fresh = incoming.filter((id) => !knownIds.current.has(id));
        if (fresh.length > 0) {
          fresh.forEach((id) => knownIds.current.add(id));
          setNewIds((prev) => {
            const n = new Set(prev);
            fresh.forEach((id) => n.add(id));
            return n;
          });
          if (!mutedRef.current) playChime();
        }
      }
      setRows(list);
    } catch {
      /* transient network/API error — try again next tick */
    } finally {
      setLoading(false);
      inFlight.current = false;
    }
  }, []);

  useEffect(() => {
    refresh();
    partnersApi.list().then(setPartners).catch(() => {});
    const t = setInterval(refresh, POLL_MS);
    return () => clearInterval(t);
  }, [refresh]);

  // Reflect the unseen count in the browser tab so it's visible when unfocused.
  useEffect(() => {
    document.title = newIds.size > 0 ? `(${newIds.size}) Orders` : 'Orders';
    return () => {
      document.title = 'Orders';
    };
  }, [newIds]);

  function markAllSeen() {
    setNewIds(new Set());
  }

  function openView(o: Order) {
    setViewing(o);
    if (newIds.has(o.id)) {
      setNewIds((prev) => {
        const n = new Set(prev);
        n.delete(o.id);
        return n;
      });
    }
  }

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
        action={
          <button
            type="button"
            onClick={toggleMuted}
            title={muted ? 'New-order sound is off' : 'New-order sound is on'}
            className="rounded-lg border border-line bg-white px-3 py-1.5 text-sm"
          >
            {muted ? '🔕 Sound off' : '🔔 Sound on'}
          </button>
        }
      />

      {newIds.size > 0 && (
        <button
          type="button"
          onClick={markAllSeen}
          className="mb-3 flex w-full items-center justify-between rounded-xl border border-brand/30 bg-brand/10 px-4 py-3 text-left"
        >
          <span className="font-semibold text-brand">
            🛎️ {newIds.size} new order{newIds.size > 1 ? 's' : ''} — review below
          </span>
          <span className="text-xs font-semibold text-brand/70">
            Dismiss
          </span>
        </button>
      )}

      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No orders yet. Place one from the app to see it here.</Empty>
        ) : (
          <Table head={['Order', 'Customer', 'Total', 'Payment', 'Status', '']}>
            {rows.map((o) => {
              const isNew = newIds.has(o.id);
              return (
                <tr
                  key={o.id}
                  className={`border-b border-line last:border-0 ${
                    isNew ? 'bg-brand/5' : ''
                  }`}
                >
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-ink">{o.code}</span>
                      {isNew && <Badge tone="green">NEW</Badge>}
                    </div>
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
                    <div className="text-xs uppercase text-muted">
                      {o.paymentMethod}
                    </div>
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
                      onClick={() => openView(o)}
                    >
                      View
                    </Button>
                  </td>
                </tr>
              );
            })}
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
                {partners.map((p) => {
                  // Only on-duty riders can be assigned. Keep the currently
                  // assigned one selectable even if they've since gone off duty,
                  // so the dropdown still shows the active assignment.
                  const isAssigned = viewing.deliveryPartner?.id === p.id;
                  const selectable = p.onDuty || isAssigned;
                  return (
                    <option key={p.id} value={p.id} disabled={!selectable}>
                      {p.onDuty ? '● ' : '○ '}
                      {p.name} · {p.phone}
                      {p.onDuty ? '' : ' (off duty)'}
                    </option>
                  );
                })}
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
