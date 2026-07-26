import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import type { CustomerClaims } from '../customerAuth.js';
import { charge, type PaymentMethod } from '../payments.js';
import { prisma } from '../prisma.js';

export const ordersRouter = Router();

/** If a valid customer token is present, return its userId (else null). */
function optionalUserId(authHeader?: string): string | null {
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : '';
  if (!token) return null;
  try {
    const claims = jwt.verify(
      token,
      process.env.JWT_SECRET ?? 'dev-secret',
    ) as CustomerClaims;
    return claims.role === 'customer' ? claims.sub : null;
  } catch {
    return null;
  }
}

const OrderInput = z.object({
  customerName: z.string().min(1),
  phone: z.string().min(1),
  address: z.string().min(1),
  slot: z.string().min(1),
  paymentMethod: z.enum(['upi', 'card', 'cod']),
  items: z
    .array(
      z.object({
        name: z.string(),
        quantity: z.string().default(''),
        priceLabel: z.string().default(''),
        price: z.number().int().nonnegative().default(0),
        productId: z.string().nullish(),
        variantId: z.string().nullish(),
      }),
    )
    .min(1),
  itemTotal: z.number().int().nonnegative(),
  savings: z.number().int().nonnegative().default(0),
  deliveryFee: z.number().int().nonnegative().default(0),
  total: z.number().int().nonnegative(),
});

function orderCode(seq: number): string {
  const d = new Date();
  const ymd =
    d.getFullYear().toString() +
    String(d.getMonth() + 1).padStart(2, '0') +
    String(d.getDate()).padStart(2, '0');
  return `FF-${ymd}-${String(seq).padStart(4, '0')}`;
}

// POST /orders — guest checkout: create the order and settle payment.
ordersRouter.post('/orders', async (req, res) => {
  const parsed = OrderInput.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }
  const d = parsed.data;

  // Verify stock, then decrement, before creating the order. Count how many of
  // each product/variant this order needs (one line = one unit).
  const need = new Map<string, { variant: boolean; qty: number }>();
  for (const it of d.items) {
    if (it.variantId) {
      const k = `v:${it.variantId}`;
      need.set(k, { variant: true, qty: (need.get(k)?.qty ?? 0) + 1 });
    } else if (it.productId) {
      const k = `p:${it.productId}`;
      need.set(k, { variant: false, qty: (need.get(k)?.qty ?? 0) + 1 });
    }
  }
  for (const [key, { variant, qty }] of need) {
    const id = key.slice(2);
    const row = variant
      ? await prisma.productVariant.findUnique({ where: { id } })
      : await prisma.product.findUnique({ where: { id } });
    if (row && row.stock < qty) {
      return res
        .status(409)
        .json({ error: `Out of stock`, name: (row as { name?: string }).name });
    }
  }
  // Decrement (only for known ids; unknown/legacy items are left alone).
  for (const [key, { variant, qty }] of need) {
    const id = key.slice(2);
    if (variant) {
      await prisma.productVariant.updateMany({
        where: { id },
        data: { stock: { decrement: qty } },
      });
    } else {
      await prisma.product.updateMany({
        where: { id },
        data: { stock: { decrement: qty } },
      });
    }
  }

  const payment = await charge(d.paymentMethod as PaymentMethod, d.total);
  const seq = (await prisma.order.count()) + 1;
  const userId = optionalUserId(req.headers.authorization);

  const order = await prisma.order.create({
    data: {
      code: orderCode(seq),
      userId,
      customerName: d.customerName,
      phone: d.phone,
      address: d.address,
      slot: d.slot,
      itemTotal: d.itemTotal,
      savings: d.savings,
      deliveryFee: d.deliveryFee,
      total: d.total,
      paymentMethod: d.paymentMethod,
      paymentStatus: payment.status,
      paymentRef: payment.ref,
      status: 'placed',
      eta: `Delivery ${d.slot}`,
      items: { create: d.items },
      events: { create: { status: 'placed', note: 'Order placed' } },
    },
    include: { items: true },
  });

  res.status(201).json({
    id: order.id,
    code: order.code,
    status: order.status,
    paymentStatus: order.paymentStatus,
    total: order.total,
    slot: order.slot,
  });
});

// GET /orders/id/:id — fetch a single order (for the confirmation screen).
ordersRouter.get('/orders/id/:id', async (req, res) => {
  const order = await prisma.order.findUnique({
    where: { id: req.params.id },
    include: { items: true },
  });
  if (!order) return res.status(404).json({ error: 'Order not found' });
  res.json(order);
});
