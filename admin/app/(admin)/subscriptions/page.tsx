'use client';

import { useEffect, useState } from 'react';
import {
  Button,
  Card,
  Empty,
  Field,
  Input,
  Modal,
  PageHeader,
  Table,
} from '@/components/ui';
import { subscriptions as api } from '@/lib/resources';
import type { Subscription } from '@/lib/types';

const EMPTY: Subscription = { id: '', name: '', description: '', priceLabel: '' };

export default function SubscriptionsPage() {
  const [rows, setRows] = useState<Subscription[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Subscription | null>(null);
  const [isNew, setIsNew] = useState(false);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function onDelete(id: string) {
    if (!confirm(`Delete plan "${id}"?`)) return;
    await api.remove(id);
    load();
  }

  return (
    <div>
      <PageHeader
        title="Subscriptions"
        subtitle={`${rows.length} plans`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New plan
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : (
          <Table head={['Name', 'Description', 'Price', '']}>
            {rows.map((s) => (
              <tr key={s.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{s.name}</td>
                <td className="px-4 py-3 text-muted">{s.description}</td>
                <td className="px-4 py-3 font-semibold text-brand">{s.priceLabel}</td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <Button
                    variant="outline"
                    className="mr-2 px-3 py-1"
                    onClick={() => {
                      setEditing(s);
                      setIsNew(false);
                    }}
                  >
                    Edit
                  </Button>
                  <Button
                    variant="danger"
                    className="px-3 py-1"
                    onClick={() => onDelete(s.id)}
                  >
                    Delete
                  </Button>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>

      {editing && (
        <Form
          initial={editing}
          isNew={isNew}
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

function Form({
  initial,
  isNew,
  onClose,
  onSaved,
}: {
  initial: Subscription;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Subscription>(initial);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    setError('');
    setSaving(true);
    try {
      if (isNew) await api.create(form);
      else await api.update(form.id, form);
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={isNew ? 'New plan' : `Edit ${initial.name}`} onClose={onClose}>
      <div className="space-y-3">
        <Field label="ID (slug)">
          <Input
            value={form.id}
            disabled={!isNew}
            onChange={(e) => setForm({ ...form, id: e.target.value })}
          />
        </Field>
        <Field label="Name">
          <Input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
        </Field>
        <Field label="Description">
          <Input
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />
        </Field>
        <Field label="Price label">
          <Input
            value={form.priceLabel}
            onChange={(e) => setForm({ ...form, priceLabel: e.target.value })}
            placeholder="from ₹2,499/mo*"
          />
        </Field>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || !form.id || !form.name}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
