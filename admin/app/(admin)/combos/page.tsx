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
  Textarea,
} from '@/components/ui';
import { combos as api } from '@/lib/resources';
import type { Combo, ComboType } from '@/lib/types';

const TYPES: ComboType[] = ['family', 'health', 'festival'];
const EMPTY: Combo = {
  id: '',
  name: '',
  type: 'family',
  price: 0,
  size: '',
  duration: '',
  items: '',
  savingsNote: '',
};

export default function CombosPage() {
  const [rows, setRows] = useState<Combo[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Combo | null>(null);
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
    if (!confirm(`Delete combo "${id}"?`)) return;
    await api.remove(id);
    load();
  }

  return (
    <div>
      <PageHeader
        title="Combo Packs"
        subtitle={`${rows.length} packs`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New pack
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : (
          <Table head={['Name', 'Type', 'Price', 'Size', '']}>
            {rows.map((c) => (
              <tr key={c.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3">
                  <div className="font-semibold text-ink">{c.name}</div>
                  <div className="max-w-xs truncate text-xs text-muted">{c.items}</div>
                </td>
                <td className="px-4 py-3">
                  <Badge>{c.type}</Badge>
                </td>
                <td className="px-4 py-3 font-bold text-brand">
                  ₹{c.price.toLocaleString('en-IN')}
                </td>
                <td className="px-4 py-3 text-muted">{c.size}</td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <Button
                    variant="outline"
                    className="mr-2 px-3 py-1"
                    onClick={() => {
                      setEditing(c);
                      setIsNew(false);
                    }}
                  >
                    Edit
                  </Button>
                  <Button
                    variant="danger"
                    className="px-3 py-1"
                    onClick={() => onDelete(c.id)}
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
  initial: Combo;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Combo>(initial);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  function set<K extends keyof Combo>(k: K, v: Combo[K]) {
    setForm((f) => ({ ...f, [k]: v }));
  }

  async function save() {
    setError('');
    setSaving(true);
    try {
      const payload = { ...form, price: Number(form.price) };
      if (isNew) await api.create(payload);
      else await api.update(form.id, payload);
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={isNew ? 'New combo pack' : `Edit ${initial.name}`} onClose={onClose}>
      <div className="grid grid-cols-2 gap-3">
        <Field label="ID (slug)">
          <Input value={form.id} disabled={!isNew} onChange={(e) => set('id', e.target.value)} />
        </Field>
        <Field label="Type">
          <Select value={form.type} onChange={(e) => set('type', e.target.value as ComboType)}>
            {TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Name">
          <Input value={form.name} onChange={(e) => set('name', e.target.value)} />
        </Field>
        <Field label="Price (₹)">
          <Input
            type="number"
            value={form.price}
            onChange={(e) => set('price', Number(e.target.value))}
          />
        </Field>
        <Field label="Size">
          <Input value={form.size} onChange={(e) => set('size', e.target.value)} />
        </Field>
        <Field label="Duration">
          <Input value={form.duration} onChange={(e) => set('duration', e.target.value)} />
        </Field>
      </div>
      <div className="mt-3 space-y-3">
        <Field label="Items (comma separated)">
          <Textarea
            rows={2}
            value={form.items}
            onChange={(e) => set('items', e.target.value)}
          />
        </Field>
        <Field label="Savings note">
          <Input
            value={form.savingsNote}
            onChange={(e) => set('savingsNote', e.target.value)}
            placeholder="Save ~₹320*"
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
