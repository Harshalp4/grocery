# FarmFresh — Gap Analysis (to a standard grocery-delivery app)

Benchmarked against Blinkit / Zepto / BigBasket-class apps. Organized per
application. **Delivery/rider app is the next phase** (tracked separately) — this
covers finishing the **customer-facing** product first.

Priority: **P0** = core purchase flow · **P1** = expected by users · **P2** = growth.

> **Scope decision:** **Payments (Razorpay)** and **Real SMS OTP** are intentionally
> **SKIPPED** for now. Everything else below is in scope.

---

## ✅ Already done (baseline)
- [x] Backend migrated to **.NET 10 + PostgreSQL** (EF Core Migrations)
- [x] Security fixes — server-side order totals, OTP throttling, admin-login throttle, constant-time compare
- [x] Placeholders/hardcoded values removed from the mobile app
- [x] **Coupons / offers** — backend + admin + app
- [x] Subscriptions hidden (admin + app)

---

## 📱 Mobile app (Flutter — customer)
- [x] **P0 — Cart quantity steppers** (−/+ per line, merge on add, qty-aware totals & orders)
- [x] **P0 — Persistent cart** — server-synced (load/merge on login, push on change) ✅ analyzer clean
- [x] **P0 — Real product search** (search + sort by name/price/discount)
- [~] **P0 — Push notifications** — inbox + order-status alerts done (analyzer clean); FCM *delivery* needs Firebase
- [x] **P1 — Write a review / rating** (star + text on product detail)
- [ ] **P1 — Reorder any past order** — *skipped per request*
- [x] **P1 — Help & Support** (FAQ, contact, raise/track tickets)
- [x] **P1 — Delete account** (profile → confirm → `DELETE /auth/me`)
- [x] **P1 — Notification inbox / center** (bell + badge on home, inbox screen)
- [x] **P1 — Favorites / wishlist** (❤️ toggle + wishlist screen)
- [ ] ~~Online payments (UPI/cards)~~ — **SKIPPED**
- [ ] P2 (deferred) — referrals · wallet/loyalty · map/GPS address · live rider map · sort options

## ⚙️ Backend (.NET API)
- [x] **P0 — Server-side cart** (`GET/POST/PATCH/DELETE /cart`, qty-aware, clears on order) ✅ tested
- [x] **P0 — Search / filter / sort / pagination** (q/category/tag/price/sort/limit, case-insensitive) ✅ tested
- [~] **P0 — Push (FCM)** device-token storage + send-on-status-change ✅ tested; real FCM delivery behind a seam (needs Firebase key)
- [x] **P1 — Customer review submission** (`POST /products/:id/reviews`) ✅ tested
- [x] **P1 — Account-deletion** endpoint (`DELETE /auth/me`, detaches orders) ✅ tested
- [x] **P1 — Notifications persistence** + endpoints (inbox, unread-count, read-all) ✅ tested
- [x] **P1 — Wishlist** endpoints (`GET/POST/DELETE /wishlist`) ✅ tested
- [x] **P1 — Support tickets** (`/support` + admin queue + reply→notify) ✅ tested
- [ ] ~~Payments (Razorpay) + webhook~~ — **SKIPPED**
- [ ] ~~Real SMS OTP (MSG91/Twilio)~~ — **SKIPPED**
- [ ] P2 (deferred) — loyalty/wallet · referrals · invoice generation

## 🖥️ Admin panel (Next.js)
- [ ] **P0 — Analytics & reporting** — *skipped per request (#7)*
- [x] **P1 — Notification / campaign sender** (broadcast page → fans out to all inboxes) ✅ compiles
- [x] **P1 — Homepage banner / promo management** (CMS + shown on app home) ✅ tested
- [x] **P1 — Low-stock alerts / inventory view** ✅ tested
- [x] **P1 — Support ticket queue** ✅ tested
- [x] **P1 — Admin roles & multi-user** (env superadmin + DB admin/staff, PBKDF2, 403 gating) ✅ tested
- [ ] P2 (deferred) — bulk product import/export · order invoice PDF · online-payment refunds

---

## Build order
1. Server-side cart + **quantity steppers** (foundational)
2. Product **search / filter / sort**
3. **Reviews write** · **wishlist** · **account deletion** (small, high-value)
4. **Notifications** (backend inbox + admin campaigns; FCM delivery when Firebase is ready)
5. **Support tickets** (app submit + admin queue)
6. **Admin analytics + CSV**, **banner CMS**, **low-stock view**, **admin roles**
7. → then the **delivery/rider app**.
