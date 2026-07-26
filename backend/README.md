# FarmFresh Backend API

TypeScript + Express + Prisma API serving the FarmFresh app's catalog, Auto
Kirana and AI-assistant data. SQLite for local dev (zero setup); switch the
Prisma datasource to PostgreSQL for production.

## Run

```bash
cd backend
npm install
npm run prisma:generate   # generate the Prisma client
npm run prisma:push       # create the SQLite schema (dev.db)
npm run seed              # load catalog data
npm run dev               # start on http://localhost:4000 (hot reload)
```

Production: `npm run build && npm start`.

## Endpoints (see PLAN.md §5)

| Method | Path | Purpose |
|---|---|---|
| GET  | `/health` | Health check |
| GET  | `/categories` | Category list |
| GET  | `/products?category=&tag=&q=` | Product catalog (filterable) |
| GET  | `/products/:id` | Single product |
| GET  | `/products/:id/reviews` | Product reviews |
| GET  | `/combos?type=family\|health\|festival` | Combo packs by type |
| GET  | `/subscriptions` | Subscription plans |
| POST | `/kirana/generate` | Auto Kirana basket (rule-based, budget-scaled) |
| GET  | `/orders/last` | Last month's basket (Repeat Last Month) |
| POST | `/ai/plan` | AI assistant reply (placeholder; swap in Claude API) |

Responses match the app's `domain/entities` shapes (e.g. product `tags` is a
string array, `nutrition` an object), so the Flutter remote data sources map 1:1.

## Architecture

```
prisma/schema.prisma   Data model (SQLite dev → Postgres prod)
prisma/seed.ts         Seed data (mirrors the app's former mock data)
src/prisma.ts          Shared Prisma client
src/mappers.ts         DB row → API DTO conversion
src/routes/*.ts        catalog / kirana / assistant route handlers
src/server.ts          Express app + wiring
```

## Connecting the Flutter app

The app's repository interfaces (`lib/domain/repositories`) get remote
implementations that call these endpoints; override the providers in the app's
`main.dart` to switch from mock to remote. Point the app at:
- iOS simulator: `http://localhost:4000`
- Android emulator: `http://10.0.2.2:4000`

## Next (not yet implemented)

Auth (OTP), cart persistence, orders/checkout, payments, real Claude-backed AI.
