# Sign-in: email OTP + Google + Apple

The customer app now signs in with **email OTP (Resend)** or **Google / Apple**,
then collects a mandatory **name + mobile** for new users. The legacy phone SMS
OTP flow is untouched and still available at `/login/phone` for later.

Everything runs today without any provider keys:
- **Email OTP** works immediately — the 6-digit code is returned in the API
  response (`devOtp`) and auto-filled while `OTP_DEV_MODE != false`. Add a Resend
  key to actually email it.
- **Google / Apple** buttons are wired but guarded — until configured they show a
  friendly "not configured / not available" message and the app keeps working.

## Backend env vars

| Variable | Purpose |
|----------|---------|
| `RESEND_API_KEY` | Enables real email delivery of the OTP (else it's logged/returned). |
| `RESEND_FROM` | Optional. From address, e.g. `FarmFresh <no-reply@yourdomain.com>`. Defaults to Resend's sandbox sender. |
| `GOOGLE_CLIENT_ID` | Comma-separated Google OAuth client id(s) to accept as the token audience (Android, iOS, web). |
| `APPLE_CLIENT_ID` | Comma-separated Apple client id(s) — your app bundle id and/or Services ID. |
| `OTP_DEV_MODE` | Set to `false` in production so the code is no longer returned in the API response. |

The backend verifies tokens server-side: Google via Google's tokeninfo endpoint
(audience check), Apple via Apple's JWKS (`Services/SocialAuth.cs`).

## Resend (email OTP)
1. Create an account at https://resend.com and verify your sending domain.
2. Create an API key → set `RESEND_API_KEY` (and `RESEND_FROM` to a verified address).
3. Done — codes now arrive by email. Template lives in `Services/Mailer.cs`.

## Google sign-in
1. In Firebase (same project as FCM) or Google Cloud, create **OAuth client IDs**:
   an **Android** client (needs your app's SHA-1) and a **Web** client (used as the
   server client id so the app can request a backend-audience id token).
2. App side: the Android client is picked up from `google-services.json`. Pass the
   **web** client id to the app so it mints a verifiable id token:
   `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com`
3. Backend: set `GOOGLE_CLIENT_ID` to the id(s) you want to accept (the web client
   id, plus the iOS client id if you ship iOS).

## Apple sign-in
Requires an **Apple Developer account** ($99/yr). Apple sign-in is **mandatory on
iOS** once Google is offered; Android-only builds can skip it.
1. In the Apple Developer portal: enable **Sign in with Apple** for your App ID,
   and (for Android/web) create a **Services ID** + a private key + configure the
   return URL.
2. iOS: add the *Sign in with Apple* capability in Xcode.
3. Android: Apple uses a web redirect — add the intent-filter for your callback to
   `android/app/src/main/AndroidManifest.xml` and set the `WebAuthenticationOptions`
   in `core/auth/social_sign_in.dart` (`SignInWithApple.getAppleIDCredential`).
4. Backend: set `APPLE_CLIENT_ID` to your bundle id and/or Services ID.

## Flow recap
`Splash → Sign in (email / Google / Apple) → [email OTP] → Complete profile
(new users, name pre-filled for social) → Home`. Guests browse products; any
account action opens the sign-in sheet (`presentation/features/auth/sign_in_sheet.dart`).
