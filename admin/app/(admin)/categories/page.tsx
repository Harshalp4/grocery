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
import { categories as api } from '@/lib/resources';
import type { Category } from '@/lib/types';

const EMPTY: Category = { slug: '', name: '', emoji: '', sortOrder: 0 };

export default function CategoriesPage() {
  const [rows, setRows] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Category | null>(null);
  const [isNew, setIsNew] = useState(false);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function onDelete(slug: string) {
    if (!confirm(`Delete category "${slug}"?`)) return;
    try {
      await api.remove(slug);
      load();
    } catch (e) {
      alert((e as Error).message);
    }
  }

  return (
    <div>
      <PageHeader
        title="Categories"
        subtitle={`${rows.length} categories`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New category
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : (
          <Table head={['Name', 'Slug', 'Emoji', '']}>
            {rows.map((c) => (
              <tr key={c.slug} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{c.name}</td>
                <td className="px-4 py-3 text-muted">{c.slug}</td>
                <td className="px-4 py-3 text-lg">{c.emoji}</td>
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
                    onClick={() => onDelete(c.slug)}
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
  initial: Category;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Category>(initial);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    setError('');
    setSaving(true);
    try {
      const payload = { ...form, sortOrder: Number(form.sortOrder ?? 0) };
      if (isNew) await api.create(payload);
      else await api.update(form.slug, payload);
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={isNew ? 'New category' : `Edit ${initial.name}`} onClose={onClose}>
      <div className="space-y-3">
        <Field label="Slug (id)">
          <Input
            value={form.slug}
            disabled={!isNew}
            onChange={(e) => setForm({ ...form, slug: e.target.value })}
          />
        </Field>
        <Field label="Name">
          <Input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Emoji (optional)">
            <Input
              value={form.emoji}
              onChange={(e) => setForm({ ...form, emoji: e.target.value })}
            />
          </Field>
          <Field label="Sort order">
            <Input
              type="number"
              value={form.sortOrder ?? 0}
              onChange={(e) =>
                setForm({ ...form, sortOrder: Number(e.target.value) })
              }
            />
          </Field>
        </div>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || !form.slug || !form.name}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
