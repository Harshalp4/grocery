# FarmFresh — Feature Roadmap (to a standard grocery app)

Plan to close the gaps vs. a standard grocery app (Blinkit / Zepto / BigBasket
class). **Online payments are intentionally excluded** (COD only for now).

Each item is one **deliverable spanning all three layers** — backend (data +
API), admin panel, and the Flutter app — so nothing ships half-wired.

Effort: **S** ≈ ½–1 day · **M** ≈ 1–2 days · **L** ≈ 3+ days / needs external setup.

---

## Phase 1 — Catalog depth ("real store" feel)  ← highest visible impact
The catalog is the product. These three transform it from "prototype" to "store".

### 1.1 Product images  · M
- **Backend:** `imageUrl` (and optional `images[]`) on Product; upload endpoint
  `POST /admin/products/:id/image` storing to disk + static serving in dev
  (swap to S3/Cloudinary for prod); return public URLs.
- **Admin:** image upload + preview in the product form; thumbnails in the list.
- **App:** show real images in ProductCard, detail, cart (replace the gradient
  `ImagePlaceholder`), with a graceful fallback.

### 1.2 Inventory / stock  · M
- **Backend:** `stock` (int) on Product; **atomically decrement on order**; reject
  / clamp when insufficient; derive `inStock`; stock-adjust endpoints.
- **Admin:** stock column + quick-edit; low-stock badge/filter; out-of-stock toggle.
- **App:** "Out of stock" / "Only N left" badges; disable **Add** at 0;
  deprioritize sold-out items.

### 1.3 Variants / pack sizes  · L
- **Backend:** `ProductVariant` model (label, packSize, price, marketPrice, stock)
  per Product; order items + cart reference a variant; catalog returns variants.
- **Admin:** manage variants per product (add/edit/delete; price + stock each).
- **App:** variant selector on card/detail; cart holds the chosen variant; price
  updates live.
- *Note:* biggest schema change here — touches cart + orders. Do **after** 1.1/1.2.

---

## Phase 2 — Customers & fulfillment ops

### 2.1 Customers in admin  · S
- **Backend:** `GET /admin/customers` (users + order count / total spend);
  `GET /admin/customers/:id` (detail + their orders + addresses).
- **Admin:** Customers screen (list, search, detail). *(Admin has none today.)*
- **App:** profile edit (name) — minor.

### 2.2 Delivery slots & serviceable areas  · M
- **Backend:** admin CRUD for `DeliverySlot`; `ServiceableArea` model
  (pincode/zone, active); `GET /serviceable?pincode=` check.
- **Admin:** slot management screen; serviceable-areas screen.
- **App:** set delivery location / pincode; serviceability check at address &
  checkout ("we don't deliver here yet"); delivery-ETA text.

### 2.3 Order tracking & delivery (lite)  · M
- **Backend:** status history with timestamps; `DeliveryPartner` model + assign to
  order; `eta` field.
- **Admin:** assign delivery partner; status timeline on the order.
- **App:** order-detail **status timeline** + ETA text.
- *Note:* full live GPS map + rider app is a separate **L+** effort — this scopes
  to a timeline + ETA now.

### 2.4 Cancel + Returns / refunds  · M
- **Backend:** customer cancel (eligible states); `ReturnRequest` + refund status
  on order; admin refund actions.
- **Admin:** returns/refunds queue (approve / reject / mark refunded).
- **App:** cancel button (eligible states); "report an issue" on delivered orders
  → creates a return request.

---

## Phase 3 — Engagement & growth

### 3.1 Coupons / offers  · M
- **Backend:** `Coupon` model (code, %/flat, value, minOrder, maxDiscount, valid
  window, usage + per-user limits); `POST /coupons/validate` applies the rules;
  store applied coupon on the order; **server-computed savings**.
- **Admin:** coupon manager (CRUD + usage stats).
- **App:** real coupon apply in cart (validate, show discount, show errors).

### 3.2 Notifications (push)  · L (external setup)
- **Backend:** FCM integration; store device tokens per user; send on status
  changes; campaign/broadcast endpoint.
- **Admin:** send campaign; per-event templates.
- **App:** FCM setup, permission prompt, token registration, handle taps, in-app
  notification center.
- *Note:* needs a Firebase project + platform config; real push only on real
  devices (simulator support is limited).

### 3.3 Support  · S–M
- **Backend:** `SupportTicket` model + endpoints (or WhatsApp deep-link + FAQ
  content).
- **Admin:** ticket queue.
- **App:** Help center (FAQ), contact (WhatsApp / call), order-level "need help?".

---

## Phase 4 — Analytics & reporting (admin)  · M
- **Backend:** aggregates — sales over time, top products, category mix, order
  funnel, new vs returning customers, AOV; date-range filters; CSV export.
- **Admin:** analytics dashboards + export buttons (today's dashboard is basic).

---

## Cross-cutting infrastructure (enablers)
- **File/image storage:** local disk (dev) → S3 / Cloudinary (prod). *(unlocks 1.1)*
- **Push:** Firebase Cloud Messaging project + configs. *(unlocks 3.2)*
- **Real SMS** for OTP (MSG91/Twilio) — already scoped separately.

## Suggested order
1 (images → stock → variants) → 2.1 customers → 2.2 slots/areas → 2.3 tracking →
2.4 cancel/returns → 3.1 coupons → 3.3 support → 4 analytics → 3.2 push (needs FCM).

Rationale: Phase 1 has the biggest "feels real" payoff and everything downstream
(cart, orders, offers) depends on a correct catalog (stock/variants). Push is
last because it needs external Firebase setup.
