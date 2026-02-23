# Nelna Maintenance System — Deployment Guide

> **Stack:** Supabase (PostgreSQL) + Render (Backend API) + Netlify (Flutter Web) + Android APK

---

## Architecture Overview

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Flutter Web  │   │  Flutter APK │   │   Browser     │
│  (Netlify)    │   │  (Android)   │   │   / Desktop   │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │ HTTPS
                    ┌──────▼───────┐
                    │  Express API  │
                    │  (Render.com) │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  PostgreSQL   │
                    │  (Supabase)   │
                    └──────────────┘
```

---

## STEP 1: Create Supabase Database (Free Tier)

### 1.1 Sign Up & Create Project

1. Go to [https://supabase.com](https://supabase.com) → **Start your project**
2. Sign up with **GitHub** (recommended)
3. Click **New project**
4. Fill in:
   - **Project name:** `nelna-maintenance`
   - **Database Password:** (use a strong password — **SAVE IT**)
   - **Region:** Choose closest to Sri Lanka (e.g., `ap-southeast-1` Singapore)
5. Click **Create new project** → wait ~2 minutes

### 1.2 Get Connection String

1. In Supabase dashboard → **Settings** (gear icon) → **Database**
2. Scroll to **Connection string** section
3. Select **URI** tab
4. Copy the **direct connection** string (port 5432):

```
postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres
```

> **IMPORTANT:** If your password contains special characters (`@`, `#`, etc.), you must URL-encode them:
> - `@` → `%40`
> - `#` → `%23`
>
> Example: password `Chinthaka2002@#` becomes `Chinthaka2002%40%23`

### 1.3 Save Your Credentials

```
DATABASE_URL=postgresql://postgres:[URL-ENCODED-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres
```

---

## STEP 2: Push Your Code to GitHub

### 2.1 Initialize Git Repository (if not already)

```powershell
cd "C:\Users\chint\OneDrive\Pictures\nelnamaintance app\Nelna_maintance_app"

# Initialize git (skip if already done)
git init

# Create .gitignore if needed
# Make sure these are in .gitignore:
#   node_modules/
#   .env
#   backend/.env
#   frontend/build/
#   *.apk
```

### 2.2 Push to GitHub

```powershell
git add .
git commit -m "Deployment: Supabase + Render + Netlify setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/Nelna_maintance_app.git
git push -u origin main
```

---

## STEP 3: Deploy Backend to Render.com (Free Tier)

### 3.1 Sign Up

