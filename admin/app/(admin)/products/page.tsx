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
import {
  categories as catApi,
  products as api,
  variants as variantApi,
  type VariantInput,
} from '@/lib/resources';
import { API_BASE } from '@/lib/api';
import type { Category, Product, ProductVariant } from '@/lib/types';

const EMPTY: Product = {
  id: '',
  name: '',
  source: '',
  packedDate: '',
  price: 0,
  marketPrice: 0,
  grade: '',
  tags: [],
  harvestMonth: '',
  packSize: '',
  nutrition: {},
  categorySlug: '',
  imageUrl: null,
  stock: 0,
  inStock: true,
  variants: [],
};

function Thumb({ src, alt }: { src: string | null; alt: string }) {
  if (!src) {
    return (
      <div className="flex h-11 w-11 items-center justify-center rounded-lg border border-line bg-brand-soft text-muted">
        <span className="text-base">🛒</span>
      </div>
    );
  }
  // eslint-disable-next-line @next/next/no-img-element
  return (
    <img
      src={`${API_BASE}${src}`}
      alt={alt}
      className="h-11 w-11 rounded-lg border border-line object-cover"
    />
  );
}

function StockCell({ p }: { p: Product }) {
  if (p.variants.length > 0) {
    return <span className="text-muted">{p.variants.length} variants</span>;
  }
  const outOfStock = p.stock === 0;
  const low = p.stock >= 1 && p.stock <= 5;
  return (
    <span className="inline-flex items-center gap-2">
      <span className="font-semibold text-ink">{p.stock}</span>
      {outOfStock ? (
        <span className="inline-block rounded-md bg-red-100 px-2 py-0.5 text-xs font-semibold text-red-700">
          Out of stock
        </span>
      ) : low ? (
        <span className="inline-block rounded-md bg-amber-100 px-2 py-0.5 text-xs font-semibold text-amber-700">
          Low
        </span>
      ) : null}
    </span>
  );
}

