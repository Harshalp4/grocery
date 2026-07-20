import { Router } from 'express';
import { prisma } from '../prisma.js';

export const serviceableRouter = Router();

// GET /serviceable?pincode=400703 -> { serviceable, etaLabel?, area? }
// If no serviceable areas are configured at all, treat everywhere as
// serviceable (so the app isn't blocked before areas are set up).
serviceableRouter.get('/serviceable', async (req, res) => {
  const pincode = String(req.query.pincode ?? '').replace(/[^0-9]/g, '');
  const total = await prisma.serviceableArea.count({ where: { active: true } });
  if (total === 0) {
    return res.json({ serviceable: true, etaLabel: 'Next day', configured: false });
  }
  if (!pincode) return res.json({ serviceable: false, configured: true });
  const area = await prisma.serviceableArea.findFirst({
    where: { pincode, active: true },
  });
  res.json({
    serviceable: !!area,
    etaLabel: area?.etaLabel ?? null,
    area: area?.area ?? null,
    configured: true,
  });
});
