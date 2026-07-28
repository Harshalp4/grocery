# Sign-in: email OTP + Google + Apple

The customer app signs in with **email OTP (Resend)** or **Google / Apple via
Firebase Authentication**, then collects a mandatory **name + mobile** for new
users. The legacy phone SMS OTP flow is untouched and still available at
`/login/phone` for later.

**Google & Apple go through Firebase Auth** (the same Firebase project used for
push): the app authenticates with Firebase and sends the resulting **Firebase ID
token** to `POST /auth/firebase`, which the backend verifies. One token covers
both providers.

Everything runs today without any keys:
- **Email OTP** works immediately — the 6-digit code is returned in the API
  response (`devOtp`) and auto-filled while `OTP_DEV_MODE != false`. Add a Resend
  key to actually email it.
- **Google / Apple** buttons are wired but guarded — until Firebase is configured
  they show a friendly message and the app keeps working.

## Backend env vars

| Variable | Purpose |
|----------|---------|
| `RESEND_API_KEY` | Enables real email delivery of the OTP (else it's logged/returned). |
| `RESEND_FROM` | Optional. From address, e.g. `FarmFresh <no-reply@yourdomain.com>`. Defaults to Resend's sandbox sender. |
| `FIREBASE_PROJECT_ID` | Your Firebase project id — used to verify Firebase ID tokens for Google/Apple sign-in. |
| `OTP_DEV_MODE` | Set to `false` in production so the code is no longer returned in the API response. |

The backend verifies the Firebase ID token against Google's securetoken public
keys, checking issuer + audience = your project id (`Services/SocialAuth.cs`,
`VerifyFirebase`). (Direct `/auth/google` + `/auth/apple` paths that verify raw
provider tokens are also present, gated by `GOOGLE_CLIENT_ID` / `APPLE_CLIENT_ID`,
but the app uses the Firebase path.)

## Resend (email OTP)
1. Create an account at https://resend.com and verify your sending domain.
2. Create an API key → set `RESEND_API_KEY` (and `RESEND_FROM` to a verified address).
3. Done — codes now arrive by email. Template lives in `Services/Mailer.cs`.

## Firebase project (covers Google, Apple, and push)
1. Create a Firebase project → add **Android** app `com.farmfresh.farmfresh` (and
   iOS `com.farmfresh.farmfresh` if shipping iOS). Add the rider app too if it
   needs push: `com.farmfresh.partner`.
2. Download the real **`google-services.json`** → replace the placeholder at
   `farmfresh/android/app/google-services.json`. (iOS: `GoogleService-Info.plist`.)
3. Backend: set **`FIREBASE_PROJECT_ID`** to that project's id.

### Google
1. In Firebase Console → **Authentication → Sign-in method → enable Google**.
2. Add your Android app's **SHA-1** (and SHA-256) fingerprint to the Firebase
   Android app (ask me — I can print the debug SHA-1; you add the release one).
   That's what makes Google sign-in succeed on device.

### Apple
Requires an **Apple Developer account** ($99/yr). Mandatory on iOS once Google is
offered; Android-only can skip it.
1. Firebase Console → **Authentication → enable Apple**.
2. Apple Developer: enable *Sign in with Apple* on the App ID; for Android/web,
   create a **Services ID** + key and paste the details into Firebase's Apple
   provider config (Services ID, Apple team id, key id, private key).
3. iOS: add the *Sign in with Apple* capability in Xcode.

## Flow recap
`Splash → Sign in (email / Google / Apple) → [email OTP] → Complete profile
(new users, name pre-filled for social) → Home`. Guests browse products; any
account action opens the sign-in sheet (`presentation/features/auth/sign_in_sheet.dart`).
