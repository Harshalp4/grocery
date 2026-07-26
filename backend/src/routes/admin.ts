import { Router } from 'express';
import { z } from 'zod';
import { login, requireAdmin } from '../auth.js';
import {
  categoryDto,
  comboDto,
  productDto,
  reviewDto,
  subscriptionDto,
} from '../mappers.js';
import { prisma } from '../prisma.js';

export const adminRouter = Router();

// ---- Auth (public) --------------------------------------------------------
adminRouter.post('/admin/login', (req, res) => {
  const schema = z.object({ email: z.string(), password: z.string() });
  const parsed = schema.safeParse(req.body ?? {});
  if (!parsed.success) return res.status(400).json({ error: 'Bad request' });
  const token = login(parsed.data.email, parsed.data.password);
  if (!token) return res.status(401).json({ error: 'Invalid credentials' });
  res.json({ token });
});

// Everything below requires a valid admin token.
adminRouter.use('/admin', requireAdmin);

// ---- Dashboard stats ------------------------------------------------------
adminRouter.get('/admin/stats', async (_req, res) => {
  const [products, categories, combos, subscriptions, reviews, orders] =
    await Promise.all([
      prisma.product.count(),
      prisma.category.count(),
      prisma.comboPack.count(),
      prisma.subscriptionPlan.count(),
      prisma.review.count(),
      prisma.order.count(),
    ]);
  const revenueAgg = await prisma.order.aggregate({
    _sum: { total: true },
    where: { status: { not: 'cancelled' } },
  });
  const grades = await prisma.product.groupBy({
    by: ['grade'],
    _count: { _all: true },
  });
  const byCategory = await prisma.product.groupBy({
    by: ['categorySlug'],
    _count: { _all: true },
  });
  const priceAgg = await prisma.product.aggregate({
    _avg: { price: true },
    _min: { price: true },
    _max: { price: true },
  });
  res.json({
    counts: { products, categories, combos, subscriptions, reviews, orders },
    revenue: revenueAgg._sum.total ?? 0,
    byCategory: byCategory.map((g) => ({
      categorySlug: g.categorySlug,
      count: g._count._all,
    })),
    byGrade: grades.map((g) => ({ grade: g.grade, count: g._count._all })),
    price: {
      avg: Math.round(priceAgg._avg.price ?? 0),
      min: priceAgg._min.price ?? 0,
      max: priceAgg._max.price ?? 0,
    },
  });
});

// ---- Products -------------------------------------------------------------
const productSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  source: z.string().default(''),
  packedDate: z.string().default(''),
  price: z.number().int().nonnegative(),
  marketPrice: z.number().int().nonnegative(),
  grade: z.string().default(''),
  tags: z.array(z.string()).default([]),
  harvestMonth: z.string().nullish(),
  packSize: z.string().nullish(),
  nutrition: z.record(z.string()).default({}),
  categorySlug: z.string().min(1),
  stock: z.number().int().nonnegative().default(20),
  imageUrl: z.string().nullish(),
});

function productData(d: z.infer<typeof productSchema>) {
  return {
    id: d.id,
    name: d.name,
    source: d.source,
    packedDate: d.packedDate,
    price: d.price,
    marketPrice: d.marketPrice,
    grade: d.grade,
    tags: d.tags.join(','),
    harvestMonth: d.harvestMonth ?? null,
    packSize: d.packSize ?? null,
    nutrition: JSON.stringify(d.nutrition ?? {}),
    categorySlug: d.categorySlug,
    stock: d.stock,
    // imageUrl is managed separately via the image-upload endpoint so edits
    // here never wipe an uploaded photo.
  };
}

adminRouter.get('/admin/products', async (_req, res) => {
  const rows = await prisma.product.findMany({
    orderBy: { name: 'asc' },
    include: { variants: true },
  });
  res.json(rows.map(productDto));
});

adminRouter.post('/admin/products', async (req, res) => {
  const p = productSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    const row = await prisma.product.create({ data: productData(p.data) });
    res.status(201).json(productDto(row));
  } catch (e) {
    res.status(409).json({ error: 'Could not create (duplicate id?)' });
  }
});

