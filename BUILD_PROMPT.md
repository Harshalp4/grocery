# FarmFresh — Build Prompt

> Copy-paste this into an AI coding agent (or hand to a developer) to build the app.
> It is written to be self-contained. Fill in the three **[CHOOSE]** blocks first.

---

## [CHOOSE] Before you start, set these

- **BRAND_NAME:** `[CHOOSE — real name; "FarmFresh" is a placeholder]`
- **BUILD_TARGET:** `[CHOOSE — "website first" | "mobile first" | "website + backend together"]`
- **DATA_MODE:** `[CHOOSE — "real backend + Postgres" | "mock data first, real backend later"]`

---

## Context

You are building **{BRAND_NAME}**, a premium farm-to-home grocery delivery product for Mumbai,
Navi Mumbai and suburbs. Two clickable wireframes already exist in this repo and are the source of
truth for flow, layout, content and design:

- `mobile-wireframe.html` — 13-screen phone app prototype
- `website-wireframe.html` — 15-section responsive website prototype

Both are single-file HTML+CSS+vanilla-JS with **dummy data and placeholder prices**. Every real
integration point is already marked with an `API:` comment. Read both files fully before writing code.
Also read `PLAN.md` in this repo — it contains the architecture, data model, API contract and roadmap;
follow it.

## What to build

Turn the wireframes into a real application per `PLAN.md`. Preserve the wireframe's **design system
exactly**: earthy green `#2f6b46`, green-dark `#1f4a30`, beige `#f5efe3`, gold `#c9a24b`, ink `#26312b`,
rounded cards (radius 18px), pill buttons, and the same section structure. Keep dark mode (mobile).

## Stack (unless BUILD_TARGET/DATA_MODE dictate otherwise — see PLAN.md §2)

- **Web:** Next.js (App Router) + React + TypeScript + Tailwind (port the wireframe tokens to `tailwind.config`).
- **Backend:** Node/TypeScript route handlers → extract to Fastify/NestJS if it grows. Prisma + PostgreSQL.
- **Auth:** phone + OTP (MSG91). **Payments:** Razorpay (UPI/Card/COD). **AI:** Claude API server-side.
- **Mobile (later phase):** React Native (Expo), reusing shared `types` + `api-client`.
- If DATA_MODE is "mock data first": implement every endpoint in `PLAN.md §5` as a typed mock handler
  returning seed data lifted from the wireframe arrays, behind the same interface, so real handlers drop in later.

## Signature features — do not skip these (they define the product)

1. **Auto Kirana List** (flagship) — form (members, adults, children, budget, veg pref, cooking pattern)
   → `POST /kirana/generate` → a full monthly basket with quantities + estimated total → one-click "Add All to Cart".
   Start rule-based (budget-allocated across staples), then AI-enhance.
2. **AI Grocery Assistant** — chat UI → `POST /ai/plan {prompt}` → suggested cart + qty + health tips + total. Claude-backed.
3. **Combo Packs** — Family / Health / Festival tabs, fixed-price bundles (data in the wireframe).
4. **Subscriptions** — create / pause / edit monthly auto-delivery.
5. **Repeat Last Month** — `GET /orders/last` → prefilled reorder.
6. **WhatsApp order** (`wa.me` deep link) + **referrals / society group buy**.

## Data & seed

Use the exact dummy data already in the wireframes as seed data:
`CATS`, `PRODUCTS`, `FAMILY_PACKS`/`HEALTH_PACKS`/`FESTIVAL_PACKS`, `SUB_PLANS`, `KIRANA`, `REPEAT`.
Model per `PLAN.md §4`. Mark all prices as placeholder until real pricing is provided.

## API surface

Implement the endpoints in `PLAN.md §5` (auth, catalog, combos, kirana/ai, cart, coupons, orders,
subscriptions, referrals). Type request/response with shared TS types. Never expose AI/payment keys client-side.

## Build order

Follow the phased roadmap in `PLAN.md §6`:
Phase 0 foundation → Phase 1 website MVP → Phase 2 accounts/orders/payments → Phase 3 AI/growth →
Phase 4 mobile → Phase 5 admin. Ship each phase working before starting the next.

## Quality bar

- Fully responsive; matches wireframe layout at mobile and desktop breakpoints.
- Accessible (semantic HTML, keyboard nav, labelled inputs, color-contrast safe).
- Typed end-to-end (no `any` in domain code). Real loading/empty/error states, not just happy path.
- Every placeholder value clearly flagged in the UI until real content replaces it.
- Commit per phase with a working app at each step. Include a README with run instructions.

## Deliverables

1. Monorepo scaffold per `PLAN.md §3`.
2. Design system package (tokens + primitives: Button, Card, Tag, Chip, Modal, Input) matching the wireframe CSS.
3. Working web app for the chosen BUILD_TARGET, backed by real or mock API per DATA_MODE.
4. Prisma schema + seed script.
5. README: setup, env vars (OTP/payment/AI keys), run, and deploy instructions.

## First step

Before coding, restate: (a) the confirmed BRAND_NAME/BUILD_TARGET/DATA_MODE, (b) your monorepo layout,
(c) the Phase 1 task list. Then scaffold Phase 0 and stop for review.
```
