# FarmFresh — Delivery Partner (Rider) App — Build Plan

> The fourth app in the FarmFresh product: a **rider app** used by delivery partners to
> pick up, navigate to, and complete assigned orders.

**Hard rule throughout:** no self-registration, no signup screen, no partner-facing
"forgot password". The backend exposes **no** partner-registration endpoint — accounts
exist only via `POST /admin/partners` behind the admin JWT. Password resets go through ops.

**Confirmed decisions:** phone + admin-issued password (forced change on first login) ·
V1 = core fulfilment **+ live GPS tracking**.

---

## 1. You're not starting from zero

| Already exists | Where |
|---|---|
| `DeliveryPartner` entity (`id, name, phone, active`) | `backend-dotnet/Models/Entities.cs:251` |
| Partner CRUD API (`GET/POST/PUT/DELETE /admin/partners`) | `backend-dotnet/Controllers/AdminController.cs` (Delivery-partners section, ~605-660) |
| Admin partner UI | `admin/app/(admin)/partners/page.tsx` |
| Order → partner assignment (`PUT /admin/orders/{id}/assign`) | `AdminController.cs:430` |
| Order status machine + `OrderEvent` timeline | `AdminController.cs:443` (`OrderStatuses[]`) |
| Notification fan-out (inbox rows + FCM **stub**) | `backend-dotnet/Services/Notify.cs:46` |
| **PBKDF2 password hasher (`Passwords.Hash`/`Verify`) — reuse for partner creds** | `backend-dotnet/Services/Passwords.cs` |
| **Customer `DeviceToken` FCM table — `PartnerDevice` mirrors it** | `Models/Entities.cs:182` |
| **Role-based auth: `Admin`/`Customer` policies + admin sub-roles (`adminRole`) + DB `AdminUser`** | `Program.cs:50-51`, `Auth/JwtService.cs`, `AdminController.cs` |
| JWT tokens `admin` (12h) + `customer` (30d) | `Auth/JwtService.cs` |
| Login rate limiter | `Services/RateLimiter.cs` |
| Flutter conventions (Riverpod + go_router + `ApiClient` + static `AuthToken`) | `farmfresh/lib` |

The work is: **add credentials + a third `partner` JWT role, a partner-scoped API, GPS,
and a second Flutter app on the same conventions.** Password hashing and device-token
storage patterns already exist and are reused, not built from scratch.

---

## 2. Architecture decision — a separate Flutter app at `partner/`

Not a "rider mode" inside `farmfresh/`:

- Different audience → separate Play/App Store listing, icon, brand voice.
- The rider app needs **background location**; adding that to the customer app forces a
  store-review justification on every customer install.
- The rider app has zero catalog/cart code; the customer app has zero delivery code.
- Shared surface is small (theme, `ApiClient`, buttons/cards ≈ 8 files) — copy for v1,
  extract to a `packages/ff_core` Flutter package only if drift becomes a real problem.

```
grocery-main/
  backend-dotnet/     ← shared API, gains /partner/* endpoints
  admin/              ← gains credential issuance + live map
  farmfresh/          ← customer app, gains live-tracking map
  partner/            ← NEW rider app
```

---

## 3. Data model changes

### 3.1 `DeliveryPartner` — extend (`Models/Entities.cs`)

```csharp
public class DeliveryPartner
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Phone { get; set; }               // login identifier (unique, digits-only)
    public bool   Active { get; set; }              // false ⇒ cannot log in, tokens revoked

    // --- credentials (admin-issued) ---
    public string  PasswordHash { get; set; }       // "pbkdf2$<iters>$<salt-b64>$<hash-b64>"
    public bool    MustChangePassword { get; set; } // true after create / admin reset
    public int     TokenVersion { get; set; }       // bump ⇒ all existing JWTs invalid
    public DateTime? LastLoginAt { get; set; }

    // --- profile ---
    public string? VehicleType   { get; set; }      // bike | scooter | ev | cycle | van
    public string? VehicleNumber { get; set; }
    public string? Zone          { get; set; }      // optional: pincode / area cluster

    // --- live state ---
    public bool      OnDuty { get; set; }
    public double?   LastLat { get; set; }
    public double?   LastLng { get; set; }
    public DateTime? LastLocationAt { get; set; }

    public DateTime CreatedAt { get; set; }
    public List<Order> Orders { get; set; }
}
```
Index: `Phone` unique.