adminRouter.put('/admin/products/:id', async (req, res) => {
  const p = productSchema.safeParse({ ...req.body, id: req.params.id });
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  const { id: _omit, ...data } = productData(p.data);
  try {
    const row = await prisma.product.update({
      where: { id: req.params.id },
      data,
    });
    res.json(productDto(row));
  } catch {
    res.status(404).json({ error: 'Product not found' });
  }
});

adminRouter.delete('/admin/products/:id', async (req, res) => {
  try {
    await prisma.review.deleteMany({ where: { productId: req.params.id } });
    await prisma.productVariant.deleteMany({
      where: { productId: req.params.id },
    });
    await prisma.product.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch {
    res.status(404).json({ error: 'Product not found' });
  }
});

// ---- Product variants -----------------------------------------------------
const variantSchema = z.object({
  label: z.string().min(1),
  price: z.number().int().nonnegative(),
  marketPrice: z.number().int().nonnegative().default(0),
  stock: z.number().int().nonnegative().default(20),
  sortOrder: z.number().int().default(0),
});

adminRouter.post('/admin/products/:id/variants', async (req, res) => {
  const p = variantSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  const product = await prisma.product.findUnique({
    where: { id: req.params.id },
  });
  if (!product) return res.status(404).json({ error: 'Product not found' });
  const row = await prisma.productVariant.create({
    data: { ...p.data, productId: req.params.id },
  });
  res.status(201).json(row);
});

adminRouter.put('/admin/variants/:vid', async (req, res) => {
  const p = variantSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    const row = await prisma.productVariant.update({
      where: { id: req.params.vid },
      data: p.data,
    });
    res.json(row);
  } catch {
    res.status(404).json({ error: 'Variant not found' });
  }
});

adminRouter.delete('/admin/variants/:vid', async (req, res) => {
  try {
    await prisma.productVariant.delete({ where: { id: req.params.vid } });
    res.json({ ok: true });
  } catch {
    res.status(404).json({ error: 'Variant not found' });
  }
});

// Quick stock adjust (product or a variant).
adminRouter.put('/admin/products/:id/stock', async (req, res) => {
  const p = z.object({ stock: z.number().int().nonnegative() })
    .safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: 'Bad stock' });
  try {
    await prisma.product.update({
      where: { id: req.params.id },
      data: { stock: p.data.stock },
    });
    res.json({ ok: true });
  } catch {
    res.status(404).json({ error: 'Product not found' });
  }
});

// ---- Product image upload (base64 data URL) -------------------------------
adminRouter.post('/admin/products/:id/image', async (req, res) => {
  const p = z.object({ dataUrl: z.string().min(1) }).safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: 'Missing image' });
  const match = /^data:image\/(png|jpe?g|webp);base64,(.+)$/.exec(p.data.dataUrl);
  if (!match) return res.status(400).json({ error: 'Unsupported image format' });
  const ext = match[1] === 'jpeg' ? 'jpg' : match[1];
  const buf = Buffer.from(match[2], 'base64');
  if (buf.length > 3_000_000) {
    return res.status(413).json({ error: 'Image too large (max ~3MB)' });
  }
  const { writeFileSync, mkdirSync } = await import('node:fs');
  mkdirSync('uploads', { recursive: true });
  const file = `${req.params.id}-${Date.now()}.${ext}`;
  writeFileSync(`uploads/${file}`, buf);
  const imageUrl = `/uploads/${file}`;
  try {
    await prisma.product.update({
      where: { id: req.params.id },
      data: { imageUrl },
    });
    res.json({ imageUrl });
  } catch {
    res.status(404).json({ error: 'Product not found' });
  }
});

// ---- Categories -----------------------------------------------------------
const categorySchema = z.object({
  slug: z.string().min(1),
  name: z.string().min(1),
  emoji: z.string().default(''),
  sortOrder: z.number().int().default(0),
});