export default function ProductsPage() {
  const [rows, setRows] = useState<Product[]>([]);
  const [cats, setCats] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Product | null>(null);
  const [isNew, setIsNew] = useState(false);

  async function load() {
    setLoading(true);
    const [p, c] = await Promise.all([api.list(), catApi.list()]);
    setRows(p);
    setCats(c);
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, []);

  async function onDelete(id: string) {
    if (!confirm(`Delete product "${id}"? This also removes its reviews.`)) return;
    await api.remove(id);
    load();
  }

  return (
    <div>
      <PageHeader
        title="Products"
        subtitle={`${rows.length} products`}
        action={
          <Button
            onClick={() => {
              setEditing({ ...EMPTY, categorySlug: cats[0]?.slug ?? '' });
              setIsNew(true);
            }}
          >
            + New product
          </Button>
        }
      />

      <Card>
        {loading ? (
          <Empty>Loading…</Empty>
        ) : rows.length === 0 ? (
          <Empty>No products yet.</Empty>
        ) : (
          <Table head={['', 'Name', 'Category', 'Price', 'Stock', 'Grade', 'Tags', '']}>
            {rows.map((p) => (
              <tr key={p.id} className="border-b border-line last:border-0">
                <td className="px-4 py-3">
                  <Thumb src={p.imageUrl} alt={p.name} />
                </td>
                <td className="px-4 py-3">
                  <div className="font-semibold text-ink">{p.name}</div>
                  <div className="text-xs text-muted">{p.source}</div>
                </td>
                <td className="px-4 py-3 text-muted">{p.categorySlug}</td>
                <td className="px-4 py-3">
                  <span className="font-bold text-brand">₹{p.price}</span>{' '}
                  <span className="text-xs text-muted line-through">
                    ₹{p.marketPrice}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <StockCell p={p} />
                </td>
                <td className="px-4 py-3 text-muted">{p.grade}</td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-1">
                    {p.tags.map((t) => (
                      <Badge key={t} tone="gold">
                        {t}
                      </Badge>
                    ))}
                  </div>
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
        <ProductForm
          initial={editing}
          isNew={isNew}
          cats={cats}
          onClose={() => setEditing(null)}
          onRefresh={load}
          onSaved={() => {
            setEditing(null);
            load();
          }}
        />
      )}
    </div>
  );
}

function ProductForm({
  initial,
  isNew,
  cats,
  onClose,
  onRefresh,
  onSaved,
}: {
  initial: Product;
  isNew: boolean;
  cats: Category[];
  onClose: () => void;
  onRefresh: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<Product>(initial);
  const [tagsText, setTagsText] = useState(initial.tags.join(', '));
  const [nutText, setNutText] = useState(
    Object.entries(initial.nutrition)
      .map(([k, v]) => `${k}: ${v}`)
      .join('\n'),
  );
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  const [uploading, setUploading] = useState(false);

  function set<K extends keyof Product>(k: K, v: Product[K]) {
    setForm((f) => ({ ...f, [k]: v }));
  }

  async function onPickImage(file: File) {
    setError('');
    setUploading(true);
    try {
      const dataUrl = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result as string);
        reader.onerror = () => reject(reader.error ?? new Error('Read failed'));
        reader.readAsDataURL(file);
      });
      const { imageUrl } = await api.uploadImage(form.id, dataUrl);
      set('imageUrl', imageUrl);
      onRefresh();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setUploading(false);
    }
  }

  async function save() {
    setError('');
    setSaving(true);
    const tags = tagsText.split(',').map((s) => s.trim()).filter(Boolean);
    const nutrition: Record<string, string> = {};
    nutText.split('\n').forEach((line) => {
      const [k, ...rest] = line.split(':');
      if (k?.trim() && rest.length) nutrition[k.trim()] = rest.join(':').trim();
    });
    const payload: Product = {
      ...form,
      price: Number(form.price),
      marketPrice: Number(form.marketPrice),
      stock: Number(form.stock),
      tags,
      nutrition,
    };
    try {
      if (isNew) await api.create(payload);
      else await api.update(form.id, payload);
      onSaved();
    } catch (e) {
      setError((e as Error).message);
      setSaving(false);
    }
  }

  return (
    <Modal open title={isNew ? 'New product' : `Edit ${initial.name}`} onClose={onClose}>
      <div className="grid grid-cols-2 gap-3">
        <Field label="ID (slug)">
          <Input
            value={form.id}
            disabled={!isNew}
            onChange={(e) => set('id', e.target.value)}
          />
        </Field>
        <Field label="Category">
          <Select
            value={form.categorySlug}
            onChange={(e) => set('categorySlug', e.target.value)}
          >
            {cats.map((c) => (
              <option key={c.slug} value={c.slug}>
                {c.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Name">
          <Input value={form.name} onChange={(e) => set('name', e.target.value)} />
        </Field>
        <Field label="Grade">
          <Input value={form.grade} onChange={(e) => set('grade', e.target.value)} />
        </Field>
        <Field label="Price (₹)">
          <Input
            type="number"
            value={form.price}
            onChange={(e) => set('price', Number(e.target.value))}
          />
        </Field>
        <Field label="Market price (₹)">
          <Input
            type="number"
            value={form.marketPrice}
            onChange={(e) => set('marketPrice', Number(e.target.value))}
          />
        </Field>
        <Field
          label="Stock"
          hint={
            form.variants.length > 0
              ? 'Managed per variant below'
              : undefined
          }
        >
          <Input
            type="number"
            value={form.stock}
            onChange={(e) => set('stock', Number(e.target.value))}
          />
        </Field>
        <Field label="Source">
          <Input value={form.source} onChange={(e) => set('source', e.target.value)} />
        </Field>
        <Field label="Packed date">
          <Input
            value={form.packedDate}
            onChange={(e) => set('packedDate', e.target.value)}
          />
        </Field>
        <Field label="Pack size">
          <Input
            value={form.packSize ?? ''}
            onChange={(e) => set('packSize', e.target.value)}
          />
        </Field>
        <Field label="Harvest month">
          <Input
            value={form.harvestMonth ?? ''}
            onChange={(e) => set('harvestMonth', e.target.value)}
          />
        </Field>
      </div>
      <div className="mt-3 space-y-3">
        <Field label="Tags (comma separated)" hint="e.g. best, fresh, premium">
          <Input value={tagsText} onChange={(e) => setTagsText(e.target.value)} />
        </Field>
        <Field label="Nutrition (one per line, Key: Value)">
          <Textarea
            rows={3}
            value={nutText}
            onChange={(e) => setNutText(e.target.value)}
            placeholder={'Protein: 22 g\nEnergy: 343 kcal'}
          />
        </Field>
      </div>

      <div className="mt-4 rounded-xl border border-line bg-brand-soft/40 p-4">
        <div className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted">
          Image
        </div>
        <div className="flex items-center gap-4">
          <Thumb src={form.imageUrl} alt={form.name} />
          {isNew ? (
            <p className="text-xs text-muted">
              Save the product first, then add an image.
            </p>
          ) : (
            <div className="flex-1">
              <input
                type="file"
                accept="image/*"
                disabled={uploading}
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (file) onPickImage(file);
                  e.target.value = '';
                }}
                className="block w-full text-xs text-muted file:mr-3 file:rounded-full file:border-0 file:bg-brand file:px-3 file:py-1.5 file:text-xs file:font-semibold file:text-white hover:file:bg-brand-dark disabled:opacity-50"
              />
              {uploading && (
                <p className="mt-1 text-[11px] text-muted">Uploading…</p>
              )}
            </div>
          )}
        </div>
      </div>

      {!isNew && (
        <VariantsSection
          product={form}
          onChanged={(next) => {
            setForm((f) => ({ ...f, variants: next }));
            onRefresh();
          }}
          onError={setError}
        />
      )}

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

const emptyVariant: VariantInput = {
  label: '',
  price: 0,
  marketPrice: 0,
  stock: 0,
};

function VariantsSection({
  product,
  onChanged,
  onError,
}: {
  product: Product;
  onChanged: (next: ProductVariant[]) => void;
  onError: (msg: string) => void;
}) {
  const variants = product.variants;
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState<VariantInput>(emptyVariant);
  const [adding, setAdding] = useState<VariantInput>(emptyVariant);
  const [busy, setBusy] = useState(false);

  function replace(next: ProductVariant): ProductVariant[] {
    return variants.map((v) => (v.id === next.id ? next : v));
  }

  async function add() {
    if (!adding.label.trim()) return;
    setBusy(true);
    onError('');
    try {
      const created = await variantApi.create(product.id, {
        ...adding,
        price: Number(adding.price),
        marketPrice: Number(adding.marketPrice),
        stock: Number(adding.stock),
      });
      onChanged([...variants, created]);
      setAdding(emptyVariant);
    } catch (e) {
      onError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function saveEdit(vid: string) {
    setBusy(true);
    onError('');
    try {
      const updated = await variantApi.update(vid, {
        ...draft,
        price: Number(draft.price),
        marketPrice: Number(draft.marketPrice),
        stock: Number(draft.stock),
      });
      onChanged(replace(updated));
      setEditingId(null);
    } catch (e) {
      onError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(vid: string) {
    if (!confirm('Delete this variant?')) return;
    setBusy(true);
    onError('');
    try {
      await variantApi.remove(vid);
      onChanged(variants.filter((v) => v.id !== vid));
    } catch (e) {
      onError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mt-4 rounded-xl border border-line p-4">
      <div className="mb-3 text-xs font-semibold uppercase tracking-wide text-muted">
        Variants
      </div>

      {variants.length === 0 ? (
        <p className="mb-3 text-xs text-muted">No variants yet.</p>
      ) : (
        <div className="mb-3 space-y-2">
          {variants.map((v) =>
            editingId === v.id ? (
              <div
                key={v.id}
                className="grid grid-cols-[1.4fr_1fr_1fr_0.9fr_auto] items-center gap-2"
              >
                <Input
                  value={draft.label}
                  placeholder="Label"
                  onChange={(e) => setDraft({ ...draft, label: e.target.value })}
                />
                <Input
                  type="number"
                  value={draft.price}
                  onChange={(e) => setDraft({ ...draft, price: Number(e.target.value) })}
                />
                <Input
                  type="number"
                  value={draft.marketPrice}
                  onChange={(e) =>
                    setDraft({ ...draft, marketPrice: Number(e.target.value) })
                  }
                />
                <Input
                  type="number"
                  value={draft.stock}
                  onChange={(e) => setDraft({ ...draft, stock: Number(e.target.value) })}
                />
                <div className="flex gap-1 whitespace-nowrap">
                  <Button
                    className="px-2 py-1 text-xs"
                    disabled={busy}
                    onClick={() => saveEdit(v.id)}
                  >
                    Save
                  </Button>
                  <Button
                    variant="ghost"
                    className="px-2 py-1 text-xs"
                    onClick={() => setEditingId(null)}
                  >
                    Cancel
                  </Button>
                </div>
              </div>
            ) : (
              <div
                key={v.id}
                className="flex items-center justify-between gap-2 rounded-lg border border-line bg-white px-3 py-2 text-sm"
              >
                <div className="flex items-center gap-3">
                  <span className="font-semibold text-ink">{v.label}</span>
                  <span className="font-bold text-brand">₹{v.price}</span>
                  <span className="text-xs text-muted line-through">
                    ₹{v.marketPrice}
                  </span>
                  <span className="text-xs text-muted">stock {v.stock}</span>
                </div>
                <div className="flex gap-1 whitespace-nowrap">
                  <Button
                    variant="outline"
                    className="px-2 py-1 text-xs"
                    onClick={() => {
                      setEditingId(v.id);
                      setDraft({
                        label: v.label,
                        price: v.price,
                        marketPrice: v.marketPrice,
                        stock: v.stock,
                      });
                    }}
                  >
                    Edit
                  </Button>
                  <Button
                    variant="danger"
                    className="px-2 py-1 text-xs"
                    disabled={busy}
                    onClick={() => remove(v.id)}
                  >
                    Delete
                  </Button>
                </div>
              </div>
            ),
          )}
        </div>
      )}

      <div className="grid grid-cols-[1.4fr_1fr_1fr_0.9fr_auto] items-center gap-2">
        <Input
          value={adding.label}
          placeholder="Label"
          onChange={(e) => setAdding({ ...adding, label: e.target.value })}
        />
        <Input
          type="number"
          placeholder="Price"
          value={adding.price}
          onChange={(e) => setAdding({ ...adding, price: Number(e.target.value) })}
        />
        <Input
          type="number"
          placeholder="Market"
          value={adding.marketPrice}
          onChange={(e) =>
            setAdding({ ...adding, marketPrice: Number(e.target.value) })
          }
        />
        <Input
          type="number"
          placeholder="Stock"
          value={adding.stock}
          onChange={(e) => setAdding({ ...adding, stock: Number(e.target.value) })}
        />
        <Button
          className="px-3 py-1 text-xs whitespace-nowrap"
          disabled={busy || !adding.label.trim()}
          onClick={add}
        >
          Add variant
        </Button>
      </div>
    </div>
  );
}
