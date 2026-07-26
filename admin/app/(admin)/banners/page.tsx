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
import { banners as api } from '@/lib/resources';
import type { Banner } from '@/lib/types';

const EMPTY: Banner = {
  id: '',
  title: '',
  subtitle: '',
  imageUrl: null,
  actionType: null,
  actionValue: null,
  active: true,
  sortOrder: 0,
};

export default function BannersPage() {
  const [rows, setRows] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Banner | null>(null);
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
    if (!confirm('Delete this banner?')) return;
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
        title="Banners"
        subtitle={`${rows.length} banners`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New banner
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No banners yet.</Empty>
        ) : (
          <Table head={['Order', 'Title', 'Action', 'Status', '']}>
            {rows.map((b) => (
              <tr key={b.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 text-muted">{b.sortOrder}</td>
                <td className="px-4 py-3">
                  <div className="font-semibold text-ink">{b.title}</div>
                  <div className="text-xs text-muted">{b.subtitle}</div>
                </td>
                <td className="px-4 py-3 text-xs text-muted">
                  {b.actionType ? `${b.actionType}: ${b.actionValue ?? ''}` : '—'}
                </td>
                <td className="px-4 py-3">
                  <Badge tone={b.active ? 'green' : 'gray'}>
                    {b.active ? 'Active' : 'Hidden'}
                  </Badge>
                </td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <Button
                    variant="outline"
                    className="mr-2 px-3 py-1"
                    onClick={() => {
                      setEditing(b);
                      setIsNew(false);
                    }}
                  >
                    Edit
                  </Button>
                  <Button
                    variant="danger"
                    className="px-3 py-1"
                    onClick={() => onDelete(b.id)}
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
  initial: Banner;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Banner>(initial);
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
    <Modal open title={isNew ? 'New banner' : 'Edit banner'} onClose={onClose}>
      <div className="space-y-3">
        <Field label="Title">
          <Input
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
          />
        </Field>
        <Field label="Subtitle">
          <Input
            value={form.subtitle}
            onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
          />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Action type">
            <Select
              value={form.actionType ?? ''}
              onChange={(e) =>
                setForm({ ...form, actionType: e.target.value || null })
              }
            >
              <option value="">None</option>
              <option value="url">In-app route</option>
              <option value="category">Category</option>
              <option value="product">Product</option>
            </Select>
          </Field>
          <Field label="Action value" hint="route / slug / product id">
            <Input
              value={form.actionValue ?? ''}
              onChange={(e) =>
                setForm({ ...form, actionValue: e.target.value || null })
              }
            />
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Sort order">
            <Input
              type="number"
              value={form.sortOrder}
              onChange={(e) =>
                setForm({ ...form, sortOrder: Number(e.target.value) || 0 })
              }
            />
          </Field>
          <Field label="Status">
            <Select
              value={form.active ? 'active' : 'hidden'}
              onChange={(e) =>
                setForm({ ...form, active: e.target.value === 'active' })
              }
            >
              <option value="active">Active</option>
              <option value="hidden">Hidden</option>
            </Select>
          </Field>
        </div>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || !form.title.trim()}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
