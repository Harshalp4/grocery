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
import { admins as api } from '@/lib/resources';
import type { AdminUser } from '@/lib/types';

export default function AdminsPage() {
  const [rows, setRows] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState<AdminUser | null>(null);
  const [creating, setCreating] = useState(false);

  async function load() {
    setLoading(true);
    setError('');
    try {
      setRows(await api.list());
    } catch (e) {
      setError((e as Error).message);
    }
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function onDelete(id: string) {
    if (!confirm('Delete this admin user?')) return;
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
        title="Admin Users"
        subtitle="Back-office accounts (superadmin only)"
        action={<Button onClick={() => setCreating(true)}>+ New admin</Button>}
      />
      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : error ? (
          <Empty>{error}</Empty>
        ) : rows.length === 0 ? (
          <Empty>No admin users yet. The env bootstrap admin still works.</Empty>
        ) : (
          <Table head={['Email', 'Role', 'Status', '']}>
            {rows.map((a) => (
              <tr key={a.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3 font-semibold text-ink">{a.email}</td>
                <td className="px-4 py-3">
                  <Badge tone={a.role === 'admin' ? 'green' : 'gold'}>
                    {a.role}
                  </Badge>
                </td>
                <td className="px-4 py-3">
                  <Badge tone={a.active ? 'green' : 'gray'}>
                    {a.active ? 'Active' : 'Disabled'}
                  </Badge>
                </td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <Button
                    variant="outline"
                    className="mr-2 px-3 py-1"
                    onClick={() => setEditing(a)}
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

      {creating && (
        <CreateForm
          onClose={() => setCreating(false)}
          onSaved={() => {
            setCreating(false);
            load();
          }}
        />
      )}
      {editing && (
        <EditForm
          user={editing}
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

function CreateForm({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('staff');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    setError('');
    setSaving(true);
    try {
      await api.create({ email: email.trim().toLowerCase(), password, role });
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title="New admin user" onClose={onClose}>
      <div className="space-y-3">
        <Field label="Email">
          <Input value={email} onChange={(e) => setEmail(e.target.value)} />
        </Field>
        <Field label="Password" hint="at least 6 characters">
          <Input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </Field>
        <Field label="Role">
          <Select value={role} onChange={(e) => setRole(e.target.value)}>
            <option value="staff">Staff</option>
            <option value="admin">Admin (superadmin)</option>
          </Select>
        </Field>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button
          onClick={save}
          disabled={saving || !email.trim() || password.length < 6}
        >
          {saving ? 'Saving…' : 'Create'}
        </Button>
      </div>
    </Modal>
  );
}

function EditForm({
  user,
  onClose,
  onSaved,
}: {
  user: AdminUser;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [role, setRole] = useState(user.role);
  const [active, setActive] = useState(user.active);
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    setError('');
    setSaving(true);
    try {
      await api.update(user.id, {
        role,
        active,
        ...(password ? { password } : {}),
      });
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={`Edit ${user.email}`} onClose={onClose}>
      <div className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <Field label="Role">
            <Select
              value={role}
              onChange={(e) => setRole(e.target.value as AdminUser['role'])}
            >
              <option value="staff">Staff</option>
              <option value="admin">Admin</option>
            </Select>
          </Field>
          <Field label="Status">
            <Select
              value={active ? 'active' : 'disabled'}
              onChange={(e) => setActive(e.target.value === 'active')}
            >
              <option value="active">Active</option>
              <option value="disabled">Disabled</option>
            </Select>
          </Field>
        </div>
        <Field label="Reset password" hint="leave blank to keep current">
          <Input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </Field>
      </div>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={save} disabled={saving || (!!password && password.length < 6)}>
          {saving ? 'Saving…' : 'Save'}
        </Button>
      </div>
    </Modal>
  );
}
