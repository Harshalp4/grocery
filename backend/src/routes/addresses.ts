import { Router } from 'express';
import { z } from 'zod';
import { requireCustomer, type CustomerClaims } from '../customerAuth.js';
import { prisma } from '../prisma.js';

export const addressesRouter = Router();

// All address routes require a signed-in customer.
addressesRouter.use('/addresses', requireCustomer);

function userId(req: unknown): string {
  return (req as { customer?: CustomerClaims }).customer!.sub;
}

const addressSchema = z.object({
  label: z.string().default('Home'),
  line: z.string().min(3),
  area: z.string().nullish(),
  city: z.string().nullish(),
  pincode: z.string().nullish(),
  isDefault: z.boolean().default(false),
});

// GET /addresses -> the user's saved addresses (default first)
addressesRouter.get('/addresses', async (req, res) => {
  const rows = await prisma.address.findMany({
    where: { userId: userId(req) },
    orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
  });
  res.json(rows);
});

// POST /addresses -> add a new address
addressesRouter.post('/addresses', async (req, res) => {
  const p = addressSchema.safeParse(req.body ?? {});
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  const uid = userId(req);

  const count = await prisma.address.count({ where: { userId: uid } });
  const makeDefault = p.data.isDefault || count === 0; // first one is default
  if (makeDefault) {
    await prisma.address.updateMany({
      where: { userId: uid },
      data: { isDefault: false },
    });
  }
  const row = await prisma.address.create({
    data: { ...p.data, isDefault: makeDefault, userId: uid },
  });
  res.status(201).json(row);
});

// PUT /addresses/:id -> edit
addressesRouter.put('/addresses/:id', async (req, res) => {
  const p = addressSchema.safeParse(req.body ?? {});
  if (!p.success) return res.status(400).json({ error: p.error.flatten() });
  const uid = userId(req);
  const existing = await prisma.address.findFirst({
    where: { id: req.params.id, userId: uid },
  });
  if (!existing) return res.status(404).json({ error: 'Address not found' });
  if (p.data.isDefault) {
    await prisma.address.updateMany({
      where: { userId: uid },
      data: { isDefault: false },
    });
  }
  const row = await prisma.address.update({
    where: { id: req.params.id },
    data: p.data,
  });
  res.json(row);
});

// DELETE /addresses/:id
addressesRouter.delete('/addresses/:id', async (req, res) => {
  const uid = userId(req);
  const existing = await prisma.address.findFirst({
    where: { id: req.params.id, userId: uid },
  });
  if (!existing) return res.status(404).json({ error: 'Address not found' });
  await prisma.address.delete({ where: { id: req.params.id } });
  res.json({ ok: true });
});
