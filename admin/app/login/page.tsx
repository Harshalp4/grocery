'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { login } from '@/lib/api';
import { Button, Field, Input } from '@/components/ui';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@farmfresh.local');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      router.replace('/');
    } catch {
      setError('Invalid email or password.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-brand-dark p-4">
      <form
        onSubmit={onSubmit}
        className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-xl"
      >
        <div className="mb-6 text-center">
          <div className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-soft">
            <svg width="30" height="30" viewBox="0 0 24 24">
              <path
                d="M12 21c0-6 0-9 5-12-0.5 6-2.5 9-5 12Zm0 0c0-6 0-9-5-12 0.5 6 2.5 9 5 12Z"
                fill="#2f6b46"
              />
            </svg>
          </div>
          <h1 className="text-xl font-extrabold text-ink">FarmFresh Admin</h1>
          <p className="mt-1 text-sm text-muted">Sign in to manage the store</p>
        </div>
        <div className="space-y-4">
          <Field label="Email">
            <Input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="username"
              required
            />
          </Field>
          <Field label="Password">
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              placeholder="••••••••"
              required
            />
          </Field>
          {error && <p className="text-sm text-red-600">{error}</p>}
          <Button type="submit" disabled={loading} className="w-full">
            {loading ? 'Signing in…' : 'Sign in'}
          </Button>
        </div>
        <p className="mt-4 text-center text-[11px] text-muted">
          Dev credentials are in the backend .env
        </p>
      </form>
    </div>
  );
}