### 3.2 New entities

```csharp
// Rider FCM token — mirrors the customer DeviceToken table.
public class PartnerDevice   { Id, PartnerId, Token (unique), Platform, CreatedAt }

// Location breadcrumbs. Written only while on-duty with an active order.
// Purged after 7 days (see §8).
public class PartnerLocation { Id, PartnerId, OrderId?, Lat, Lng,
                               Accuracy?, Speed?, Heading?, RecordedAt }
```
Indexes: `PartnerLocation(PartnerId, RecordedAt)`, `PartnerLocation(OrderId)`.

### 3.3 `Order` — extend

```csharp
public DateTime? AssignedAt  { get; set; }
public DateTime? PickedUpAt  { get; set; }
public DateTime? DeliveredAt { get; set; }

public string?   DeliveryOtp       { get; set; }  // 4-digit, minted at out_for_delivery
public DateTime? DeliveryOtpSentAt { get; set; }
public string?   ProofPhotoUrl     { get; set; }  // /uploads/proof/<orderId>-<rand>.jpg
public string?   DeliveryNote      { get; set; }  // rider's free-text note
public int       CodCollected      { get; set; }  // ₹ handed over by the customer
public string?   FailureReason     { get; set; }

public double?   DestLat { get; set; }            // snapshot of the address coords
public double?   DestLng { get; set; }
```

### 3.4 `Address` — extend
`public double? Lat; public double? Lng;` — nullable. When absent the rider app navigates
by **address string query**, so navigation works from day one and coordinates are a
progressive enhancement.

### 3.5 Order status machine — two new states

```
placed → confirmed → packed → picked_up → out_for_delivery → delivered
                                  ↘ failed ↗ (re-assign / retry)
   ↘ cancelled (any pre-dispatch state)
```

| New status | Set by | Meaning |
|---|---|---|
| `picked_up` | rider | Parcel collected from the hub; not yet moving to the customer |
| `failed` | rider | Attempted but undelivered (nobody home / refused / wrong address) — returns to the admin queue |

**Grep-verified (re-checked against current code): 6 files hardcode the status list and must all change.**
- `backend-dotnet/Controllers/AdminController.cs:443` — `OrderStatuses[]`
- `backend-dotnet/Controllers/AdminController.cs:475` — `StatusMessage()` customer copy
- `admin/lib/types.ts:76` — `OrderStatus` union
- `admin/app/(admin)/orders/page.tsx:8` — `STATUSES` list (drives the dropdown + labels)
- `farmfresh/lib/domain/entities/customer_order.dart:3` — `orderStatusLabel()` map
- `farmfresh/lib/presentation/features/orders/order_detail_page.dart:18` — timeline steps

### 3.6 Migration
One EF migration, `PartnerAuthAndTracking` — auto-applied on boot, since `Program.cs:69`
already calls `db.Database.Migrate()`. Existing partner rows get a random hash +
`MustChangePassword = true` and show in the admin panel as
**"No credentials — reset password to issue"**.

---

## 4. Authentication design

### 4.1 The third JWT role
```csharp
public string SignPartnerToken(string partnerId, string phone, int tokenVersion)
  // claims: sub=partnerId, phone, role="partner", tv=<tokenVersion>   TTL 7d
```
`Program.cs` gains `options.AddPolicy("Partner", p => p.RequireClaim("role", "partner"));`

### 4.2 Token revocation (the `tv` claim)
Every `/partner/*` request re-loads the partner and rejects if
`partner == null || !partner.Active || partner.TokenVersion != tv`.
Implemented once as `[Authorize(Policy="Partner")]` + a `PartnerActionFilter`
(or a `PartnerControllerBase.LoadPartner()` helper).

`TokenVersion++` on: admin deactivate · admin password reset · partner password change ·
"log out of all devices". This is how ops **instantly kills access** for a departed rider.