adminRouter.get('/admin/categories', async (_req, res) => {
  const rows = await prisma.category.findMany({ orderBy: { sortOrder: 'asc' } });
  res.json(rows.map(categoryDto));
});

adminRouter.post('/admin/categories', async (req, res) => {
  const p = categorySchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    const row = await prisma.category.create({ data: p.data });
    res.status(201).json(categoryDto(row));
  } catch {
    res.status(409).json({ error: 'Slug already exists' });
  }
});

adminRouter.put('/admin/categories/:slug', async (req, res) => {
  const p = categorySchema.safeParse({ ...req.body, slug: req.params.slug });
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    const row = await prisma.category.update({
      where: { slug: req.params.slug },
      data: { name: p.data.name, emoji: p.data.emoji, sortOrder: p.data.sortOrder },
    });
    res.json(categoryDto(row));
  } catch {
    res.status(404).json({ error: 'Category not found' });
  }
});

adminRouter.delete('/admin/categories/:slug', async (req, res) => {
  const count = await prisma.product.count({
    where: { categorySlug: req.params.slug },
  });
  if (count > 0) {
    return res
      .status(409)
      .json({ error: `In use by ${count} product(s)` });
  }
  try {
    await prisma.category.delete({ where: { slug: req.params.slug } });
    res.json({ ok: true });
  } catch {
    res.status(404).json({ error: 'Category not found' });
  }
});

// ---- Combo packs ----------------------------------------------------------
const comboSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  type: z.enum(['family', 'health', 'festival']),
  price: z.number().int().nonnegative(),
  size: z.string().default(''),
  duration: z.string().default(''),
  items: z.string().default(''),
  savingsNote: z.string().default(''),
});

adminRouter.get('/admin/combos', async (_req, res) => {
  const rows = await prisma.comboPack.findMany({ orderBy: { price: 'asc' } });
  res.json(rows.map(comboDto));
});

adminRouter.post('/admin/combos', async (req, res) => {
  const p = comboSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    const row = await prisma.comboPack.create({ data: p.data });
    res.status(201).json(comboDto(row));
  } catch {
    res.status(409).json({ error: 'Duplicate id' });
  }
});

adminRouter.put('/admin/combos/:id', async (req, res) => {
  const p = comboSchema.safeParse({ ...req.body, id: req.params.id });
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  const { id: _omit, ...data } = p.data;
  try {
    const row = await prisma.comboPack.update({
      where: { id: req.params.id },
      data,
    });
    res.json(comboDto(row));
  } catch {
    res.status(404).json({ error: 'Combo not found' });
  }
});

adminRouter.delete('/admin/combos/:id', async (req, res) => {
  try {
    await prisma.comboPack.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch {
    res.status(404).json({ error: 'Combo not found' });
  }
});

// ---- Subscription plans ---------------------------------------------------
const subSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  description: z.string().default(''),
  priceLabel: z.string().default(''),
});

adminRouter.get('/admin/subscriptions', async (_req, res) => {
  const rows = await prisma.subscriptionPlan.findMany();
  res.json(rows.map(subscriptionDto));
});

adminRouter.post('/admin/subscriptions', async (req, res) => {
  const p = subSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    const row = await prisma.subscriptionPlan.create({ data: p.data });
    res.status(201).json(subscriptionDto(row));
  } catch {
    res.status(409).json({ error: 'Duplicate id' });
  }
});

adminRouter.put('/admin/subscriptions/:id', async (req, res) => {
  const p = subSchema.safeParse({ ...req.body, id: req.params.id });
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  const { id: _omit, ...data } = p.data;
  try {
    const row = await prisma.subscriptionPlan.update({
      where: { id: req.params.id },
      data,
    });
    res.json(subscriptionDto(row));
  } catch {
    res.status(404).json({ error: 'Plan not found' });
  }
});

