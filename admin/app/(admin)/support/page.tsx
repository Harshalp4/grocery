'use client';

import { useEffect, useState } from 'react';
import {
  Badge,
  Button,
  Card,
  Empty,
  Field,
  Modal,
  PageHeader,
  Select,
  Table,
  Textarea,
} from '@/components/ui';
import { support as api } from '@/lib/resources';
import type { SupportTicket, TicketStatus } from '@/lib/types';

const tone = (s: TicketStatus) =>
  s === 'open' ? 'gold' : s === 'resolved' ? 'green' : 'gray';

export default function SupportPage() {
  const [rows, setRows] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<SupportTicket | null>(null);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  return (
    <div>
      <PageHeader title="Support" subtitle={`${rows.length} tickets`} />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No support tickets.</Empty>
        ) : (
          <Table head={['Subject', 'Customer', 'Status', 'Updated', '']}>
            {rows.map((t) => (
              <tr key={t.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{t.subject}</td>
                <td className="px-4 py-3 text-muted">
                  {t.customerName ?? '—'}
                  <span className="block text-xs">{t.phone}</span>
                </td>
                <td className="px-4 py-3">
                  <Badge tone={tone(t.status)}>{t.status}</Badge>
                </td>
                <td className="px-4 py-3 text-xs text-muted">
                  {new Date(t.updatedAt).toLocaleDateString()}
                </td>
                <td className="px-4 py-3 text-right">
                  <Button
                    variant="outline"
                    className="px-3 py-1"
                    onClick={() => setEditing(t)}
                  >
                    View
                  </Button>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>

      {editing && (
        <Detail
          ticket={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            load();
          }}
        />
      )}
    </div>
  );
}

function Detail({
  ticket,
  onClose,
  onSaved,
}: {
  ticket: SupportTicket;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [status, setStatus] = useState<TicketStatus>(ticket.status);
  const [reply, setReply] = useState(ticket.reply ?? '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function save() {
    setError('');
    setSaving(true);
    try {
      await api.update(ticket.id, { status, reply });
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={ticket.subject} onClose={onClose}>
      <div className="space-y-3">
        <div className="rounded-lg bg-black/5 p-3 text-sm text-ink">
          {ticket.message}
        </div>
        <p className="text-xs text-muted">
          From {ticket.customerName ?? '—'} · {ticket.phone}
          {ticket.orderId ? ` · order ${ticket.orderId.slice(0, 8)}` : ''}
        </p>
        <Field label="Reply to customer">
          <Textarea
            rows={3}
            value={reply}
            onChange={(e) => setReply(e.target.value)}
          />
        </Field>
        <Field label="Status">
          <Select
            value={status}
            onChange={(e) => setStatus(e.target.value as TicketStatus)}
          >
            <option value="open">Open</option>
            <option value="resolved">Resolved</option>
            <option value="closed">Closed</option>
          </Select>
        </Field>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