### 4.3 Password handling
- **Hash:** a PBKDF2-HMAC-SHA256 hasher **already exists** — `Services/Passwords.cs`
  (`Passwords.Hash`/`Verify`: 100 000 iters, 16-byte salt, 32-byte key, format
  `<salt-b64>.<hash-b64>`, verified with `CryptographicOperations.FixedTimeEquals`), added
  for the admin-users feature. **Reuse it directly** for partner credentials (optionally
  bump to 210 000 iters). `System.Security.Cryptography`; **no new NuGet package**.
- **Temp password:** 10 chars from an unambiguous alphabet (no `0/O/1/l/I`), e.g. `Kx7t-9fQa`.
- **Returned exactly once** in the create/reset response. Never stored in plaintext, never
  re-readable — issuing a new one requires a reset.
- **First login:** response carries `mustChangePassword: true`; the app routes to a
  non-dismissible "Set your password" screen. Every other `/partner/*` endpoint returns
  `409 { error: "Password change required" }` until it's done.
- **New password rules:** min 8 chars, not the temp password, not the phone number.

### 4.4 Brute-force protection (reuses `RateLimiter`)
- `partner-login:{phone}` — 5 attempts / 15 min
- `partner-login-ip:{ip}` — 20 attempts / 15 min
- Failure is always `401 { error: "Invalid phone or password" }` — never reveals whether a
  phone is on the roster (prevents partner-roster enumeration).

### 4.5 Explicitly NOT built
- ❌ `POST /partner/register` — does not exist, will not exist.
- ❌ Self-service "forgot password" — resets go through the admin only (a rider phones ops).
- ❌ OTP login — no SMS provider is wired (`GAP_ANALYSIS.md` marks real SMS as skipped).

---

## 5. Backend API surface

### 5.1 Admin additions (`AdminController.cs`)

| Method | Route | Notes |
|---|---|---|
| `POST` | `/admin/partners` | **changed** — also takes `vehicleType`, `vehicleNumber`, `zone`; generates the temp password and returns `{ ...partner, tempPassword }` **once** |
| `GET` | `/admin/partners/{id}` | detail: profile, duty state, last location, active orders, today's counts |
| `POST` | `/admin/partners/{id}/reset-password` | new temp password, `MustChangePassword=true`, `TokenVersion++` → `{ tempPassword }` |
| `PUT` | `/admin/partners/{id}` | **changed** — `active:false` also does `TokenVersion++` (instant lockout) |
| `DELETE` | `/admin/partners/{id}` | **changed** — 409 if the partner has active assigned orders; prefer deactivate |
| `GET` | `/admin/partners/live` | on-duty partners + last coords, for the ops map |
| `PUT` | `/admin/orders/{id}/assign` | **changed** — stamps `AssignedAt`, writes an `OrderEvent`, pushes to the rider |
| `GET` | `/admin/orders/{id}` | **changed** — includes proof photo, COD collected, delivery note, rider timestamps |

### 5.2 Partner API — new `Controllers/PartnerController.cs`
All `[Authorize(Policy = "Partner")]` except login.

**Auth & profile**

| Method | Route | Body → Response |
|---|---|---|
| `POST` | `/partner/auth/login` | `{phone, password}` → `{token, partner, mustChangePassword}` |
| `POST` | `/partner/auth/password` | `{currentPassword, newPassword}` → `{token}` (rotates `TokenVersion`, re-issues) |
| `POST` | `/partner/auth/logout` | revokes this device's FCM token |
| `GET`  | `/partner/me` | profile + duty + today's summary |
| `PUT`  | `/partner/me/duty` | `{onDuty}`. Going off-duty stops location upload |
| `POST` | `/partner/me/device` | `{token, platform}` — FCM registration |

**Orders** — every handler filters `o.DeliveryPartnerId == me.Id`; a partner can never read
or touch an order that isn't theirs.

