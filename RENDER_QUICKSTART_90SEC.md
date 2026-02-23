# 🎯 RENDER DEPLOYMENT - QUICK START (90 SECONDS)

## The Problem
```
Error: Environment variable not found: DATABASE_URL
```

## The Solution
**Set DATABASE_URL in Render dashboard in 90 seconds**

---

## ⚡ 3-STEP QUICKFIX

### STEP 1: Go to Render Dashboard
```
https://render.com/dashboard
→ Click nelna-maintenance-api
→ Click Settings (left sidebar)
```

### STEP 2: Add Environment Variable
```
Click: Environment
Click: Add Environment Variable

Key:   DATABASE_URL
Value: postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres

⚠️ IMPORTANT: Use %40%23 (not @#)
```

### STEP 3: Deploy
```
Click: Manual Deploy
Wait: 5-10 minutes
Check: Logs tab for success message
```

---

## ✅ Success Indicators

**You'll see in logs:**
```
✔ DATABASE_URL is set
✔ Prisma Client generated
✔ Database seeded successfully
✔ Server running on http://localhost:3000
```

**Test with curl:**
```bash
curl https://your-app.onrender.com/api/v1/health
# Response: {"success":true,"message":"Backend is running"}
```

---

## ⚠️ Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|-----------|
| `@#` in URL | `%40%23` in URL |
| Quotes around value | No quotes |
| Space after comma | No spaces |
| Wrong key name | `DATABASE_URL` exactly |

---

## 📋 All Environment Variables Needed

After DATABASE_URL works, also add these:

```
NODE_ENV              = production
JWT_SECRET            = (any random string, 32+ chars)
JWT_REFRESH_SECRET    = (any random string, 32+ chars)
CORS_ORIGIN           = https://your-frontend-domain.com
LOG_LEVEL             = info
PORT                  = 3000
```

---

## 🔗 Direct Links

- **Render Dashboard:** https://render.com/dashboard
- **Supabase PostgreSQL:** https://app.supabase.com

---

## 💬 Need Help?

1. Check **Logs** in Render dashboard
2. Look for `P1012` or `DATABASE_URL` error
3. Verify URL-encoding: `%40%23` not `@#`
4. Try **Manual Deploy** again after 30 seconds

---

**Done! 🚀 Your backend should be live in 5-10 minutes**
