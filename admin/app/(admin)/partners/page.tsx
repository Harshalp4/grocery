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

export default function PartnersPage() {
  const [rows, setRows] = useState<Partner[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<Partner | null>(null);
  const [creds, setCreds] = useState<{ phone: string; password: string } | null>(null);

  async function load() {
    setLoading(true);
    setRows(await api.list());
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function onDelete(id: string) {
    if (!confirm('Delete this partner? (Deactivate instead if they have active orders.)')) return;
    try {
      await api.remove(id);
      load();
    } catch (e) {
      alert((e as Error).message);
    }
  }

  async function onReset(p: Partner) {
    if (!confirm(`Reset ${p.name}'s password? This logs them out of all devices.`)) return;
    try {
      const r = await api.resetPassword(p.id);
      setCreds({ phone: p.phone, password: r.tempPassword });
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
        action={<Button onClick={() => setCreating(true)}>+ New partner</Button>}
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No delivery partners yet.</Empty>
        ) : (
          <Table head={['Name', 'Phone', 'Vehicle', 'Credentials', 'Status', '']}>
            {rows.map((p) => (
              <tr key={p.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{p.name}</td>
                <td className="px-4 py-3 text-muted">{p.phone}</td>
                <td className="px-4 py-3 text-xs text-muted">
                  {p.vehicleType ?? '—'}
                  {p.vehicleNumber ? ` · ${p.vehicleNumber}` : ''}
                </td>
                <td className="px-4 py-3">
                  {p.hasCredentials ? (
                    <Badge tone={p.mustChangePassword ? 'gold' : 'green'}>
                      {p.mustChangePassword ? 'Temp password' : 'Set'}
                    </Badge>
                  ) : (
                    <Badge tone="gray">None</Badge>
                  )}
                </td>
                <td className="px-4 py-3">
                  <Badge tone={p.active ? 'green' : 'gray'}>
                    {p.active ? 'Active' : 'Inactive'}
                  </Badge>
                </td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <Button variant="ghost" className="mr-1 px-2 py-1" onClick={() => onReset(p)}>
                    Reset pw
                  </Button>
                  <Button
                    variant="outline"
                    className="mr-1 px-3 py-1"
                    onClick={() => setEditing(p)}
                  >
                    Edit
                  </Button>
                  <Button variant="danger" className="px-3 py-1" onClick={() => onDelete(p.id)}>
                    Delete
                  </Button>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>

      {creating && (
        <CreateForm
          onClose={() => setCreating(false)}
          onCreated={(phone, password) => {
            setCreating(false);
            setCreds({ phone, password });
            load();
          }}
        />
      )}
      {editing && (
        <EditForm
          partner={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            load();
          }}
        />
      )}
      {creds && <CredentialModal creds={creds} onClose={() => setCreds(null)} />}
    </div>
  );
}

const VEHICLES = ['bike', 'scooter', 'ev', 'cycle', 'van'];

function CreateForm({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: (phone: string, password: string) => void;
}) {
  const [form, setForm] = useState({
    name: '',
    phone: '',
    vehicleType: 'bike',
    vehicleNumber: '',
    zone: '',
  });
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    setError('');
    setSaving(true);
    try {
      const r = await api.create(form);
      onCreated(r.partner.phone, r.tempPassword);
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title="New delivery partner" onClose={onClose}>
      <div className="space-y-3">
        <Field label="Name">
          <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </Field>
        <Field label="Phone" hint="the partner's login ID — can't be changed later">
          <Input
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
          />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Vehicle type">
            <Select
              value={form.vehicleType}
              onChange={(e) => setForm({ ...form, vehicleType: e.target.value })}
            >
              {VEHICLES.map((v) => (
                <option key={v} value={v}>
                  {v}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Vehicle number">
            <Input
              value={form.vehicleNumber}
              onChange={(e) => setForm({ ...form, vehicleNumber: e.target.value })}
            />
          </Field>
        </div>
        <Field label="Zone (optional)">
          <Input value={form.zone} onChange={(e) => setForm({ ...form, zone: e.target.value })} />
        </Field>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || !form.name.trim() || form.phone.trim().length < 8}>
          {saving ? 'Creating…' : 'Create & issue password'}
        </Button>
      </div>
    </Modal>
  );
}

function EditForm({
  partner,
  onClose,
  onSaved,
}: {
  partner: Partner;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState({
    name: partner.name,
    vehicleType: partner.vehicleType ?? 'bike',
    vehicleNumber: partner.vehicleNumber ?? '',
    zone: partner.zone ?? '',
    active: partner.active,
  });
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    setError('');
    setSaving(true);
    try {
      await api.update(partner.id, form);
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={`Edit ${partner.name}`} onClose={onClose}>
      <div className="space-y-3">
        <Field label="Name">
          <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Vehicle type">
            <Select
              value={form.vehicleType}
              onChange={(e) => setForm({ ...form, vehicleType: e.target.value })}
            >
              {VEHICLES.map((v) => (
                <option key={v} value={v}>
                  {v}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Vehicle number">
            <Input
              value={form.vehicleNumber}
              onChange={(e) => setForm({ ...form, vehicleNumber: e.target.value })}
            />
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Zone">
            <Input value={form.zone} onChange={(e) => setForm({ ...form, zone: e.target.value })} />
          </Field>
          <Field label="Status">
            <Select
              value={form.active ? 'active' : 'inactive'}
              onChange={(e) => setForm({ ...form, active: e.target.value === 'active' })}
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive (revokes sessions)</option>
            </Select>
          </Field>
        </div>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || !form.name.trim()}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}

function CredentialModal({
  creds,
  onClose,
}: {
  creds: { phone: string; password: string };
  onClose: () => void;
}) {
  return (
    <Modal open title="Partner credentials" onClose={onClose}>
      <p className="text-sm text-ink">Share these with the delivery partner:</p>
      <div className="mt-3 space-y-2 rounded-xl border border-line bg-black/5 p-4 font-mono text-sm">
        <div className="flex justify-between">
          <span className="text-muted">Phone</span>
          <span className="font-semibold">{creds.phone}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted">Password</span>
          <span className="font-semibold">{creds.password}</span>
        </div>
      </div>
      <p className="mt-3 text-xs text-gold">
        ⚠ Shown only once and cannot be recovered. The partner must change it at first login.
      </p>
      <div className="mt-5 flex justify-end gap-2">
        <Button
          variant="outline"
          onClick={() => navigator.clipboard?.writeText(`Phone: ${creds.phone}\nPassword: ${creds.password}`)}
        >
          Copy
        </Button>
        <Button onClick={onClose}>Done</Button>
      </div>
    </Modal>
  );
}
