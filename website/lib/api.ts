// Server-side catalog client for the FarmFresh marketing site. Fetches live data
// from the backend (NEXT_PUBLIC_API_BASE) with ISR caching, and falls back to
// curated static content when the API is unreachable — so the page never breaks.

export const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE ?? "http://localhost:4000";

// Revalidate live data every 5 minutes (ISR).
const REVALIDATE = 300;

export type Category = {
  id: string;
  slug: string;
  name: string;
  emoji: string;
};

export type Product = {
  id: string;
  name: string;
  source: string;
  price: number;
  marketPrice: number;
  grade: string;
  tags: string[];
  packSize?: string | null;
  categorySlug: string;
};

export type Combo = {
  id: string;
  name: string;
  type: string;
  price: number;
  size: string;
  duration: string;
  items: string;
  savingsNote: string;
};

export type Subscription = {
  id: string;
  name: string;
  description: string;
  priceLabel: string;
};

async function fetchJson<T>(path: string, fallback: T): Promise<T> {
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      next: { revalidate: REVALIDATE },
    });
    if (!res.ok) return fallback;
    return (await res.json()) as T;
  } catch {
    // Backend down / not deployed yet → curated static content.
    return fallback;
  }
}

export const getCategories = () =>
  fetchJson<Category[]>("/categories", FALLBACK_CATEGORIES);

export const getBestSellers = () =>
  fetchJson<Product[]>("/products?tag=bestseller", FALLBACK_PRODUCTS).then(
    (rows) => (rows.length ? rows : FALLBACK_PRODUCTS).slice(0, 6),
  );

export const getAllProducts = () =>
  fetchJson<Product[]>("/products", FALLBACK_PRODUCTS).then((rows) =>
    rows.length ? rows : FALLBACK_PRODUCTS,
  );

export const getCombos = () =>
  fetchJson<Combo[]>("/combos?type=family", FALLBACK_COMBOS).then((rows) =>
    rows.length ? rows : FALLBACK_COMBOS,
  );

export const getSubscriptions = () =>
  fetchJson<Subscription[]>("/subscriptions", FALLBACK_SUBSCRIPTIONS).then(
    (rows) => (rows.length ? rows : FALLBACK_SUBSCRIPTIONS),
  );

// ── Image mapping ─────────────────────────────────────────────────────────
// The catalog has no image column, so we map category slugs / product keywords
// to the real local photos in /public/images. Falls back to a produce basket.

const CATEGORY_IMAGES: Record<string, string> = {
  rice: "/images/cat-rice.jpg",
  "dal-pulses": "/images/cat-dal-pulses.jpg",
  "wheat-flour": "/images/cat-wheat-flour.jpg",
  "oils-ghee": "/images/cat-oils-ghee.jpg",
  spices: "/images/cat-spices.jpg",
  millets: "/images/cat-millets.jpg",
  "tea-coffee": "/images/cat-tea-coffee.jpg",
  "sugar-jaggery": "/images/cat-sugar-jaggery.jpg",
};

export function categoryImage(slug: string): string {
  return CATEGORY_IMAGES[slug] ?? "/images/produce-basket.jpg";
}

const PRODUCT_KEYWORD_IMAGES: [RegExp, string][] = [
  [/tomato/i, "/images/prod-tomatoes.jpg"],
  [/milk|dairy/i, "/images/prod-milk.jpg"],
  [/atta|flour|wheat/i, "/images/prod-atta.jpg"],
  [/apple|fruit/i, "/images/prod-apples.jpg"],
  [/paneer|cheese/i, "/images/prod-paneer.jpg"],
  [/honey|jaggery|sugar/i, "/images/prod-honey.jpg"],
  [/rice|basmati/i, "/images/cat-rice.jpg"],
  [/dal|pulse|lentil/i, "/images/cat-dal-pulses.jpg"],
  [/oil|ghee/i, "/images/cat-oils-ghee.jpg"],
  [/spice|masala/i, "/images/cat-spices.jpg"],
  [/millet/i, "/images/cat-millets.jpg"],
  [/tea|coffee/i, "/images/cat-tea-coffee.jpg"],
];

export function productImage(p: { name: string; categorySlug: string }): string {
  for (const [re, img] of PRODUCT_KEYWORD_IMAGES) {
    if (re.test(p.name)) return img;
  }
  return categoryImage(p.categorySlug);
}

