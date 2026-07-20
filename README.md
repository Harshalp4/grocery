# FarmFresh — Grocery Delivery App

A full grocery/kirana delivery product, built from the wireframes in this repo:

| App | Path | Stack |
|---|---|---|
| **Customer app** | `farmfresh/` | Flutter (Riverpod, go_router), clean architecture |
| **Backend API** | `backend/` | Node + TypeScript + Express + Prisma + PostgreSQL |
| **Admin panel** | `admin/` | Next.js 16 + React 19 + Tailwind v4 |
| **Marketing site** | `website/` | Next.js (optional) |

The app runs on the live backend; the admin panel manages the catalog, orders,
customers, delivery and returns; changes sync to the app.

Original wireframes: `mobile-wireframe.html`, `website-wireframe.html`.
Docs: [`PLAN.md`](PLAN.md) (architecture), [`FEATURE_ROADMAP.md`](FEATURE_ROADMAP.md) (what's built / what's next), [`CLAUDE.md`](CLAUDE.md) (project overview).

---

## Prerequisites

- **Node.js** 20+ (project developed on 24 LTS)
- **PostgreSQL** 14+ (running locally)
- **Flutter** 3.3+ (Dart 3.4+) with a device/emulator (iOS Simulator, Android emulator, or Chrome)
- For iOS: Xcode + CocoaPods · For Android: Android SDK + a JDK 17

## 1. Database

Create the database and a user (defaults match `backend/.env.example`):

```bash
createdb farmfresh          # or: psql -c "CREATE DATABASE farmfresh;"
# ensure a role that matches your DATABASE_URL exists (e.g. postgres/postgres)
```

## 2. Backend API  →  http://localhost:4000

```bash
cd backend
cp .env.example .env          # then edit DATABASE_URL / secrets
npm install
npx prisma generate
npx prisma db push            # creates all tables
npm run seed                  # loads catalog, images, stock, variants, slots, areas, partners
npm run dev                   # starts the API (hot reload)
```

Product images ship in `backend/uploads/` and are served at `/uploads/...`.

## 3. Admin panel  →  http://localhost:3000

```bash
cd admin
cp .env.local.example .env.local
npm install
npm run dev
```

Log in with `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `backend/.env`
(default `admin@farmfresh.local` / `farmfresh123`).

## 4. Customer app

```bash
cd farmfresh
flutter pub get
flutter run                   # pick a device
```

The app auto-targets the backend: `http://localhost:4000` on iOS/desktop,
`http://10.0.2.2:4000` on Android emulators. Override with a deployed API:

```bash
flutter run --dart-define=API_BASE=https://api.yourdomain.com
```

To build a release APK: `flutter build apk --release`.

---

## Login / test flow

1. App → **Get Started** → enter a name + any 10-digit number → **Send OTP**.
2. In dev the OTP is returned by the API and auto-filled — tap **Continue**.
3. Shop → add to cart (some products have pack-size variants) → **Cart → Checkout**
   → pick a saved address + delivery slot → **Place Order** (Cash on Delivery).
4. **Profile → My Orders** shows it with a tracking timeline; the **admin Orders**
   screen can advance status / assign a delivery partner, which the app reflects.

## Notes & current limitations (dev state)

- **Auth:** real phone+OTP, but **no SMS is sent** — the OTP comes back in the API
  response (`OTP_DEV_MODE=true`). Wire MSG91/Twilio in `backend/src/customerAuth.ts`.
- **Payments:** **Cash on Delivery only**. Razorpay is stubbed (env-ready).
- **HTTP in dev:** the app talks to the backend over HTTP — iOS `Info.plist` has
  `NSAllowsLocalNetworking` and Android has `usesCleartextTraffic`. Use HTTPS in prod.
- **Brand/content:** "FarmFresh", prices and some copy are still placeholders.
- Roadmap of remaining features (coupons, notifications, etc.) in `FEATURE_ROADMAP.md`.

## Ports
`4000` backend · `3000` admin · `5432` Postgres (default) · Flutter picks the device.
