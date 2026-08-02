# Deployment — backend on Render, admin on Vercel

The app is prepped to deploy from GitHub: the backend reads all secrets from
env, binds to the host's `$PORT`, and ships a Dockerfile + `render.yaml`
blueprint; the admin reads its API URL from `NEXT_PUBLIC_API_BASE`.

## 0. Push to GitHub (once)
Create an empty repo at github.com (private is fine), then:
```
git remote add origin https://github.com/<you>/farmfresh.git
git push -u origin master
```
(If pushing over HTTPS asks for a password, use a GitHub Personal Access Token.)

## 1. Backend + Postgres on Render
1. Render → **New → Blueprint** → connect the repo → it reads `render.yaml`
   (creates the `farmfresh-api` web service + `farmfresh-db` Postgres).
2. Set the secrets marked `sync: false` in the service's **Environment**:
   - `Admin__Password` — your admin login password.
   - `RESEND_API_KEY` — your Resend key (email OTP).
   - `FIREBASE_PROJECT_ID` — your Firebase project id (Google/Apple sign-in).
   - `Jwt__Secret` is auto-generated; `DATABASE_URL` is wired from the DB.
3. Deploy. First boot runs EF migrations and seeds demo data (idempotent).
4. Verify: open `https://farmfresh-api.onrender.com/health` → `{"ok":true}`.

Notes:
- Free web services **sleep after ~15 min idle** (first request is slow). Upgrade
  the plan to keep it warm.
- Uploaded files are durable **only if `CLOUDINARY_URL` is set** — then admin
  product images and delivery-proof photos go to Cloudinary's CDN. Without it,
  they fall back to local disk, which is **ephemeral** on Render (seed images
  ship in the image and are fine; new uploads are lost on redeploy). Set up
  Cloudinary before relying on uploads (below).

### Cloudinary (durable image uploads)
1. Create a free account at https://cloudinary.com.
2. Dashboard → copy the **API environment variable**
   (`cloudinary://<api_key>:<api_secret>@<cloud_name>`).
3. Set it on Render as **`CLOUDINARY_URL`** (and in local `.env` for dev). Done —
   the code auto-switches from disk to Cloudinary when it's present.

## 2. Admin panel on Vercel
1. Vercel → **Add New → Project** → import the repo.
2. **Root Directory: `admin`** (it's a monorepo). Framework auto-detects Next.js.
3. Environment variable: `NEXT_PUBLIC_API_BASE = https://farmfresh-api.onrender.com`
4. Deploy → open the Vercel URL → log in with `Admin__Email` / `Admin__Password`.

## 3. Lock CORS (optional, recommended)
Once you know the Vercel URL, set on Render:
`ALLOWED_ORIGINS = https://<your-admin>.vercel.app` — the API then only accepts
the admin origin (the mobile apps call it directly and are unaffected).

## 4. Point the apps at the live backend
Build the Flutter apps against the deployed API:
```
flutter build apk --dart-define=API_BASE=https://farmfresh-api.onrender.com
```
(Rider app uses the same `--dart-define=API_BASE`.)

## Environment variables (backend)
| Variable | Set by | Purpose |
|---|---|---|
| `DATABASE_URL` | Render (blueprint) | Postgres connection (parsed to Npgsql). |
| `Jwt__Secret` | Render (generated) | Token signing key. |
| `Admin__Email` / `Admin__Password` | you | Admin panel login. |
| `RESEND_API_KEY` / `RESEND_FROM` | you | Email OTP delivery. |
| `FIREBASE_PROJECT_ID` | you | Google/Apple sign-in verification. |
| `CLOUDINARY_URL` | you | Durable image uploads (else ephemeral local disk). |
| `OTP_DEV_MODE=false` | blueprint | Stop returning OTPs in responses. |
| `ALLOWED_ORIGINS` | optional | Restrict CORS to the admin origin. |
| `PORT` | Render | Injected; the app binds to it automatically. |
