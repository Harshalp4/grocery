'use client';

import { useEffect, useState } from 'react';
import {
  Badge,
  Button,
  Card,
  Empty,
  Field,
  Input,
  Modal,
  PageHeader,
  Select,
  Table,
} from '@/components/ui';
import { slots as api } from '@/lib/resources';
import type { Slot } from '@/lib/types';

const EMPTY: Slot = { id: '', label: '', active: true, sortOrder: 0 };

export default function SlotsPage() {
  const [rows, setRows] = useState<Slot[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Slot | null>(null);
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
    if (!confirm('Delete this slot?')) return;
    try {
      await api.remove(id);
      load();
    } catch (e) {
      alert((e as Error).message);
    }
  }

  return (
    <div>
      <PageHeader
        title="Delivery Slots"
        subtitle={`${rows.length} slots`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New slot
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No slots yet.</Empty>
        ) : (
          <Table head={['Label', 'Sort', 'Status', '']}>
            {rows.map((s) => (
              <tr key={s.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{s.label}</td>
                <td className="px-4 py-3 text-muted">{s.sortOrder}</td>
                <td className="px-4 py-3">
                  <Badge tone={s.active ? 'green' : 'gray'}>
                    {s.active ? 'Active' : 'Inactive'}
                  </Badge>
                </td>
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
  initial: Slot;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Slot>(initial);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    setError('');
    setSaving(true);
    try {
      const payload = { ...form, sortOrder: Number(form.sortOrder ?? 0) };
      if (isNew) await api.create(payload);
      else await api.update(form.id, payload);
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={isNew ? 'New slot' : `Edit ${initial.label}`} onClose={onClose}>
      <div className="space-y-3">
        <Field label="Label">
          <Input
            value={form.label}
            onChange={(e) => setForm({ ...form, label: e.target.value })}
            placeholder="Morning · 7–10 AM"
          />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Sort order">
            <Input
              type="number"
              value={form.sortOrder}
              onChange={(e) =>
                setForm({ ...form, sortOrder: Number(e.target.value) })
              }
            />
          </Field>
          <Field label="Status">
            <Select
              value={form.active ? 'active' : 'inactive'}
              onChange={(e) =>
                setForm({ ...form, active: e.target.value === 'active' })
              }
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </Select>
          </Field>
        </div>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || !form.label}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