| Method | Route | Notes |
|---|---|---|
| `GET`  | `/partner/orders` | `?scope=active` (default: `packed`/`picked_up`/`out_for_delivery`/`failed`) or `?scope=history&from=&to=` |
| `GET`  | `/partner/orders/{id}` | items, customer name/phone, address + coords, slot, payment method, amount to collect |
| `POST` | `/partner/orders/{id}/status` | `{status}` — only `picked_up` \| `out_for_delivery`; validates the legal transition; `out_for_delivery` also mints the 4-digit `DeliveryOtp` and notifies the customer |
| `POST` | `/partner/orders/{id}/deliver` | `{otp, codCollected, note?, photoDataUrl?}` → verifies OTP (3 attempts, then requires photo proof + an admin flag), sets `delivered` + `DeliveredAt`, stores proof, notifies the customer |
| `POST` | `/partner/orders/{id}/fail` | `{reason}` → `failed`, `FailureReason`, event, notifies admin + customer |
| `GET`  | `/partner/summary?date=` | deliveries completed, failed, COD collected (₹), first/last delivery time |

**Tracking**

| Method | Route | Notes |
|---|---|---|
| `POST` | `/partner/location` | `{lat, lng, accuracy?, speed?, heading?, orderId?}` — updates `LastLat/LastLng/LastLocationAt`, appends a `PartnerLocation` row. **Server-side throttle: max 1 write / 10 s per partner** (extras silently 204) so a misbehaving client can't flood the table |

### 5.3 Customer additions

| Method | Route | Notes |
|---|---|---|
| `GET` | `/auth/orders/{id}/track` | Only while `picked_up`/`out_for_delivery`, only for the owning customer → `{status, partner:{name, phone}, location:{lat,lng,updatedAt}, dest:{lat,lng}, etaLabel}`. Returns `{location: null}` otherwise — **the rider's position is never exposed outside an active delivery** |
| `GET` | `/auth/orders/{id}` | **changed** — includes `deliveryOtp` once status is `out_for_delivery` (the code the customer reads out to the rider) |

---

## 6. Admin panel changes (`admin/`)

> ⚠️ Per `admin/AGENTS.md` this is **Next.js 16** — read the relevant guide in
> `node_modules/next/dist/docs/` before writing components.

