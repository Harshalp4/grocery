import { Router } from 'express';
import { prisma } from '../prisma.js';

export const slotsRouter = Router();

// GET /slots -> active delivery slots (used by the checkout screen)
slotsRouter.get('/slots', async (_req, res) => {
  const rows = await prisma.deliverySlot.findMany({
    where: { active: true },
    orderBy: { sortOrder: 'asc' },
  });
  res.json(rows.map((s) => ({ id: s.id, label: s.label })));
});