adminRouter.delete('/admin/subscriptions/:id', async (req, res) => {
  try {
    await prisma.subscriptionPlan.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch {
    res.status(404).json({ error: 'Plan not found' });
  }
});

// ---- Reviews (moderation) -------------------------------------------------
adminRouter.get('/admin/reviews', async (_req, res) => {
  const rows = await prisma.review.findMany();
  const products = await prisma.product.findMany({
    select: { id: true, name: true },
  });
  const nameById = new Map(products.map((p) => [p.id, p.name]));
  res.json(
    rows.map((r) => ({
      id: r.id,
      productId: r.productId,
      productName: nameById.get(r.productId) ?? r.productId,
      ...reviewDto(r),
    })),
  );
});

adminRouter.delete('/admin/reviews/:id', async (req, res) => {
  try {
    await prisma.review.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch {
    res.status(404).json({ error: 'Review not found' });
  }
});

// ---- Orders ---------------------------------------------------------------
adminRouter.get('/admin/orders', async (_req, res) => {
  const rows = await prisma.order.findMany({
    orderBy: { createdAt: 'desc' },
    include: { items: true, deliveryPartner: true, returnRequest: true },
  });
  res.json(rows);
});

adminRouter.get('/admin/orders/:id', async (req, res) => {
  const order = await prisma.order.findUnique({
    where: { id: req.params.id },
    include: {
      items: true,
      events: { orderBy: { createdAt: 'asc' } },
      deliveryPartner: true,
      returnRequest: true,
    },
  });
  if (!order) return res.status(404).json({ error: 'Order not found' });
  res.json(order);
});

// Assign a delivery partner to an order.
adminRouter.put('/admin/orders/:id/assign', async (req, res) => {
  const p = z.object({ partnerId: z.string().nullable() }).safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: 'Bad request' });
  try {
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: { deliveryPartnerId: p.data.partnerId },
      include: { items: true, deliveryPartner: true },
    });
    res.json(order);
  } catch {
    res.status(404).json({ error: 'Order not found' });
  }
});

const ORDER_STATUSES = [
  'placed',
  'confirmed',
  'packed',
  'out_for_delivery',
  'delivered',
  'cancelled',
];
const PAYMENT_STATUSES = ['pending', 'paid', 'failed'];

adminRouter.put('/admin/orders/:id/status', async (req, res) => {
  const schema = z.object({
    status: z.enum(ORDER_STATUSES as [string, ...string[]]).optional(),
    paymentStatus: z
      .enum(PAYMENT_STATUSES as [string, ...string[]])
      .optional(),
  });
  const parsed = schema.safeParse(req.body ?? {});
  if (!parsed.success) return res.status(400).json({ error: 'Bad status' });
  try {
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: {
        ...parsed.data,
        // Log a timeline event whenever the fulfillment status changes.
        ...(parsed.data.status
          ? { events: { create: { status: parsed.data.status } } }
          : {}),
      },
      include: { items: true, events: { orderBy: { createdAt: 'asc' } } },
    });
    res.json(order);
  } catch {
    res.status(404).json({ error: 'Order not found' });
  }
});

// ---- Customers ------------------------------------------------------------
adminRouter.get('/admin/customers', async (_req, res) => {
  const users = await prisma.user.findMany({
    orderBy: { createdAt: 'desc' },
    include: {
      _count: { select: { orders: true, addresses: true } },
      orders: { select: { total: true, status: true } },
    },
  });
  res.json(
    users.map((u) => ({
      id: u.id,
      phone: u.phone,
      name: u.name,
      createdAt: u.createdAt,
      orderCount: u._count.orders,
      addressCount: u._count.addresses,
      totalSpend: u.orders
        .filter((o) => o.status !== 'cancelled')
        .reduce((s, o) => s + o.total, 0),
    })),
  );
});

adminRouter.get('/admin/customers/:id', async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.params.id },
    include: {
      addresses: true,
      orders: { orderBy: { createdAt: 'desc' }, include: { items: true } },
    },
  });
  if (!user) return res.status(404).json({ error: 'Customer not found' });
  res.json(user);
});

// ---- Delivery slots (CRUD) ------------------------------------------------
const slotSchema = z.object({
  label: z.string().min(1),
  active: z.boolean().default(true),
  sortOrder: z.number().int().default(0),
});

