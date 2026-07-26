import type {
  Category,
  ComboPack,
  Product,
  ProductVariant,
  Review,
  SubscriptionPlan,
} from '@prisma/client';

type ProductWithVariants = Product & { variants?: ProductVariant[] };

function variantDto(v: ProductVariant) {
  return {
    id: v.id,
    label: v.label,
    price: v.price,
    marketPrice: v.marketPrice,
    stock: v.stock,
    inStock: v.stock > 0,
  };
}

/**
 * Convert DB rows into the JSON shapes the Flutter app expects (see the app's
 * `domain/entities`). Notably: `tags` becomes a string[] and `nutrition` a
 * parsed object, hiding SQLite's lack of array/JSON column types.
 */

export function productDto(p: ProductWithVariants) {
  const variants = (p.variants ?? [])
    .slice()
    .sort((a, b) => a.sortOrder - b.sortOrder)
    .map(variantDto);
  // A product with variants is "in stock" if any variant is; otherwise use its
  // own stock field.
  const inStock =
    variants.length > 0 ? variants.some((v) => v.inStock) : p.stock > 0;
  return {
    id: p.id,
    name: p.name,
    source: p.source,
    packedDate: p.packedDate,
    price: p.price,
    marketPrice: p.marketPrice,
    grade: p.grade,
    tags: p.tags ? p.tags.split(',').filter(Boolean) : [],
    harvestMonth: p.harvestMonth ?? null,
    packSize: p.packSize ?? null,
    nutrition: safeJson(p.nutrition),
    categorySlug: p.categorySlug,
    imageUrl: p.imageUrl ?? null,
    stock: p.stock,
    inStock,
    variants,
  };
}

export function categoryDto(c: Category) {
  return { id: c.id, slug: c.slug, name: c.name, emoji: c.emoji };
}

export function reviewDto(r: Review) {
  return {
    initials: r.initials,
    author: r.author,
    area: r.area,
    rating: r.rating,
    text: r.text,
  };
}

export function comboDto(c: ComboPack) {
  return {
    id: c.id,
    name: c.name,
    type: c.type,
    price: c.price,
    size: c.size,
    duration: c.duration,
    items: c.items,
    savingsNote: c.savingsNote,
  };
}

export function subscriptionDto(s: SubscriptionPlan) {
  return {
    id: s.id,
    name: s.name,
    description: s.description,
    priceLabel: s.priceLabel,
  };
}

function safeJson(s: string): Record<string, string> {
  try {
    const v = JSON.parse(s);
    return v && typeof v === 'object' ? v : {};
  } catch {
    return {};
  }
}
