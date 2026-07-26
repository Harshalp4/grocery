# CLAUDE.md — FarmFresh project guide

Context for Claude Code (and developers) working in this repo. See `README.md`
for full setup and `FEATURE_ROADMAP.md` for what's built vs. planned.

## What this is
A grocery/kirana delivery product built from `mobile-wireframe.html` /
`website-wireframe.html`. Three apps share one backend + Postgres DB:

- `farmfresh/` — Flutter customer app (Riverpod + go_router, clean architecture).
- `backend/` — Express + Prisma + PostgreSQL API (the single source of truth).
- `admin/` — Next.js 16 admin panel (catalog + ops management).
- `website/` — Next.js marketing site (optional).

## Run (details in README.md)
```
# backend  (:4000)   cp .env.example .env; npm i; npx prisma generate; npx prisma db push; npm run seed; npm run dev
# admin    (:3000)   cp .env.local.example .env.local; npm i; npm run dev
# app                flutter pub get; flutter run
```
Admin login: `ADMIN_EMAIL`/`ADMIN_PASSWORD` in `backend/.env`.

## Architecture conventions
**Flutter app** — clean layered:
- `domain/` entities + repository interfaces (no Flutter/HTTP deps).
- `data/` remote (HTTP) + mock repository implementations + `ApiClient`.
- `presentation/` feature screens + Riverpod providers.
- Remote repos are activated in `main.dart` via provider overrides; `ApiConfig.useRemote`
  (default true) toggles mock vs. real API. Base URL: localhost (iOS) / 10.0.2.2 (Android).
- Auth token held in `AuthToken` (static), attached by `ApiClient`, persisted via shared_preferences.
- Catalog uses `FutureProvider`s that cache — refresh via pull-to-refresh and on app resume
  (`presentation/providers/refresh.dart`, `app.dart`).

**Backend** — `src/routes/*.ts` mounted in `src/server.ts`. `src/env.ts` loads `.env`
FIRST (before any module reads `process.env`, so JWT secret is stable across restarts).
Admin routes under `/admin/*` require a JWT (`src/auth.ts`); customer routes use
`src/customerAuth.ts` (`requireCustomer`). Prisma schema in `prisma/schema.prisma`;
`prisma/seed.ts` reproduces the full demo state. Product images in `uploads/` (served static).

## What's wired end-to-end
Catalog (categories/products/images/stock/variants/reviews/combos/subscriptions),
OTP auth, addresses, delivery slots + serviceability, orders (COD) with stock
decrement, order tracking timeline + delivery partner, cancel/returns, customers.
Admin manages all of it; changes sync to the app.

## Known placeholders / not-yet-real
- No real SMS (OTP returned in API response; `OTP_DEV_MODE=true`).
- COD only (Razorpay stubbed).
- Brand name "FarmFresh", some prices/copy, cart starter items, home "best sellers"
  slicing, "★ 4.7" rating are placeholders.
- Not built yet: coupons, push notifications, support, analytics depth, product variants
  in cart quantity steppers. See `FEATURE_ROADMAP.md`.

## Gotchas
- Only ONE backend server on :4000; if data looks stale, confirm Postgres is up and the
  API/DB agree.
- macOS may clear the Postgres socket in /tmp — if `pg_ctl status` lies (stale pid), remove
  `postmaster.pid` and restart.
- `admin/` is Next.js 16 (newer than some training data) — check `admin/AGENTS.md`.