1. Go to [https://render.com](https://render.com)
2. Sign up with **GitHub** (recommended — auto-connects your repos)

### 3.2 Create Web Service

1. Click **New** → **Web Service**
2. Connect your GitHub repo: `Nelna_maintance_app`
3. Configure:

| Setting | Value |
|---|---|
| **Name** | `nelna-maintenance-api` |
| **Region** | Singapore (closest to SL) |
| **Root Directory** | `backend` |
| **Runtime** | Node |
| **Build Command** | `npm ci && npx prisma generate` |
| **Start Command** | `npx prisma migrate deploy && node prisma/seed.js && node src/server.js` |
| **Plan** | Free |

> **Note:** After the first deployment, change Start Command to just `node src/server.js` (seed only needs to run once).

### 3.3 Set Environment Variables

In Render dashboard → your service → **Environment** tab → Add these:

| Key | Value |
|---|---|
| `NODE_ENV` | `production` |
| `PORT` | `3000` |
| `DATABASE_URL` | `postgresql://postgres:[URL-ENCODED-PASS]@db.[PROJECT-REF].supabase.co:5432/postgres` |
| `JWT_SECRET` | (generate: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`) |
| `JWT_REFRESH_SECRET` | (generate another random string same way) |
| `JWT_EXPIRY` | `24h` |
| `JWT_REFRESH_EXPIRY` | `7d` |
| `CORS_ORIGIN` | `https://YOUR-SITE-NAME.netlify.app` (update after Netlify deploy) |
| `LOG_LEVEL` | `info` |
| `UPLOAD_MAX_SIZE` | `10485760` |

### 3.4 Deploy

1. Click **Create Web Service**
2. Render will build and deploy automatically
3. Wait for "Live" status (~3-5 minutes)
4. Your API will be at: `https://nelna-maintenance-api.onrender.com`

### 3.5 Verify

Open in browser:
```
https://nelna-maintenance-api.onrender.com/api/v1/health
```
Should return: `{ "status": "ok" }`

Test login:
```powershell
curl -X POST https://nelna-maintenance-api.onrender.com/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"admin@nelna.com","password":"Admin@123"}'
```

> **Render Free Tier Note:** The service spins down after 15 min of inactivity. First request after idle takes ~30-50 seconds to cold-start.

---

## STEP 4: Update Flutter Config with Render URL

After Render deploys, update the production URL in Flutter:

Open `frontend/lib/core/config/app_config.dart` and verify:
```dart
Environment.prod: 'https://nelna-maintenance-api.onrender.com/api/v1',
```

> **Already done** — the file has been updated. If your Render service name is different, update it here.

---

## STEP 5: Deploy Flutter Web to Netlify (Free Tier)

### 5.1 Option A: Drag & Drop (Simplest)

#### Build locally:
```powershell
cd "C:\Users\chint\OneDrive\Pictures\nelnamaintance app\Nelna_maintance_app\frontend"

flutter build web --release --dart-define=ENV=prod
```

#### Deploy:
1. Go to [https://app.netlify.com](https://app.netlify.com) → Sign up (free)
2. Click **Add new site** → **Deploy manually**
3. Drag the `frontend/build/web` folder into the drop zone
4. Site is live instantly at `https://random-name.netlify.app`
5. Go to **Site configuration** → **Change site name** → `nelna-maintenance`
   - URL becomes: `https://nelna-maintenance.netlify.app`

#### Configure SPA Routing:
Create a file `frontend/build/web/_redirects`:
```
/*    /index.html   200
```
Or just redeploy — the `netlify.toml` already handles this.

### 5.2 Option B: Auto-Deploy from GitHub (Recommended)

1. Go to [https://app.netlify.com](https://app.netlify.com)
2. Click **Add new site** → **Import an existing project** → **GitHub**
3. Select your repo: `Nelna_maintance_app`
4. Configure:

| Setting | Value |
|---|---|
| **Base directory** | `frontend` |
| **Build command** | `flutter build web --release --dart-define=ENV=prod` |
| **Publish directory** | `frontend/build/web` |

> **Important:** Netlify's build environment doesn't have Flutter installed by default.
> You need to either:
> - Use **Option A** (manual drag & drop) — **easiest**, OR
> - Add a Netlify build plugin or Dockerfile for Flutter

**For beginners, Option A (drag & drop) is strongly recommended.**

### 5.3 Update Render CORS After Netlify Deploy

Go back to **Render.com** → your service → **Environment** → update:
```
CORS_ORIGIN=https://nelna-maintenance.netlify.app
```
(Use your actual Netlify URL)

---

## STEP 6: Build Android APK

### 6.1 Configure for Production

```powershell
cd "C:\Users\chint\OneDrive\Pictures\nelnamaintance app\Nelna_maintance_app\frontend"
```

### 6.2 Build Release APK

```powershell
flutter build apk --release --dart-define=ENV=prod
```

Output APK location:
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

### 6.3 Build Split APKs (Smaller Size)

```powershell
flutter build apk --split-per-abi --release --dart-define=ENV=prod
```

This creates 3 smaller APKs:
```
app-armeabi-v7a-release.apk   (~15-20 MB) — older phones
app-arm64-v8a-release.apk     (~15-20 MB) — most modern phones ✓
app-x86_64-release.apk        (~15-20 MB) — emulators
```

> For distribution, use `app-arm64-v8a-release.apk` (covers 90%+ of devices).

### 6.4 Install on Phone

```powershell
# Connect phone via USB with USB debugging enabled
adb install frontend/build/app/outputs/flutter-apk/app-release.apk
```

Or share the APK file via Google Drive, WhatsApp, email, etc.

### 6.5 (Optional) Build App Bundle for Play Store

```powershell
flutter build appbundle --release --dart-define=ENV=prod
```

Output: `frontend/build/app/outputs/bundle/release/app-release.aab`

---

## STEP 7: Verify Full Deployment

### 7.1 Test Backend API
```
GET  https://nelna-maintenance-api.onrender.com/api/v1/health
POST https://nelna-maintenance-api.onrender.com/api/v1/auth/login
GET  https://nelna-maintenance-api.onrender.com/api/v1/roles
```

### 7.2 Test Flutter Web
1. Open `https://nelna-maintenance.netlify.app`
2. Login with: `admin@nelna.com` / `Admin@123`
3. Verify dashboard loads

### 7.3 Test Android APK
1. Install APK on device
2. Login with same credentials
3. Verify all features work

---

## Quick Reference — All URLs

| Service | URL |
|---|---|
| **Supabase Dashboard** | `https://supabase.com/dashboard/project/YOUR_REF` |
| **Backend API** | `https://nelna-maintenance-api.onrender.com` |
| **Flutter Web** | `https://nelna-maintenance.netlify.app` |
| **Render Dashboard** | `https://dashboard.render.com` |
| **Netlify Dashboard** | `https://app.netlify.com` |

---

## Environment Variables Summary

### Backend (set in Render.com)

| Variable | Example Value |
|---|---|
| `NODE_ENV` | `production` |
| `PORT` | `3000` |
| `DATABASE_URL` | `postgresql://postgres.xxx:pass@...supabase.com:6543/postgres?pgbouncer=true` |
| `DIRECT_URL` | `postgresql://postgres.xxx:pass@...supabase.com:5432/postgres` |
| `JWT_SECRET` | `<64-char random hex>` |
| `JWT_REFRESH_SECRET` | `<64-char random hex>` |
| `JWT_EXPIRY` | `24h` |
| `JWT_REFRESH_EXPIRY` | `7d` |
| `CORS_ORIGIN` | `https://nelna-maintenance.netlify.app` |
| `LOG_LEVEL` | `info` |

### Flutter (compile-time)

| Flag | Value |
|---|---|
| `ENV` | `prod` |
| `SENTRY_DSN` | `(optional)` |

---

## Troubleshooting

### "Cannot connect to database"
- Verify `DATABASE_URL` and `DIRECT_URL` in Render env vars
- Check Supabase dashboard → Settings → Database → make sure project is active
- Ensure the password doesn't have special chars that need URL-encoding

### "CORS error" in browser
- Update `CORS_ORIGIN` in Render to match your exact Netlify URL
- Include both `http` and `https` if needed: `https://nelna-maintenance.netlify.app,http://localhost:3000`

### "502 Bad Gateway" on Render
- Check Render logs for startup errors
- Ensure `PORT=3000` is set
- Verify Prisma migration ran successfully

### "Page not found" on Netlify refresh
- The `netlify.toml` or `_redirects` file must be in the `build/web` folder
- Ensure the redirect rule `/* /index.html 200` is active

### Render cold start (slow first request)
- Free tier spins down after 15 min idle → first request takes ~30-50s
- Upgrade to paid ($7/mo) for always-on if needed
- Or use a cron service to ping `/api/v1/health` every 14 min

### Android APK can't connect
- Make sure you built with `--dart-define=ENV=prod`
- Verify the Render API URL is correct in `app_config.dart`
- Check device has internet access

---

## Default Login Credentials

| Email | Password | Role |
|---|---|---|
| `admin@nelna.com` | `Admin@123` | Super Admin |
| `kamal@nelna.com` | `Admin@123` | Maintenance Manager |
| `nimal@nelna.com` | `Admin@123` | Technician |
| `sunil@nelna.com` | `Admin@123` | Store Manager |
| `ruwan@nelna.com` | `Admin@123` | Driver |
| `chamari@nelna.com` | `Admin@123` | Finance Officer |

> **IMPORTANT:** Change all passwords after first login in production!

---

## Cost Summary (Free Tier)

| Service | Plan | Monthly Cost | Limits |
|---|---|---|---|
| **Supabase** | Free | $0 | 500 MB database, 1 GB file storage, 50k auth users |
| **Render** | Free | $0 | 750 hours/month, spins down after 15 min idle |
| **Netlify** | Free | $0 | 100 GB bandwidth, 300 build minutes/month |
| **Total** | | **$0** | |
