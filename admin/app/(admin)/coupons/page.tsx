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
import { coupons as api } from '@/lib/resources';
import type { Coupon } from '@/lib/types';

const EMPTY: Coupon = {
  id: '',
  code: '',
  type: 'flat',
  value: 0,
  minOrder: 0,
  maxDiscount: 0,
  validFrom: null,
  validTo: null,
  usageLimit: 0,
  perUserLimit: 0,
  timesUsed: 0,
  active: true,
};

function discountLabel(c: Coupon): string {
  if (c.type === 'percent') {
    return `${c.value}%${c.maxDiscount > 0 ? ` (max ₹${c.maxDiscount})` : ''}`;
  }
  return `₹${c.value}`;
}

export default function CouponsPage() {
  const [rows, setRows] = useState<Coupon[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Coupon | null>(null);
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
    if (!confirm('Delete this coupon?')) return;
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
        title="Coupons"
        subtitle={`${rows.length} coupons`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY });
              setIsNew(true);
            }}
          >
            + New coupon
          </Button>
        }
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No coupons yet.</Empty>
        ) : (
          <Table head={['Code', 'Discount', 'Min order', 'Used', 'Status', '']}>
            {rows.map((c) => (
              <tr key={c.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{c.code}</td>
                <td className="px-4 py-3 text-muted">{discountLabel(c)}</td>
                <td className="px-4 py-3 text-muted">
                  {c.minOrder > 0 ? `₹${c.minOrder}` : '—'}
                </td>
                <td className="px-4 py-3 text-muted">
                  {c.timesUsed}
                  {c.usageLimit > 0 ? ` / ${c.usageLimit}` : ''}
                </td>
                <td className="px-4 py-3">
                  <Badge tone={c.active ? 'green' : 'gray'}>
                    {c.active ? 'Active' : 'Inactive'}
                  </Badge>
                </td>
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
  initial: Coupon;
  isNew: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Coupon>(initial);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  const num = (v: string) => (v === '' ? 0 : Math.max(0, Number(v) || 0));
  const dateVal = (v: string | null) => (v ? v.slice(0, 10) : '');

  async function save() {
    setError('');
    setSaving(true);
    try {
      const body = { ...form, code: form.code.trim().toUpperCase() };
      if (isNew) await api.create(body);
      else await api.update(form.id, body);
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={isNew ? 'New coupon' : `Edit ${initial.code}`} onClose={onClose}>
      <div className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <Field label="Code">
            <Input
              value={form.code}
              disabled={!isNew}
              placeholder="FRESH50"
              onChange={(e) =>
                setForm({ ...form, code: e.target.value.toUpperCase() })
              }
            />
          </Field>
          <Field label="Type">
            <Select
              value={form.type}
              onChange={(e) =>
                setForm({ ...form, type: e.target.value as Coupon['type'] })
              }
            >
              <option value="flat">Flat (₹ off)</option>
              <option value="percent">Percent (% off)</option>
            </Select>
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field label={form.type === 'percent' ? 'Percent off (%)' : 'Amount off (₹)'}>
            <Input
              type="number"
              value={form.value}
              onChange={(e) => setForm({ ...form, value: num(e.target.value) })}
            />
          </Field>
          <Field label="Min order (₹)">
            <Input
              type="number"
              value={form.minOrder}
              onChange={(e) => setForm({ ...form, minOrder: num(e.target.value) })}
            />
          </Field>
        </div>
        {form.type === 'percent' && (
          <Field label="Max discount (₹, 0 = no cap)">
            <Input
              type="number"
              value={form.maxDiscount}
              onChange={(e) =>
                setForm({ ...form, maxDiscount: num(e.target.value) })
              }
            />
          </Field>
        )}
        <div className="grid grid-cols-2 gap-3">
          <Field label="Total uses (0 = unlimited)">
            <Input
              type="number"
              value={form.usageLimit}
              onChange={(e) =>
                setForm({ ...form, usageLimit: num(e.target.value) })
              }
            />
          </Field>
          <Field label="Per-user uses (0 = unlimited)">
            <Input
              type="number"
              value={form.perUserLimit}
              onChange={(e) =>
                setForm({ ...form, perUserLimit: num(e.target.value) })
              }
            />
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Valid from (optional)">
            <Input
              type="date"
              value={dateVal(form.validFrom)}
              onChange={(e) =>
                setForm({ ...form, validFrom: e.target.value || null })
              }
            />
          </Field>
          <Field label="Valid to (optional)">
            <Input
              type="date"
              value={dateVal(form.validTo)}
              onChange={(e) =>
                setForm({ ...form, validTo: e.target.value || null })
              }
            />
          </Field>
        </div>
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
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || !form.code.trim() || form.value <= 0}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