1. **`app/(admin)/partners/page.tsx`** — vehicle fields, plus a **one-time credential
   modal** on create:
   ```
   ✅ Partner created — share these credentials
   Phone     9876543210
   Password  Kx7t-9fQa            [ Copy ]
   ⚠ This password is shown only once and cannot be recovered.
     The partner must change it at first login.
   ```
   Row actions: **Reset password** (same modal), **Deactivate** (warns "revokes all
   sessions"), link to detail.
2. **`app/(admin)/partners/[id]/page.tsx`** *(new)* — profile, duty state, assigned orders,
   today's deliveries/COD, last-seen location + map.
3. **`app/(admin)/live/page.tsx`** *(new)* — ops map of on-duty riders, polling
   `/admin/partners/live` every 15 s.
4. **`app/(admin)/orders/page.tsx`** — add `picked_up` / `failed` to the list + labels;
   show the assigned rider column.
5. **Order detail** — rider timeline (assigned → picked up → out for delivery → delivered),
   proof photo, COD collected, failure reason + re-assign button.
6. **`lib/resources.ts` / `lib/types.ts`** — extend the `partners` resource
   (`get`, `resetPassword`, `live`) and the `Partner` / `OrderStatus` types.

---

## 7. Rider app (`partner/`) — Flutter

### 7.1 Layout — mirrors `farmfresh/`
```
partner/lib/
  main.dart, app.dart
  core/config/api_config.dart          # same --dart-define=API_BASE pattern
  core/theme/                          # ported (accent shifted to a rider blue/amber)
  core/widgets/                        # buttons, cards, sheets (ported)
  data/datasources/api_client.dart     # ported; 401 ⇒ clear token ⇒ back to login
  data/datasources/partner_token.dart  # static token + shared_preferences (like AuthToken)
  data/repositories/                   # remote_partner_auth_repository, remote_delivery_repository
  domain/entities/                     # partner, delivery_order, delivery_summary, tracking_ping
  domain/repositories/                 # interfaces (no Flutter/HTTP deps)
  presentation/features/
    splash/     gate: token? → orders : login
    auth/       login_page, change_password_page
    orders/     orders_page, order_detail_page, deliver_sheet, fail_sheet
    history/    history_page (+ today's summary card)
    profile/    profile_page (duty, vehicle, change password, logout)
    shell/      main_shell (3-tab bottom nav)
  presentation/providers/              # auth_controller, orders_controller, duty_controller
  presentation/services/location_service.dart
```

### 7.2 Screens

| # | Screen | Content |
|---|---|---|
| 1 | **Splash** | logo → token check → Login or Orders |
| 2 | **Login** | phone + password. **No "Sign up" link.** Footer: *"Delivery partner accounts are created by the FarmFresh team. Contact your ops manager for access."* |
| 3 | **Set password** | forced after first login / admin reset; non-dismissible, no back button |
| 4 | **Orders** (tab 1) | Duty toggle in the header. Sections: **To pick up** (`packed`) · **In transit** (`picked_up`/`out_for_delivery`) · **Retry** (`failed`). Card = code, ₹ amount + COD badge, item count, slot, area. Pull-to-refresh + 30 s poll |
| 5 | **Order detail** | items, customer name, **Call** (`url_launcher` → `tel:`), full address, **Navigate** (Google Maps by coords, else address query), payment method + amount to collect, one primary action per status:<br>`packed` → **Mark picked up** · `picked_up` → **Start delivery** · `out_for_delivery` → **Deliver** / **Can't deliver** |
| 6 | **Deliver sheet** | 4-digit OTP (read out by the customer) → COD amount (prefilled with the order total, editable) → optional photo (`image_picker`, downscaled, sent as a data URL like the existing product-image upload) → optional note → **Confirm delivery** |
| 7 | **Can't deliver sheet** | reason chips (Customer unavailable · Wrong address · Refused · Other + free text) → confirm |
| 8 | **History** (tab 2) | today's summary card (delivered, failed, **₹ COD collected**), then a date-grouped list |
| 9 | **Profile** (tab 3) | name, phone, vehicle, duty toggle, change password, **Log out**, app version |

### 7.3 Location tracking

**Rule: upload only when `onDuty == true` AND at least one order is `picked_up`/
`out_for_delivery`.** Off duty or idle ⇒ tracking stops completely — battery, privacy and
store-policy compliance.

- `geolocator` with an Android **foreground service** (persistent "FarmFresh — delivering"
  notification) and `allowBackgroundLocationUpdates` on iOS.
- Filters: `distanceFilter: 50 m`, min interval 15 s → `POST /partner/location`
  (server throttles to 10 s regardless).
- Offline queue: pings buffer in memory (cap ~200) and flush on reconnect. **A failed
  location upload never blocks completing a delivery.**
- A **permission-rationale screen** before the OS prompt, explaining exactly what is
  tracked and when — required for the Play Store background-location declaration.

### 7.4 Customer-side live map (`farmfresh/`)
On order detail, when status is `picked_up`/`out_for_delivery`: a map with the rider marker
+ destination, polling `/auth/orders/{id}/track` every 15 s, showing the rider's name, a
Call button, and the **delivery OTP prominently** for the customer to read out.

### 7.5 New Flutter dependencies

| Package | Used for |
|---|---|
| `geolocator` | GPS position stream + permissions |
| `permission_handler` | background-location rationale flow |
| `url_launcher` | `tel:` calls, Google Maps navigation |
| `image_picker` | proof-of-delivery photo |
| `google_maps_flutter` | maps in the rider + customer apps (needs an API key) |
| `firebase_core`, `firebase_messaging` | assignment push (shares the Firebase project the customer app still needs) |

Reused as-is: `flutter_riverpod`, `go_router`, `http`, `shared_preferences`.

---

## 8. Security, privacy & compliance

1. **No registration path.** Partner creation is admin-JWT only. Add an API test asserting
   every `/partner/*` route except login rejects an anonymous **and a customer** token.
2. **Ownership checks** on every order handler — `WHERE DeliveryPartnerId = @me`. A rider
   must not read another rider's (or an unassigned) order by guessing an id.
3. **Instant revocation** via `TokenVersion` on deactivate / reset / password change.
4. **Login throttling + non-enumerable errors** (§4.4).
5. **Location retention:** `PartnerLocation` rows older than **7 days** purged by a startup
   + daily cleanup task. Customers only ever see a rider's position during their own
   active delivery.
6. **Proof photos:** `uploads/proof/`, reusing the 3 MB cap and format allowlist from the
   existing product-image endpoint (`AdminController.cs`, `POST /admin/products/{id}/image`,
   3 MB cap at `:220`). Filenames include a random
   component; served only via authenticated admin/customer routes.
7. **COD reconciliation trail:** per-order `CodCollected` is the source of truth for the
   daily cash handover; the admin partner-detail page totals it.
8. **Store requirements:** background-location disclosure screen + privacy-policy URL. An
   in-app account-deletion path is *not* required here (accounts are org-managed, not
   consumer) — but the rationale screen **is** mandatory for Play review.

---

## 9. Build order

Each phase carries its own tests (not a Phase-7 afterthought). Backend/admin phases are
verified with API smoke tests; app phases with `flutter analyze` + a device pass.

| Phase | Status | Deliverable | Touches | Est. |
|---|---|---|---|---|
| **0. Schema** | ✅ **done** | `PartnerAuthAndTracking` migration: credentials, duty, location, order delivery fields, address coords, `PartnerDevice`, `PartnerLocation`. Existing partner rows get an empty hash (unusable until reset). | `Models/Entities.cs`, `Data/AppDbContext.cs`, `Migrations/` | 0.5 d |
| **1. Auth + credential issuance** | ✅ **done** | **Reused `Services/Passwords.cs`**, `SignPartnerToken`, `Partner` policy + `PartnerBase.LoadPartner` revocation check, `/partner/auth/*`, admin create/reset one-time password, admin credential modal. *Tested: create→login→force-change→revoke-on-deactivate.* | `Auth/`, `Program.cs`, `AdminController.cs`, `admin/partners` | 1.5 d |
| **2. Status machine** | ✅ **done** | `picked_up` + `failed` across the 6 grep-verified files + customer copy. | backend + admin + customer app | 0.5 d |
| **3. Partner order API** | ✅ **done** | `PartnerOrdersController` orders/status/deliver/fail/summary — **ownership-checked + transition-guarded** (optimistic concurrency, §11.4). *Tested: full lifecycle + OTP + COD + cross-partner 404.* | `Controllers/PartnerOrdersController.cs` | 2 d |
| **4. Rider app core** | ✅ **done** | New `partner/` project (20 files, rider-blue theme), login → forced password change → orders (duty toggle, poll) → detail → status actions → deliver/fail sheets → history/summary → profile. *`flutter analyze` clean.* (call/navigate deferred to Phase 5 with `url_launcher`.) | `partner/` | 4 d |
| **5. Proof of delivery** | app pending | (backend done) COD capture + photo upload + fail flow in the app; customer sees the OTP. **Move proof photos to durable storage (§11.5).** | `partner/` + `farmfresh/` | 1.5 d |
| **6. Live GPS** | pending | `/partner/location` + throttle + retention job, rider foreground-location service + rationale screen, customer live map, admin live map. **Offline-complete queue (§11.3).** | all four | 4 d |
| **7. Push + polish** | pending | FCM on assignment (un-stubs `Notify.Push`), reassignment flow (§11.1), deactivate-with-cash (§11.2), history/summary, admin partner detail, empty/error states, integration tests. | all four | 2 d |

**≈ 16 working days** end-to-end (Phases 0–3 ≈ 4.5 d **already shipped**). Phase 4 completes a
**usable rider app**; 5–7 make it production-grade.

---

## 10. Open items to confirm before Phase 6

1. **Google Maps API key** (+ billing) — needed for `google_maps_flutter` in both apps.
   Without it, maps degrade to "open the external Maps app" only.
2. **Firebase project** — still unconfigured (`Notify.cs:12` is a stub; `GAP_ANALYSIS.md`
   lists customer push as blocked on it). Assignment alerts fall back to 30 s polling until
   it exists.
3. **Address coordinates** — new addresses need a map-pin picker in the customer app to
   populate `Address.Lat/Lng`; existing addresses stay text-only (navigation by address
   string still works).
4. **Rider app brand / bundle id** — "FarmFresh Partner" or a distinct name? Painful to
   change after publishing.
5. **COD cash handover** — is per-order `CodCollected` enough for v1, or is a formal
   "cash deposited to ops" ledger needed? Currently planned as the former; the latter is
   the deliberately deferred "earnings & payouts" module.

---

## 11. Hardening decisions (edge cases the happy path skips)

These close the gaps that only surface in production. Items marked ✅ are already
implemented in Phases 0–3; the rest are pinned to a later phase so they aren't forgotten.

**11.1 Order re-assignment / hand-off.** When an order is `failed` (or an admin moves it off
a rider), the admin action **clears `DeliveryPartnerId`, resets the delivery snapshot**
(`PickedUpAt`, `DeliveryOtp`, `DeliveryOtpAttempts`, `DeliveryOtpSentAt` → null) and sets the
order back to `packed` (re-assignable). The old rider loses it automatically — every partner
handler filters on `DeliveryPartnerId == me.Id`, so once it's cleared it vanishes from their
active list. Both riders and the customer get an event/notification. *→ Phase 7 (admin
re-assign button + reset helper).* Ownership isolation itself is ✅ done.

**11.2 Deactivating / reassigning a rider mid-delivery.** `DELETE` a partner is already **409'd
while they hold active orders** ✅. `PUT active:false` bumps `TokenVersion` (instant lockout) ✅,
but must **also unassign their in-flight orders back to the queue and preserve any
`CodCollected` so far** for the cash trail. *→ Phase 7:* deactivate warns "N active orders will
be unassigned", moves them via the 11.1 reset (keeping `CodCollected`), and the partner-detail
page shows outstanding cash owed.

**11.3 Completing a delivery offline.** OTP-verify and `deliver`/`fail` need the server. The
rider app **queues the completion action** (with the entered OTP/COD/photo) and retries on
reconnect; the UI shows "syncing…" and the order isn't marked done locally until the server
confirms. A failed sync **never loses the captured COD/photo**. *→ Phase 5/6.*

**11.4 Concurrency / double-transition.** ✅ Handled by **status-guarded transitions**: every
partner mutation asserts the current status (`picked_up` only from `packed`, `deliver` only
from `out_for_delivery`, etc.) and returns `409` otherwise — so two devices, or a rider vs. an
admin racing, can't double-apply. Assignment only targets **active** partners ✅. (If real
contention appears, add a rowversion token; not needed at current scale.)