adminRouter.get('/admin/slots', async (_req, res) => {
  res.json(await prisma.deliverySlot.findMany({ orderBy: { sortOrder: 'asc' } }));
});
adminRouter.post('/admin/slots', async (req, res) => {
  const p = slotSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  res.status(201).json(await prisma.deliverySlot.create({ data: p.data }));
});
adminRouter.put('/admin/slots/:id', async (req, res) => {
  const p = slotSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    res.json(await prisma.deliverySlot.update({
      where: { id: req.params.id }, data: p.data,
    }));
  } catch { res.status(404).json({ error: 'Slot not found' }); }
});
adminRouter.delete('/admin/slots/:id', async (req, res) => {
  try {
    await prisma.deliverySlot.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch { res.status(404).json({ error: 'Slot not found' }); }
});

// ---- Serviceable areas (CRUD) ---------------------------------------------
const areaSchema = z.object({
  pincode: z.string().min(3),
  area: z.string().nullish(),
  city: z.string().nullish(),
  etaLabel: z.string().default('Next day'),
  active: z.boolean().default(true),
});

adminRouter.get('/admin/areas', async (_req, res) => {
  res.json(await prisma.serviceableArea.findMany({ orderBy: { pincode: 'asc' } }));
});
adminRouter.post('/admin/areas', async (req, res) => {
  const p = areaSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    res.status(201).json(await prisma.serviceableArea.create({ data: p.data }));
  } catch { res.status(409).json({ error: 'Pincode already added' }); }
});
adminRouter.put('/admin/areas/:id', async (req, res) => {
  const p = areaSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    res.json(await prisma.serviceableArea.update({
      where: { id: req.params.id }, data: p.data,
    }));
  } catch { res.status(404).json({ error: 'Area not found' }); }
});
adminRouter.delete('/admin/areas/:id', async (req, res) => {
  try {
    await prisma.serviceableArea.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch { res.status(404).json({ error: 'Area not found' }); }
});

// ---- Delivery partners (CRUD) ---------------------------------------------
const partnerSchema = z.object({
  name: z.string().min(1),
  phone: z.string().min(1),
  active: z.boolean().default(true),
});

adminRouter.get('/admin/partners', async (_req, res) => {
  res.json(await prisma.deliveryPartner.findMany({ orderBy: { name: 'asc' } }));
});
adminRouter.post('/admin/partners', async (req, res) => {
  const p = partnerSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  res.status(201).json(await prisma.deliveryPartner.create({ data: p.data }));
});
adminRouter.put('/admin/partners/:id', async (req, res) => {
  const p = partnerSchema.safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  try {
    res.json(await prisma.deliveryPartner.update({
      where: { id: req.params.id }, data: p.data,
    }));
  } catch { res.status(404).json({ error: 'Partner not found' }); }
});
adminRouter.delete('/admin/partners/:id', async (req, res) => {
  try {
    await prisma.deliveryPartner.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch { res.status(404).json({ error: 'Partner not found' }); }
});

// ---- Returns / refunds queue ----------------------------------------------
const RETURN_STATUSES = ['requested', 'approved', 'rejected', 'refunded'];

adminRouter.get('/admin/returns', async (_req, res) => {
  const rows = await prisma.returnRequest.findMany({
    orderBy: { createdAt: 'desc' },
    include: { order: { select: { code: true, customerName: true, total: true } } },
  });
  res.json(rows);
});

adminRouter.put('/admin/returns/:id', async (req, res) => {
  const p = z.object({
    status: z.enum(RETURN_STATUSES as [string, ...string[]]),
  }).safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: 'Bad status' });
  try {
    const rr = await prisma.returnRequest.update({
      where: { id: req.params.id },
      data: { status: p.data.status },
    });
    if (p.data.status === 'refunded') {
      await prisma.order.update({
        where: { id: rr.orderId },
        data: { paymentStatus: 'refunded' },
      });
    }
    res.json(rr);
  } catch { res.status(404).json({ error: 'Return not found' }); }
});
