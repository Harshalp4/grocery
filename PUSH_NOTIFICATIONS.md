# Push notifications (FCM) — going live

The apps and backend are **fully wired for Firebase Cloud Messaging**. Everything
runs today without Firebase (push simply no-ops; the in-app notification inbox
still works). To turn on real device push, add your own Firebase project's
credentials — no code changes required.

## What's already built

**Backend** (`backend-dotnet`)
- `Services/Notify.cs` — `ToUser()` / `ToPartner()` / `Broadcast()` write the inbox
  row and fan the message out to every registered device token via FCM. The send
  is a no-op until a server key is set (`FcmConfigured`), then it POSTs to FCM.
- Order lifecycle already calls these: status changes → customer; order assignment
  → rider (`AdminController` assign).
- Token registration endpoints: `POST /notifications/token` (customer),
  `POST /partner/me/device` (rider). Tokens are stored in `DeviceTokens` /
  `PartnerDevices`.

**Customer app** (`farmfresh`) and **Rider app** (`partner`)
- `firebase_core` + `firebase_messaging` added.
- `PushService` (guarded): inits Firebase, requests notification permission, gets
  the FCM token. On login (and on app start with a saved session) the token is
  registered with the backend.
- A **placeholder** `android/app/google-services.json` ships so the app builds. It
  is NOT a real project — push stays off until you replace it.

## Steps to enable

1. **Create a Firebase project** at https://console.firebase.google.com.
2. **Add two Android apps** with these package names:
   - Customer: `com.farmfresh.farmfresh`
   - Rider: `com.farmfresh.partner`
3. **Download each `google-services.json`** and replace the placeholders:
   - `farmfresh/android/app/google-services.json`
   - `partner/android/app/google-services.json`
   (For iOS, add `GoogleService-Info.plist` under `ios/Runner/` and register the
   iOS apps — the Dart code is already platform-agnostic.)
4. **Give the backend a credential.** Set ONE environment variable before running
   the API:
   - `FCM_SERVER_KEY` — legacy Cloud Messaging server key (simplest; Google is
     retiring this API), **or**
   - `FIREBASE_SERVICE_ACCOUNT` — path to a service-account JSON for the modern
     HTTP v1 API. If you use this, switch the endpoint in `Notify.SendFcm` to
     `https://fcm.googleapis.com/v1/projects/<project-id>/messages:send` and mint
     an OAuth2 bearer token from the service account (e.g. with
     `Google.Apis.Auth`) instead of the `key=` header.
5. **Rebuild the apps** and run the backend. Device tokens register on login; order
   updates now arrive as real push notifications.

## Verifying

- Backend logs `[PUSH stub] ... -> N device(s)` when no key is set, and
  `[PUSH] ... -> N device(s): 200` once it's sending.
- Check a token was stored: `GET /admin/...` isn't exposed for tokens, but you can
  query the `DeviceTokens` / `PartnerDevices` tables directly.
