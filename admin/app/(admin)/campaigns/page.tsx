'use client';

import { useState } from 'react';
import { Button, Card, Field, Input, PageHeader } from '@/components/ui';
import { campaigns } from '@/lib/resources';

export default function CampaignsPage() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [error, setError] = useState('');

  async function send() {
    setError('');
    setResult(null);
    setSending(true);
    try {
      const r = await campaigns.send(title.trim(), body.trim());
      setResult(`Sent to ${r.sentTo} customer${r.sentTo === 1 ? '' : 's'}.`);
      setTitle('');
      setBody('');
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSending(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Notifications"
        subtitle="Broadcast a message to every customer's inbox (and push, when Firebase is configured)."
      />
      <Card>
        <div className="space-y-3 p-1">
          <Field label="Title">
            <Input
              value={title}
              placeholder="Monsoon Sale"
              onChange={(e) => setTitle(e.target.value)}
            />
          </Field>
          <Field label="Message">
            <textarea
              className="w-full rounded-lg border border-line bg-white px-3 py-2 text-sm outline-none focus:border-brand"
              rows={4}
              value={body}
              placeholder="Flat 10% off staples this week — use code SAVE10."
              onChange={(e) => setBody(e.target.value)}
            />
          </Field>
          {result && <p className="text-sm font-medium text-brand">{result}</p>}
          {error && <p className="text-sm text-red-600">{error}</p>}
          <div className="flex justify-end">
            <Button
              onClick={send}
              disabled={sending || !title.trim() || !body.trim()}
            >
              {sending ? 'Sending…' : 'Send broadcast'}
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
}
