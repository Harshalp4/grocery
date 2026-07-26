import { Router } from 'express';
import { z } from 'zod';
import {
  generateOtp,
  OTP_DEV_MODE,
  requireCustomer,
  sendSms,
  signCustomerToken,
  type CustomerClaims,
} from '../customerAuth.js';
import { prisma } from '../prisma.js';

export const authRouter = Router();

const OTP_TTL_MS = 5 * 60 * 1000;

const phoneSchema = z
  .string()
  .min(8)
  .max(15)
  .transform((s) => s.replace(/[^0-9]/g, ''));

// POST /auth/otp/request { phone } -> { sent, retryIn, devOtp? }
authRouter.post('/auth/otp/request', async (req, res) => {
  const parsed = z.object({ phone: phoneSchema }).safeParse(req.body ?? {});
  if (!parsed.success) return res.status(400).json({ error: 'Invalid phone' });
  const { phone } = parsed.data;

  const code = generateOtp();
  const expiresAt = new Date(Date.now() + OTP_TTL_MS);

  // Invalidate previous unconsumed codes, then store the new one.
  await prisma.otpCode.updateMany({
    where: { phone, consumed: false },
    data: { consumed: true },
  });
  await prisma.otpCode.create({ data: { phone, code, expiresAt } });
  await sendSms(phone, code);

  res.json({
    sent: true,
    retryIn: 30,
    // Dev only — remove when real SMS is wired.
    ...(OTP_DEV_MODE ? { devOtp: code } : {}),
  });
});

// POST /auth/otp/verify { phone, code, name? } -> { token, user }
authRouter.post('/auth/otp/verify', async (req, res) => {
  const parsed = z
    .object({
      phone: phoneSchema,
      code: z.string().min(4).max(6),
      name: z.string().optional(),
    })
    .safeParse(req.body ?? {});
  if (!parsed.success) return res.status(400).json({ error: 'Bad request' });
  const { phone, code, name } = parsed.data;

  const otp = await prisma.otpCode.findFirst({
    where: { phone, code, consumed: false, expiresAt: { gt: new Date() } },
    orderBy: { createdAt: 'desc' },
  });
  if (!otp) {
    return res.status(401).json({ error: 'Invalid or expired code' });
  }
  await prisma.otpCode.update({
    where: { id: otp.id },
    data: { consumed: true },
  });

  const user = await prisma.user.upsert({
    where: { phone },
    update: name ? { name } : {},
    create: { phone, name: name ?? null },
  });

  const token = signCustomerToken(user.id, user.phone);
  res.json({ token, user: { id: user.id, phone: user.phone, name: user.name } });
});

// GET /auth/me -> current user
authRouter.get('/auth/me', requireCustomer, async (req, res) => {
  const claims = (req as { customer?: CustomerClaims }).customer!;
  const user = await prisma.user.findUnique({ where: { id: claims.sub } });
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ id: user.id, phone: user.phone, name: user.name });
});

// PUT /auth/me -> update the signed-in user's profile (name)
authRouter.put('/auth/me', requireCustomer, async (req, res) => {
  const claims = (req as { customer?: CustomerClaims }).customer!;
  const parsed = z.object({ name: z.string().max(60) }).safeParse(req.body ?? {});
  if (!parsed.success) return res.status(400).json({ error: 'Bad request' });
  const user = await prisma.user.update({
    where: { id: claims.sub },
    data: { name: parsed.data.name },
  });
  res.json({ id: user.id, phone: user.phone, name: user.name });
});

// GET /auth/orders -> the signed-in user's order history
authRouter.get('/auth/orders', requireCustomer, async (req, res) => {
  const claims = (req as { customer?: CustomerClaims }).customer!;
  const orders = await prisma.order.findMany({
    where: { userId: claims.sub },
    orderBy: { createdAt: 'desc' },
    include: { items: true, returnRequest: true },
  });
  res.json(orders);
});

// GET /auth/orders/:id -> one order with its tracking timeline
authRouter.get('/auth/orders/:id', requireCustomer, async (req, res) => {
  const claims = (req as { customer?: CustomerClaims }).customer!;
  const order = await prisma.order.findFirst({
    where: { id: req.params.id, userId: claims.sub },
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

// POST /auth/orders/:id/cancel -> customer cancels (only before dispatch)
const CANCELLABLE = ['placed', 'confirmed'];
authRouter.post('/auth/orders/:id/cancel', requireCustomer, async (req, res) => {
  const claims = (req as { customer?: CustomerClaims }).customer!;
  const order = await prisma.order.findFirst({
    where: { id: req.params.id, userId: claims.sub },
  });
  if (!order) return res.status(404).json({ error: 'Order not found' });
  if (!CANCELLABLE.includes(order.status)) {
    return res
      .status(409)
      .json({ error: 'This order can no longer be cancelled' });
  }
  const updated = await prisma.order.update({
    where: { id: order.id },
    data: {
      status: 'cancelled',
      events: { create: { status: 'cancelled', note: 'Cancelled by customer' } },
    },
    include: { items: true, events: { orderBy: { createdAt: 'asc' } } },
  });
  res.json(updated);
});

// POST /auth/orders/:id/return -> report an issue / request a return
authRouter.post('/auth/orders/:id/return', requireCustomer, async (req, res) => {
  const claims = (req as { customer?: CustomerClaims }).customer!;
  const parsed = z.object({ reason: z.string().min(3) }).safeParse(req.body ?? {});
  if (!parsed.success) return res.status(400).json({ error: 'Reason required' });
  const order = await prisma.order.findFirst({
    where: { id: req.params.id, userId: claims.sub },
    include: { returnRequest: true },
  });
  if (!order) return res.status(404).json({ error: 'Order not found' });
  if (order.returnRequest) {
    return res.status(409).json({ error: 'A request already exists for this order' });
  }
  const rr = await prisma.returnRequest.create({
    data: { orderId: order.id, userId: claims.sub, reason: parsed.data.reason },
  });
  res.status(201).json(rr);
});