// ── Static fallback content (used when the backend isn't reachable) ─────────

const FALLBACK_CATEGORIES: Category[] = [
  { id: "c1", slug: "rice", name: "Rice", emoji: "🍚" },
  { id: "c2", slug: "dal-pulses", name: "Dal & Pulses", emoji: "🫘" },
  { id: "c3", slug: "wheat-flour", name: "Wheat & Flour", emoji: "🌾" },
  { id: "c4", slug: "oils-ghee", name: "Oils & Ghee", emoji: "🛢️" },
  { id: "c5", slug: "spices", name: "Spices", emoji: "🌶️" },
  { id: "c6", slug: "millets", name: "Millets", emoji: "🌱" },
  { id: "c7", slug: "tea-coffee", name: "Tea & Coffee", emoji: "☕" },
  { id: "c8", slug: "sugar-jaggery", name: "Sugar & Jaggery", emoji: "🍯" },
];

const FALLBACK_PRODUCTS: Product[] = [
  {
    id: "p1",
    name: "Sona Masoori Rice",
    source: "Raichur, Karnataka",
    price: 82,
    marketPrice: 98,
    grade: "Premium",
    tags: ["bestseller"],
    packSize: "1 kg",
    categorySlug: "rice",
  },
  {
    id: "p2",
    name: "Organic Toor Dal",
    source: "Latur, Maharashtra",
    price: 148,
    marketPrice: 170,
    grade: "A-grade",
    tags: ["bestseller"],
    packSize: "1 kg",
    categorySlug: "dal-pulses",
  },
  {
    id: "p3",
    name: "Chakki Fresh Atta",
    source: "Nashik Mills",
    price: 62,
    marketPrice: 75,
    grade: "Whole wheat",
    tags: ["bestseller"],
    packSize: "1 kg",
    categorySlug: "wheat-flour",
  },
  {
    id: "p4",
    name: "Wood-Pressed Groundnut Oil",
    source: "Kolhapur",
    price: 320,
    marketPrice: 380,
    grade: "Cold-pressed",
    tags: ["bestseller"],
    packSize: "1 L",
    categorySlug: "oils-ghee",
  },
  {
    id: "p5",
    name: "Farm-Fresh Paneer",
    source: "Anand, Gujarat",
    price: 90,
    marketPrice: 110,
    grade: "Full cream",
    tags: ["bestseller"],
    packSize: "200 g",
    categorySlug: "dairy",
  },
  {
    id: "p6",
    name: "Raw Forest Honey",
    source: "Sahyadri Hills",
    price: 240,
    marketPrice: 300,
    grade: "Unprocessed",
    tags: ["bestseller"],
    packSize: "500 g",
    categorySlug: "sugar-jaggery",
  },
];

const FALLBACK_COMBOS: Combo[] = [
  {
    id: "k1",
    name: "Family of 4 — Monthly Kirana",
    type: "family",
    price: 2499,
    size: "18 items",
    duration: "1 month",
    items: "Rice, atta, 3 dals, 5 spices, oil, tea, sugar & more",
    savingsNote: "Save ₹420 vs buying separately",
  },
  {
    id: "k2",
    name: "Newlywed Starter Kit",
    type: "family",
    price: 1499,
    size: "12 items",
    duration: "1 month",
    items: "Compact essentials for a two-person kitchen",
    savingsNote: "Save ₹260",
  },
  {
    id: "k3",
    name: "Healthy Millet Box",
    type: "family",
    price: 999,
    size: "8 items",
    duration: "1 month",
    items: "Foxtail, ragi, jowar, bajra & millet flours",
    savingsNote: "Save ₹180",
  },
];

const FALLBACK_SUBSCRIPTIONS: Subscription[] = [
  {
    id: "s1",
    name: "Daily Milk & Bread",
    description: "Fresh dairy and bakery at your door every morning.",
    priceLabel: "from ₹68/day",
  },
  {
    id: "s2",
    name: "Weekly Fruits & Veggies",
    description: "A seasonal basket of farm produce, every week.",
    priceLabel: "from ₹499/week",
  },
  {
    id: "s3",
    name: "Monthly Kirana Refill",
    description: "Your staples auto-replenished, delivered monthly.",
    priceLabel: "from ₹2,499/month",
  },
];
