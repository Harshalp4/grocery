import './env.js'; // MUST be first — loads .env before any module reads it.
import cors from 'cors';
import express from 'express';
import { addressesRouter } from './routes/addresses.js';
import { adminRouter } from './routes/admin.js';
import { assistantRouter } from './routes/assistant.js';
import { authRouter } from './routes/auth.js';
import { slotsRouter } from './routes/slots.js';
import { catalogRouter } from './routes/catalog.js';
import { kiranaRouter } from './routes/kirana.js';
import { ordersRouter } from './routes/orders.js';
import { serviceableRouter } from './routes/serviceable.js';

// Safety net: don't let a transient error (e.g. a DB blip) crash the process.
process.on('unhandledRejection', (e) => console.error('[unhandledRejection]', e));
process.on('uncaughtException', (e) => console.error('[uncaughtException]', e));

const app = express();
app.use(cors());
app.use(express.json({ limit: '5mb' })); // room for base64 image uploads

// Uploaded product images.
app.use('/uploads', express.static('uploads'));

// Health check
app.get('/health', (_req, res) => res.json({ ok: true, service: 'farmfresh' }));

// API routes (see PLAN.md §5)
app.use(authRouter);
app.use(addressesRouter);
app.use(slotsRouter);
app.use(serviceableRouter);
app.use(catalogRouter);
app.use(kiranaRouter);
app.use(assistantRouter);
app.use(ordersRouter);
app.use(adminRouter);

// 404
app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

const port = Number(process.env.PORT ?? 4000);
app.listen(port, () => {
  console.log(`FarmFresh API listening on http://localhost:${port}`);
});