**11.5 Proof-photo durability.** Phase 5 reuses the local `uploads/proof/` endpoint to ship,
but proof photos are **dispute/legal evidence** — they must move to **object storage (S3 /
Cloudinary) before production**, ahead of the general product-image migration. Tracked as a
release blocker for the rider app, not a nice-to-have.

**11.6 Partner alerts are push-only.** The `Notification` inbox is FK'd to `User` (customers).
Riders get **FCM push + 30 s polling only** (no inbox), and push depends on the **still-stubbed
Firebase project** (§10.2) — until it's configured, assignment relies on polling. Stated so it
isn't mistaken for a built inbox.

**11.7 Migration defaults.** ✅ New non-null partner columns land with CLR defaults
(`PasswordHash=""`, `MustChangePassword=false`, `TokenVersion=0`); an empty hash makes the row
**un-loginnable until an admin issues credentials** — which is the intended "no credentials yet"
state.

**11.8 Assignment validation.** ✅ `assign` rejects an inactive/unknown partner, stamps
`AssignedAt`, and writes an `OrderEvent`. (Assign is allowed from any pre-dispatch state; the
rider can only pick up once the order is `packed`.)

> **Realism note:** ~16 dev-days is engineering effort. Calendar time runs longer once
> **Google Play / App Store review** (background-location justification) and **Maps + Firebase
> account setup** are on the critical path — treat those as parallel, external-dependency tracks.
