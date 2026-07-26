# FarmFresh — Build Plan

> Premium farm-to-home grocery delivery for Mumbai / Navi Mumbai / suburbs.
> This plan turns the two clickable wireframes (`mobile-wireframe.html`, `website-wireframe.html`)
> into a real, production-shaped application.

---

## 1. Product summary

**What it is:** An own-label grocery brand selling staples (rice, dals, flour, oils/ghee, spices,
millets, tea/coffee, sugar/jaggery) direct-to-home. The differentiator is **transparency**
(source, packing date, quality grade, lab reports, QR trace) + **fair pricing vs. market** +
**smart monthly planning**.

**Signature features (the reason this isn't a generic grocery clone):**

| Feature | What it does |
|---|---|
| 🧾 **Auto Kirana List** | Enter family size, budget, veg preference, cooking pattern → auto-builds a full monthly basket, one-click add to cart. **Flagship.** |
| 🤖 **AI Grocery Assistant** | Chat that plans monthly kirana / health baskets / budget-fit baskets. |
| 📦 **Combo Packs** | Fixed-price bundles: Family (Bachelor→Large), Health (fitness/diabetic/weight-loss/high-protein), Festival (Ganpati/Diwali/Gudi Padwa/Upvas). |
| ⭐ **Subscriptions** | Auto monthly delivery, editable, pausable. |
| 🔁 **Repeat Last Month** | One-tap reorder of last basket. |
| 💬 **WhatsApp order + 🏢 Society group buy / referrals** | Low-friction ordering + community bulk discounts. |

---

## 2. Recommended stack & why

The wireframes are framework-free single files. For a real product serving both **web** and
**mobile** with a shared backend, the recommendation is a **single TypeScript monorepo**:

| Layer | Choice | Why |
|---|---|---|
| **Web app** | **Next.js (App Router) + React + TypeScript** | SEO matters for a marketing/e-commerce site (the website wireframe is content-heavy). SSR + fast product pages. |
| **Styling** | **Tailwind CSS** with the wireframe's design tokens ported to `tailwind.config` | The wireframe already defines a clean token set (green/beige/gold). Tailwind maps 1:1. |
| **Mobile app** | **React Native (Expo)** — Phase 2 | Shares TypeScript types, business logic, and API client with web. (Flutter is a valid alternative per the wireframe README, but RN keeps one language across the stack.) |
| **Backend** | **Node + TypeScript** — Next.js API routes / route handlers to start; extract to a standalone **NestJS or Fastify** service if it grows | Same language as frontend; the API surface is small at first. |
| **Database** | **PostgreSQL** + **Prisma ORM** | Relational data (users, products, orders, subscriptions) fits SQL. Prisma gives typed queries + migrations. |
| **Auth** | **OTP via SMS** (Twilio / MSG91 — MSG91 is India-friendly) | Wireframe login is phone + OTP. |
| **Payments** | **Razorpay** (UPI/cards/COD, India-first) | Wireframe checkout lists UPI/Card/COD. |
| **AI** | **Claude API** (`claude-sonnet-5` for planning, cheaper tier for simple prompts) | Powers Auto Kirana generation + AI Assistant. See `POST /ai/plan`, `POST /kirana/generate`. |
| **WhatsApp** | `wa.me` deep links first; **WhatsApp Business API** later | Wireframe uses `wa.me/<number>?text=<list>`. |
| **Hosting** | **Vercel** (web) + **managed Postgres** (Neon/Supabase/RDS) | Zero-config Next.js deploys. |

> If you prefer to stay lean and skip a real backend initially, everything below still holds —
> just back the API contracts with mock handlers and swap in real ones later. The wireframes
> already mark every integration point with `API:` comments.

---

## 3. Architecture

```
apps/
  web/            Next.js website + customer web app (Phase 1)
  mobile/         React Native (Expo) app            (Phase 2)
packages/
  ui/             Shared design system (tokens, components)
  api-client/     Typed client for the backend
  types/          Shared TS types (Product, Order, KiranaPlan, ...)
services/
  api/            Backend (route handlers → NestJS/Fastify if extracted)
  db/             Prisma schema + migrations + seed
```

**Request flow:** Client → API client → Backend route → Prisma → Postgres. AI features call the
Claude API server-side (never expose keys to the client). Payments go client → Razorpay →
server webhook confirms order.

---

## 4. Data model (from the wireframe's dummy data)

The wireframe's `PRODUCTS`, `PACKS`, `KIRANA`, `SUBS`, `REPEAT` arrays map directly to tables:

```
User(id, phone, name, addresses[], createdAt)
Address(id, userId, label, line, area, city, pincode, isDefault)

Category(id, emoji, name, slug)
Product(id, name, categorySlug, source, packedDate, harvestMonth,
        price, marketPrice, grade, packSize, nutrition{}, labReportUrl,
        traceQr, tags[best|fresh|premium], images[])

ComboPack(id, name, type[family|health|festival], price, size, duration,
          items[], savingsNote)

CartItem(id, userId, productId|comboPackId, qty)
Order(id, userId, items[], addressId, slot, paymentMethod, status,
      itemTotal, savings, deliveryFee, total, placedAt)

Subscription(id, userId, planName, cartSnapshot, cadence, status[active|paused], nextDelivery)
KiranaPlan(id, userId, inputs{members,adults,children,budget,pref,usage},
           generatedItems[], estTotal, savedAt)
Review(id, productId, userId, rating, text, area)
Coupon(code, type, value, minOrder, expiresAt)
Referral(id, userId, code, rewards)
```

---

## 5. API contract (extracted from `API:` comments + implied endpoints)

**Auth**
- `POST /auth/otp/request` `{ phone }` → `{ sent: true, retryIn }`
- `POST /auth/otp/verify` `{ phone, otp }` → `{ token, user }`

**Catalog**
- `GET /categories`
- `GET /products?category=&tag=&priceMin=&priceMax=&packSize=&q=`
- `GET /products/:id`
- `GET /products/:id/reviews`

**Combos & plans**
- `GET /combos?type=family|health|festival`
- `POST /kirana/generate` `{ members, adults, children, budget, pref, usage }` → `{ items[], estTotal }`
- `POST /ai/plan` `{ prompt }` → `{ cart[], qty, healthTips[], estTotal }`

**Cart & orders**
- `GET/POST/PATCH/DELETE /cart`
- `POST /coupons/apply` `{ code, cartTotal }` → `{ discount }`
- `POST /orders` `{ items, addressId, slot, payment }` → `{ orderId, status }`
- `GET /orders/last` → last basket (for Repeat Last Month)
- `GET /orders` / `GET /orders/:id`

**Subscriptions**
- `GET/POST /subscriptions`, `PATCH /subscriptions/:id` (pause/edit)

**Other**
- `POST /referrals` , `GET /referrals`
- WhatsApp: build `wa.me/<number>?text=<encoded list>` client-side (no server call).

---

## 6. Phased roadmap

**Phase 0 — Foundation (setup)**
- Monorepo, TypeScript, lint/format, CI.
- Port design tokens → Tailwind config. Build shared UI primitives (Button, Card, Tag, Chip, Modal, Input) from the wireframe CSS.
- Prisma schema + seed data lifted from the wireframe arrays.

**Phase 1 — Website MVP (customer-facing web app)**
- Public marketing sections (hero, trust, categories, farm-to-home, quality, testimonials, footer) — static/SSR.
- Real product catalog (list, filter, detail with nutrition/reviews).
- Cart + coupon + checkout skeleton (address, slot, payment method selection).
- Auto Kirana form → real `POST /kirana/generate` (rule-based first, AI-enhanced next).

**Phase 2 — Accounts, orders, payments**
- Phone+OTP auth, addresses, order placement, Razorpay integration, order history, Repeat Last Month.
- Subscriptions (create/pause/edit).

**Phase 3 — AI + growth features**
- AI Grocery Assistant (Claude-backed), smarter Auto Kirana.
- WhatsApp ordering, referrals, society group buy.

**Phase 4 — Mobile app (React Native / Expo)**
- Reuse types, api-client, and business logic; rebuild the 13 screens natively.

**Phase 5 — Ops & admin**
- Admin panel (products, orders, inventory, delivery slots), analytics, notifications.

---

## 7. Screen/section → build mapping

**Mobile (13 screens):** Splash · Login(OTP) · Home · Auto Kirana · Combo Packs · Product Listing ·
Product Detail · Cart · Checkout · Subscriptions · Repeat Last Month · AI Assistant · Profile
+ 6-tab bottom nav, modals, dark mode.

**Website (15 sections):** Header/nav · Hero · Trust bar · Categories · Auto Kirana · Combo Packs ·
Products · Farm-to-Home timeline · Quality/Transparency · AI Planner · Subscriptions · Testimonials ·
Referrals/Group Buy · WhatsApp band · Footer.

Each wireframe `.screen` / `<section>` → one route/page. Each `.card` → one component.
`showScreen()`/`openModal()` → router + dialog. The wireframe README already documents this mapping.

---

## 8. Open decisions (to confirm before Phase 1)

1. **Build order** — website first, mobile first, or backend first? (Recommend: website + backend together.)
2. **Stack confirmation** — accept the Next.js + Postgres recommendation, or a different one (Flutter, etc.)?
3. **Real backend now vs. mock data** — production foundation, or UI-first with mocks?
4. **Real brand name** — "FarmFresh" is a placeholder throughout; pick the real name early so it's not a rename later.
5. **Launch geography & catalog** — confirm delivery zones and the real starting product list/prices.
6. **Payments/SMS providers** — Razorpay + MSG91 assumed; confirm accounts.
```
