# 🖼️ RENDER DASHBOARD SETUP - VISUAL GUIDE

## Step-by-Step with Screenshots Description

---

## STEP 1️⃣ Open Render Dashboard

**URL:** https://render.com/dashboard

**You will see:**
```
Your services list
- nelna-maintenance-api
- (other services if any)
```

**Action:** Click on **nelna-maintenance-api**

---

## STEP 2️⃣ Click Settings

**Location:** Left sidebar of the service page

**You will see:**
```
Settings (currently selected)
Deploys
Logs
Events
```

**Action:** Make sure you're on **Settings**

---

## STEP 3️⃣ Find Environment Variables Section

**Scroll down** until you see:

```
Environment Variables
┌─────────────────────────┐
│ NODE_ENV = production   │
│ JWT_SECRET = ****       │
│ JWT_REFRESH_SECRET = ** │
└─────────────────────────┘

[Add Environment Variable] button
```

**Action:** Click **[Add Environment Variable]**

---

## STEP 4️⃣ Add DATABASE_URL Variable

**A form will appear:**

```
┌──────────────────────────────────────┐
│ Key:                                 │
│ ┌──────────────────────────────────┐ │
│ │ DATABASE_URL                     │ │
│ └──────────────────────────────────┘ │
│                                      │
│ Value:                               │
│ ┌──────────────────────────────────┐ │
│ │ postgresql://postgres:Chinthak... │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [Save] [Cancel]                      │
└──────────────────────────────────────┘
```

**Copy-Paste Exactly:**

| Field | Content |
|-------|---------|
| Key | `DATABASE_URL` |
| Value | `postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres` |

**⚠️ Critical:** Use `%40%23` NOT `@#`

**Action:** Click **[Save]**

---

## STEP 5️⃣ Verify Variable Was Saved

**You should see:**

```
Environment Variables

NODE_ENV                    = production
JWT_SECRET                  = ****
JWT_REFRESH_SECRET          = ****
DATABASE_URL                = postgresql://postgres... ✅
CORS_ORIGIN                 = https://...
LOG_LEVEL                   = info
PORT                        = 3000
```

**Check:** Green checkmark ✅ next to DATABASE_URL

---

## STEP 6️⃣ Deploy

**Option A - Manual Deploy (Fastest)**

**Location:** Top-right of service page

```
[Manual Deploy ▼]
```

**Action:** 
1. Click **Manual Deploy**
2. Select **Deploy latest commit**
3. Click **Deploy**

**Option B - Auto Deploy (Via GitHub)**

Just push to GitHub:
```bash
git add .
git commit -m "Fix: Add error checking to Dockerfile"
git push origin main
```

Render will auto-deploy.

---

## STEP 7️⃣ Monitor Deployment

**Location:** Click **Logs** tab

**You will see:**

```
==> Downloading cache...
==> Building...
...
#12 [6/8] RUN npm ci
#13 [7/8] RUN npx prisma generate
    ✔ Generated Prisma Client
==> Deploying...
    ✅ DATABASE_URL is set
    ✔ Prisma migration deployed
    ✔ Database seeded successfully
    🚀 Server running on http://localhost:3000
    ❤️  Health Check: http://localhost:3000/api/v1/health
==> Deployment successful!
```

**Watch for:**
- ✅ DATABASE_URL is set
- ✔ Prisma migration deployed
- 🚀 Server running

**If you see:**
- ❌ DATABASE_URL environment variable not set
  - Go back to Step 4, verify the variable was saved
  - Try Manual Deploy again

---

## STEP 8️⃣ Test Deployment

**After seeing "Deployment successful!" in logs:**

### Test 1: Health Endpoint

**Get your Render URL:**
```
Your service URL: https://your-app.onrender.com
(shown at top of service page)
```

**Run test:**
```bash
curl https://your-app.onrender.com/api/v1/health
```

**Expected response:**
```json
{
  "success": true,
  "message": "Backend is running",
  "timestamp": "2026-02-23T19:08:24.061Z"
}
```

### Test 2: Login Endpoint

```bash
curl -X POST https://your-app.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nelna.com","password":"Admin@123"}'
```

**Expected response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "...",
    "user": {
      "id": 1,
      "email": "admin@nelna.com",
      "name": "Admin",
      "roles": ["Admin"]
    }
  }
}
```

---

## ✅ Troubleshooting Visual Guide

### Problem: Still Getting P1012 Error

**In logs you see:**
```
Error: P1012: The provided database string is invalid
error: Environment variable not found: DATABASE_URL
```

**Solution Flowchart:**
```
Is DATABASE_URL in Environment list?
│
├─ NO  → Go back to STEP 4, add it
├─ YES → Check the value
    │
    ├─ Has @# instead of %40%23?
    │  └─ YES → Delete and re-add with correct encoding
    │
    └─ Looks correct?
       └─ Wait 30 seconds, then Manual Deploy again
```

---

### Problem: Connection Timeout

**In logs you see:**
```
Error: P1001: Can't reach database server
```

**Solution:**
1. Check Supabase is running: https://app.supabase.com
2. Verify IP allowlist in Supabase
3. Try Manual Deploy again

---

### Problem: Migration Failed

**In logs you see:**
```
Error: failed to execute batch request
```

**Solution:**
1. Check full error message in logs
2. Could be schema conflict
3. Contact support with error details

---

## 🎯 Quick Summary Visual

```
┌─────────────────────────────────────┐
│ 1. Go to Render Dashboard           │
├─────────────────────────────────────┤
│ 2. Click nelna-maintenance-api      │
├─────────────────────────────────────┤
│ 3. Click Settings                   │
├─────────────────────────────────────┤
│ 4. Add Environment Variable:        │
│    Key: DATABASE_URL                │
│    Value: postgresql://postgres:... │
│           Chinthaka2002%40%23@...   │
├─────────────────────────────────────┤
│ 5. Click Save                       │
├─────────────────────────────────────┤
│ 6. Click Manual Deploy              │
├─────────────────────────────────────┤
│ 7. Wait 5-10 minutes                │
├─────────────────────────────────────┤
│ 8. Check Logs for success           │
├─────────────────────────────────────┤
│ 9. Test with curl                   │
├─────────────────────────────────────┤
│ 10. 🎉 Backend is live!             │
└─────────────────────────────────────┘
```

---

## 📱 Mobile Tips

If accessing from mobile:

1. Use desktop view (better layout)
2. Copy DATABASE_URL value carefully (no typos)
3. Paste in Mobile keyboard with precision
4. Use browser zoom to verify %40%23 (not @#)

---

## 🔒 Security Checklist

Before deployment, verify:

- [ ] DATABASE_URL has `%40%23` (URL-encoded)
- [ ] No plain `@#` in value
- [ ] No quotes around URL value
- [ ] CORS_ORIGIN set to your frontend domain
- [ ] JWT secrets are auto-generated (not visible)
- [ ] LOG_LEVEL is `info` (not `debug`)

---

## 💾 Save This for Reference

**DATABASE_URL to Use:**
```
postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
```

**Health Check URL:**
```
https://your-app.onrender.com/api/v1/health
```

**Test Login:**
```
Email: admin@nelna.com
Password: Admin@123
```

---

**Status:** 🟢 READY - You can complete this in 2 minutes!
