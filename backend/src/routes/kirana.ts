import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../prisma.js';

export const kiranaRouter = Router();

const GenerateInput = z.object({
  members: z.union([z.string(), z.number()]).transform((v) => String(v)),
  adults: z.number().int().optional().default(2),
  children: z.number().int().optional().default(2),
  budget: z.number().int().nonnegative().default(4500),
  preference: z.string().default('Vegetarian'),
  usage: z.string().default('Regular cooking'),
});

/** Base monthly quantities for a family of ~4, scaled by household size. */
const BASE = [
  { name: 'Rice', unit: 'kg', qty: 10, rate: 54 },
  { name: 'Wheat Flour', unit: 'kg', qty: 15, rate: 51 },
  { name: 'Toor Dal', unit: 'kg', qty: 3, rate: 160 },
  { name: 'Chana Dal', unit: 'kg', qty: 2, rate: 130 },
  { name: 'Sugar', unit: 'kg', qty: 2, rate: 55 },
  { name: 'Tea', unit: 'kg', qty: 1, rate: 450 },
  { name: 'Oil', unit: 'L', qty: 5, rate: 230 },
];

function rupees(n: number) {
  return '₹' + n.toLocaleString('en-IN');
}

// POST /kirana/generate  -> { title, subtitle, lines[], estimatedTotal }
kiranaRouter.post('/kirana/generate', (req, res) => {
  const parsed = GenerateInput.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }
  const input = parsed.data;

  // Scale quantities to household size (family of 4 = baseline factor 1.0).
  const headcount = input.adults + input.children * 0.6;
  const factor = Math.max(0.5, headcount / 4);

  let lines = BASE.map((b) => {
    const qty = Math.max(1, Math.round(b.qty * factor));
    const cost = qty * b.rate;
    return {
      name: b.name,
      quantity: `${qty} ${b.unit}`,
      priceLabel: rupees(cost),
      cost,
    };
  });

  // Trim least-essential items if we blow the budget (keep the first staples).
  let total = lines.reduce((s, l) => s + l.cost, 0);
  while (total > input.budget * 1.05 && lines.length > 4) {
    const removed = lines.pop()!;
    total -= removed.cost;
  }

  const members = input.members;
  res.json({
    title: `Family of ${members} — Monthly Kirana`,
    subtitle: `${input.preference} · ${input.usage}`,
    lines: lines.map(({ name, quantity, priceLabel }) => ({
      name,
      quantity,
      priceLabel,
    })),
    estimatedTotal: total,
  });
});

// GET /orders/last  -> BasketLine[]  (Repeat Last Month)
kiranaRouter.get('/orders/last', async (_req, res) => {
  const rows = await prisma.basketLine.findMany({
    where: { list: 'repeat' },
    orderBy: { sortOrder: 'asc' },
  });
  res.json(
    rows.map((r) => ({
      name: r.name,
      quantity: r.quantity,
      priceLabel: r.priceLabel,
    })),
  );
});
