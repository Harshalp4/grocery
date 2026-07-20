import { Router } from 'express';
import { z } from 'zod';

export const assistantRouter = Router();

const AskInput = z.object({ prompt: z.string().min(1) });

/**
 * POST /ai/plan  -> { reply }
 *
 * Placeholder assistant. Returns a helpful templated basket suggestion. To make
 * this a real AI planner, call the Claude API here (server-side, key in env)
 * and return the model's plan — the response shape stays the same.
 */
assistantRouter.post('/ai/plan', (req, res) => {
  const parsed = AskInput.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'prompt is required' });
  }
  const prompt = parsed.data.prompt.toLowerCase();

  const highProtein = /protein|fitness|gym|muscle/.test(prompt);
  const budget = /budget|cheap|₹|rupee|save/.test(prompt);

  const cart = highProtein
    ? 'Soya 1kg · Rajma 2kg · Chana 2kg · Moong 3kg · Peanut 1kg'
    : 'Rice 10kg · Atta 15kg · Toor Dal 3kg · Oil 5L · Tea 1kg';
  const tip = highProtein
    ? 'add sprouts and paneer for extra protein 💪'
    : 'add millets twice a week for fibre 🌱';
  const total = budget ? '₹4,980*' : '₹4,250*';

  const reply =
    "Here's a suggested basket 👇\n\n" +
    `Suggested cart\n${cart}\n\n` +
    'Est. monthly qty: ~34 kg / 5 L\n' +
    `Health tip: ${tip}\n` +
    `Est. total: ${total} (placeholder)`;

  res.json({ reply });
});
