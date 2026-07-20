# FarmFresh — Marketing Website

A polished, responsive marketing/landing site for **FarmFresh**, a farm-to-home
premium grocery delivery service in **Mumbai & Navi Mumbai**. Built with
**Next.js 16 (App Router) + TypeScript + Tailwind CSS v4** — the same stack as the
`admin/` panel, so it deploys to Vercel the same way.

Design reference: [firstclub.site](https://www.firstclub.site/) (structure/quality bar
only — brand, copy and layout are original FarmFresh).

## Features
- **Live catalog** — categories, best-sellers and combo packs are fetched from the
  FarmFresh backend (`NEXT_PUBLIC_API_BASE`) with ISR (5-min revalidate). If the
  backend is down or not deployed yet, the page **falls back to curated static
  content**, so it never breaks.
- **Real imagery** — all photos are real, license-safe images stored locally in
  `public/images/` (Unsplash for hero/section shots, keyword-sourced grocery photos
  for category tiles). No broken hotlinks, no placeholders.
- Brand tokens shared with the app + admin (green `#2f6b46`, gold `#c9a24b`,
  beige `#f5efe3`), Fraunces + Inter fonts via `next/font`.
- Responsive (mobile-first), semantic HTML, SEO + Open Graph metadata,
  `prefers-reduced-motion` respected.

## Pages
- `/` — landing page (all sections below)
- `/categories` — browse all categories (live)
- `/products` — best sellers / full product grid (live)
- `/subscriptions` — subscription plans + combo packs (live)
- `/how-it-works` — farm-to-home journey, quality comparison, FAQ
- `/about` — story, values, stats
- `/contact` — contact channels + enquiry form (demo submit, no backend)

Header nav and footer links resolve to these routes; the on-page `#download`
anchor is referenced as `/#download` so it works from any page.

## Sections (landing page)
Header (sticky, mobile menu) · Hero · value banner (marquee) · Categories (live) ·
Farm-to-Home journey · Quality & Transparency comparison · Best Sellers (live) ·
Two service models · AI Grocery Planner teaser · Combo Packs (live) · Testimonials ·
Referrals & Society Group Buy · App download CTA (badges + QR + phone mockup) · Footer.

## Run locally
```bash
# from grocery/website
export PATH="$HOME/node/bin:$PATH"     # if node isn't already on PATH
npm install
cp .env.example .env.local             # then edit NEXT_PUBLIC_API_BASE if needed
npm run dev                            # http://localhost:3000
```
> If port 3000 is taken by another project, run `npm run dev -- -p 3005`.

To see **live** catalog data, start the backend first (`cd ../backend && npm run dev`,
serves `http://localhost:4000`). Without it, the site renders the static fallback.

## Production build
```bash
npm run build
npm run start
```

## Deploy to Vercel (free)
1. Import the repo → **Root Directory: `website`**. Vercel auto-detects Next.js 16.
2. Add env var **`NEXT_PUBLIC_API_BASE`** = your deployed backend URL
   (e.g. `https://farmfresh-api.onrender.com`, no trailing slash).
3. Deploy → e.g. `https://farmfresh.vercel.app`.

## Configuration
| Env var | Purpose | Default |
|---|---|---|
| `NEXT_PUBLIC_API_BASE` | FarmFresh backend base URL | `http://localhost:4000` |

## Structure
```
website/
├── app/
│   ├── layout.tsx        # fonts, metadata, <html>
│   ├── page.tsx          # assembles all sections (server component, fetches data)
│   └── globals.css       # brand tokens + Tailwind v4
├── components/           # Header, Hero, Categories, BestSellers, Combos, …
├── lib/api.ts            # catalog client + static fallback + image mapping
└── public/images/        # real local photos
```

## Swapping images
Images map by category slug / product keyword in `lib/api.ts`
(`categoryImage`, `productImage`). Drop a new file in `public/images/` and point the
map at it. To add a live image column later, extend the backend `productDto` with an
`imageUrl` and read it here instead of the keyword map.
