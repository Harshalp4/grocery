import { Router } from 'express';
import { prisma } from '../prisma.js';
import {
  categoryDto,
  comboDto,
  productDto,
  reviewDto,
  subscriptionDto,
} from '../mappers.js';

export const catalogRouter = Router();

// GET /categories
catalogRouter.get('/categories', async (_req, res) => {
  const rows = await prisma.category.findMany({ orderBy: { sortOrder: 'asc' } });
  res.json(rows.map(categoryDto));
});

// GET /products?category=&tag=&q=
catalogRouter.get('/products', async (req, res) => {
  const { category, tag, q } = req.query as Record<string, string | undefined>;
  const rows = await prisma.product.findMany({
    where: {
      ...(category ? { categorySlug: category } : {}),
      ...(tag ? { tags: { contains: tag } } : {}),
      ...(q ? { name: { contains: q } } : {}),
    },
    include: { variants: true },
  });
  res.json(rows.map(productDto));
});

// GET /products/:id
catalogRouter.get('/products/:id', async (req, res) => {
  const row = await prisma.product.findUnique({
    where: { id: req.params.id },
    include: { variants: true },
  });
  if (!row) return res.status(404).json({ error: 'Product not found' });
  res.json(productDto(row));
});

// GET /products/:id/reviews
catalogRouter.get('/products/:id/reviews', async (req, res) => {
  const rows = await prisma.review.findMany({
    where: { productId: req.params.id },
  });
  res.json(rows.map(reviewDto));
});

// GET /combos?type=family|health|festival
catalogRouter.get('/combos', async (req, res) => {
  const type = (req.query.type as string | undefined) ?? 'family';
  const rows = await prisma.comboPack.findMany({ where: { type } });
  res.json(rows.map(comboDto));
});

// GET /subscriptions
catalogRouter.get('/subscriptions', async (_req, res) => {
  const rows = await prisma.subscriptionPlan.findMany();
  res.json(rows.map(subscriptionDto));
});
