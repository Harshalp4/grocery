# FarmFresh Admin

Branded admin panel (Next.js 16 App Router + React 19 + Tailwind v4) for managing
the FarmFresh catalog. Talks to the backend admin API with JWT auth.

## Run

The backend must be running first (see `../backend`). Then:

```bash
cd admin
npm install
npm run dev        # http://localhost:3000
```

Config: `NEXT_PUBLIC_API_BASE` in `.env.local` (defaults to `http://localhost:4000`).

Login with the admin credentials from the backend `.env`
(`ADMIN_EMAIL` / `ADMIN_PASSWORD`; dev default `admin@farmfresh.local` / `farmfresh123`).

## Features

- **Login** — JWT stored in localStorage; auth guard redirects unauthenticated users.
- **Dashboard** — live counts, products-by-category chart, price stats, grade breakdown.
- **Products / Categories / Combo Packs / Subscriptions** — full create / edit / delete.
- **Reviews** — moderation (view + delete).

Edits flow straight through to the database and are immediately visible in the
customer app (which reads the same backend). Verified end-to-end.

## Structure

```
app/
  login/page.tsx           Login screen
  (admin)/                 Protected area (wrapped by AppShell)
    layout.tsx             Sidebar shell + auth guard
    page.tsx               Dashboard
    products/ categories/ combos/ subscriptions/ reviews/   CRUD screens
components/
  AppShell.tsx             Sidebar + auth guard
  ui.tsx                   Button, Card, Table, Modal, Field, Badge, …
lib/
  api.ts                   Fetch client + token handling
  resources.ts             Typed CRUD wrappers per resource
  types.ts                 Shared types
```

## Production notes

Dev auth is a single env-based admin. For production: bcrypt-hash the password,
use a long random `JWT_SECRET`, add admin users/roles, serve over HTTPS, and set
`NEXT_PUBLIC_API_BASE` to the deployed API. Build with `npm run build && npm start`.
