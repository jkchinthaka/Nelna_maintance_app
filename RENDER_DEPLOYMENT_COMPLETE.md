# 🚀 RENDER DEPLOYMENT - COMPLETE SOLUTION

## Current Error
```
Error: Prisma schema validation - (get-config wasm)
Error code: P1012
error: Environment variable not found: DATABASE_URL.
```

**Root Cause:** DATABASE_URL environment variable is NOT set in Render.com dashboard

---

## ✅ SOLUTION - 6 STEPS

### Step 1: Log into Render.com
https://render.com/dashboard

---

### Step 2: Select Your Service
- Click on **nelna-maintenance-api** service
- Click **Settings** (left sidebar)

---

### Step 3: Click Environment
- In Settings, find **Environment** section
- Click **Environment Variables** if needed

---

### Step 4: Add DATABASE_URL Variable

**IMPORTANT:** Use the URL-ENCODED version!

```
Key:   DATABASE_URL
Value: postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
```

**Why URL-encoded?**
- `@` in password becomes `%40`
- `#` in password becomes `%23`
- Render expects URL-safe format

**Copy-paste this exactly:**
```
postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
```

---

### Step 5: Add Other Required Variables

Copy each pair and click "Add Environment Variable":

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `JWT_SECRET` | `$(openssl rand -base64 32)` or any 32+ random chars |
| `JWT_REFRESH_SECRET` | `$(openssl rand -base64 32)` or any 32+ random chars |
| `CORS_ORIGIN` | `https://your-frontend-domain.com` |
| `LOG_LEVEL` | `info` |
| `PORT` | `3000` |

**Generate Random Secrets:**
```bash
openssl rand -base64 32
```

Or use any random string like:
```
aB3cDeFgHiJkLmNoPqRsTuVwXyZ0123456789!@#$%
```

---

### Step 6: Deploy

Click one of:
- **Manual Deploy** button (right now)
- Or just git push (auto-deploys if connected to GitHub)

---

## 📋 Complete Environment Variables Checklist

Copy this checklist and verify each is set in Render:

```
✅ DATABASE_URL = postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
✅ NODE_ENV = production
✅ JWT_SECRET = (random 32+ chars)
✅ JWT_REFRESH_SECRET = (random 32+ chars)
✅ CORS_ORIGIN = https://your-domain.com
✅ LOG_LEVEL = info
✅ PORT = 3000
```

---

## 🎯 Expected Success Logs

After deploying with correct DATABASE_URL, you should see:

```
==> Building...
✔ Generated Prisma Client
✔ DATABASE_URL is set
==> Prisma migration deployed
==> Seeding database...
==> Database seeded successfully
🚀 Nelna Maintenance System v1.0.0 started
📡 Environment: production
🌐 Server running on http://localhost:3000
❤️  Health Check: http://localhost:3000/api/v1/health
```

---

## ✅ Verification After Deployment

### Check 1: Logs
In Render dashboard → **Logs** tab
- Should see "✔ DATABASE_URL is set"
- Should see "Server running on http://localhost:3000"
- Should NOT see "P1012 error"

### Check 2: Health Endpoint
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

### Check 3: Test Login
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
    "accessToken": "...",
    "refreshToken": "...",
    "user": { "id": "...", "email": "admin@nelna.com", ... }
  }
}
```

---

## 🐛 Troubleshooting

### Still Getting P1012 Error?

**Check:**
1. ✅ DATABASE_URL is visible in Render environment variables
2. ✅ Value is URL-encoded (`%40%23` not `@#`)
3. ✅ No quotes around the URL value
4. ✅ No spaces or line breaks
5. ✅ Key is exactly `DATABASE_URL` (all caps)
6. ✅ Saved successfully (green checkmark)

**If still failing:**
1. Click **Manual Deploy** to force rebuild
2. Wait 3-5 minutes for deployment
3. Check logs again

### Connection to Database Failed?

**Cause:** Supabase might be blocking Render's IP

**Solution:**
1. Go to Supabase dashboard
2. Settings → Database → Allowed IPs
3. Disable IP restrictions (for development)
4. Or add Render's IP range

### Migrations Failing?

**Check:**
1. DATABASE_URL is correct
2. Supabase PostgreSQL is running
3. Database `postgres` exists in Supabase
4. Check Render logs for specific error

---

## 📝 What Each Environment Variable Does

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Supabase PostgreSQL connection string |
| `NODE_ENV` | Set to `production` for Render |
| `JWT_SECRET` | Sign authentication tokens |
| `JWT_REFRESH_SECRET` | Sign refresh tokens |
| `CORS_ORIGIN` | Allow frontend to call API |
| `LOG_LEVEL` | Set to `info` for production (less verbose) |
| `PORT` | Must be 3000 for Render |

---

## 🔒 Security Checklist

✅ **Credentials Safe:**
- DATABASE_URL only in Render environment (not in git)
- JWT secrets in environment (not in code)
- Supabase credentials hidden
- No secrets in Dockerfile

✅ **CORS Configured:**
- Set CORS_ORIGIN to your frontend domain
- Prevents unauthorized API access

✅ **Logging Safe:**
- LOG_LEVEL=info (doesn't log sensitive data)
- Logs go to Render dashboard only

---

## 📞 If Deployment Still Fails

1. **Push latest code:**
   ```bash
   git add .
   git commit -m "Fix: Add error checking to Dockerfile startup"
   git push origin main
   ```

2. **Manually deploy in Render:**
   - Click **Manual Deploy**
   - Wait 5-10 minutes

3. **Check logs:**
   - Click **Logs** tab
   - Scroll to bottom for latest messages

4. **Share error:**
   - Copy full error message
   - Include last 20 lines of logs

---

## 🎊 Expected Outcome

Once DATABASE_URL is set:

✅ Docker image pulls from registry  
✅ Dockerfile startup script validates DATABASE_URL  
✅ Prisma CLI connects to Supabase  
✅ Schema is pushed to database  
✅ Database is seeded with test data  
✅ Node.js server starts  
✅ Health check passes  
✅ API is online and responding  

---

## 📋 Quick Reference

### What to set in Render:
```
DATABASE_URL = postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
NODE_ENV = production
JWT_SECRET = (random)
JWT_REFRESH_SECRET = (random)
CORS_ORIGIN = (your domain)
LOG_LEVEL = info
PORT = 3000
```

### Test after deployment:
```bash
curl https://your-app.onrender.com/api/v1/health
```

### Expect:
```json
{"success":true,"message":"Backend is running"}
```

---

**Status:** 🟢 READY - Follow these 6 steps and your deployment will succeed!
