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
import { partners as api } from '@/lib/resources';
import type { Partner } from '@/lib/types';

const EMPTY: Partner = { id: '', name: '', phone: '', active: true };

export default function PartnersPage() {
  const [rows, setRows] = useState<Partner[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Partner | null>(null);
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
    if (!confirm('Delete this partner?')) return;
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
        title="Delivery Partners"
        subtitle={`${rows.length} partners`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New partner
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No delivery partners yet.</Empty>
        ) : (
          <Table head={['Name', 'Phone', 'Status', '']}>
            {rows.map((p) => (
              <tr key={p.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{p.name}</td>
                <td className="px-4 py-3 text-muted">{p.phone}</td>
                <td className="px-4 py-3">
                  <Badge tone={p.active ? 'green' : 'gray'}>
                    {p.active ? 'Active' : 'Inactive'}
                  </Badge>
                </td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <Button
                    variant="outline"
                    className="mr-2 px-3 py-1"
                    onClick={() => {
                      setEditing(p);
                      setIsNew(false);
                    }}
                  >
                    Edit
                  </Button>
                  <Button
                    variant="danger"
                    className="px-3 py-1"
                    onClick={() => onDelete(p.id)}
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
  initial: Partner;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Partner>(initial);
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
      title={isNew ? 'New partner' : `Edit ${initial.name}`}
      onClose={onClose}
    >
      <div className="space-y-3">
        <Field label="Name">
          <Input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Phone">
            <Input
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
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
        <Button onClick={save} disabled={saving || !form.name || !form.phone}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
