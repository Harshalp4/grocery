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
import { areas as api } from '@/lib/resources';
import type { Area } from '@/lib/types';

const EMPTY: Area = {
  id: '',
  pincode: '',
  area: '',
  city: '',
  etaLabel: '',
  active: true,
};

export default function AreasPage() {
  const [rows, setRows] = useState<Area[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Area | null>(null);
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
    if (!confirm('Delete this area?')) return;
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
        title="Serviceable Areas"
        subtitle={`${rows.length} areas`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New area
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No serviceable areas yet.</Empty>
        ) : (
          <Table head={['Pincode', 'Area', 'City', 'ETA', 'Status', '']}>
            {rows.map((a) => (
              <tr key={a.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{a.pincode}</td>
                <td className="px-4 py-3 text-ink">{a.area}</td>
                <td className="px-4 py-3 text-muted">{a.city}</td>
                <td className="px-4 py-3 text-muted">{a.etaLabel}</td>
                <td className="px-4 py-3">
                  <Badge tone={a.active ? 'green' : 'gray'}>
                    {a.active ? 'Active' : 'Inactive'}
                  </Badge>
                </td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <Button
                    variant="outline"
                    className="mr-2 px-3 py-1"
                    onClick={() => {
                      setEditing(a);
                      setIsNew(false);
                    }}
                  >
                    Edit
                  </Button>
                  <Button
                    variant="danger"
                    className="px-3 py-1"
                    onClick={() => onDelete(a.id)}
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
  initial: Area;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Area>(initial);
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
    <Modal
      open
      title={isNew ? 'New area' : `Edit ${initial.area}`}
      onClose={onClose}
    >
      <div className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <Field label="Pincode">
            <Input
              value={form.pincode}
              onChange={(e) => setForm({ ...form, pincode: e.target.value })}
            />
          </Field>
          <Field label="City">
            <Input
              value={form.city}
              onChange={(e) => setForm({ ...form, city: e.target.value })}
            />
          </Field>
        </div>
        <Field label="Area">
          <Input
            value={form.area}
            onChange={(e) => setForm({ ...form, area: e.target.value })}
          />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="ETA label">
            <Input
              value={form.etaLabel}
              onChange={(e) => setForm({ ...form, etaLabel: e.target.value })}
              placeholder="Same day"
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
        <Button onClick={save} disabled={saving || !form.pincode || !form.area}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
