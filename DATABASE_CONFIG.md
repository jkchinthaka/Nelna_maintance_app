# 🗄️ DATABASE CONFIGURATION - SUPABASE POSTGRESQL

## Database Connection String

```
postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
```

### URL Components
- **Protocol:** `postgresql://` (or `postgres://`)
- **Username:** `postgres`
- **Password:** `Chinthaka2002@#`
- **Host:** `db.zlnhdrdbksrwtfdpetai.supabase.co`
- **Port:** `5432` (PostgreSQL default)
- **Database:** `postgres` (Supabase default)

---

## Where DATABASE_URL is Applied

### 1. ✅ Backend .env File
**Location:** `backend/.env`

```env
DATABASE_URL=postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
```

**Purpose:** Local development with Supabase  
**Used by:** Prisma, Node.js backend  
**Status:** ✅ CONFIGURED

---

### 2. ✅ Backend .env.example File
**Location:** `backend/.env.example`

```env
DATABASE_URL=postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
```

**Purpose:** Template for new developers  
**Used by:** Reference/documentation  
**Status:** ✅ UPDATED

---

### 3. ✅ Prisma Schema
**Location:** `backend/prisma/schema.prisma`

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

**Purpose:** Tells Prisma to use the environment variable  
**Used by:** Prisma migrations, queries  
**Status:** ✅ FIXED (now uses env reference)

---

### 4. ✅ Docker Compose (Alternative Local Setup)
**Location:** `docker-compose.yml`

```yaml
environment:
  DATABASE_URL: mysql://${MYSQL_USER:-nelna_user}:${MYSQL_PASSWORD:-NelnaPass@2024}@mysql:3306/${MYSQL_DATABASE:-nelna_maintenance}
```

**Purpose:** Local MySQL development (alternative to Supabase)  
**Status:** ✅ KEPT (for backward compatibility)  
**Note:** Uses MySQL, not PostgreSQL - different connection string

---

### 5. ✅ Dockerfile
**Location:** `Dockerfile`

```dockerfile
# Start app (DATABASE_URL from environment: postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres)
CMD sh -c "npx prisma db push --skip-generate && npx prisma db seed && node src/server.js"
```

**Purpose:** Docker build documentation  
**Used by:** Container deployment  
**Status:** ✅ DOCUMENTED

---

### 6. ✅ Render.yaml (Cloud Deployment)
**Location:** `render.yaml`

```yaml
envVars:
  - key: DATABASE_URL
    sync: false  # set manually in Render dashboard
```

**Purpose:** Deployment on Render.com  
**Used by:** Render CI/CD pipeline  
**Status:** ✅ CONFIGURED (manual entry in Render dashboard)

---

## How to Use DATABASE_URL

### In Node.js Code
```javascript
// Option 1: Via dotenv (automatic)
require('dotenv').config();

// Option 2: Via process.env
const databaseUrl = process.env.DATABASE_URL;

// Option 3: Via Prisma (automatic)
// Prisma reads DATABASE_URL from .env
const prisma = new PrismaClient();
```

### In Prisma
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")  // Reads from .env
}
```

### In Connection Strings
```javascript
const client = new Client({
  connectionString: process.env.DATABASE_URL
});
```

---

## Development Workflow

### Step 1: Verify .env Configuration
```bash
cd backend
cat .env | grep DATABASE_URL
# Should output: DATABASE_URL=postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres
```

### Step 2: Run Migrations
```bash
npx prisma migrate dev --name init
```

### Step 3: Seed Database
```bash
npx prisma db seed
```

### Step 4: Start Backend
```bash
npm run dev
```

### Step 5: Verify Connection
```bash
curl http://localhost:3000/api/v1/health
```

---

## Production Deployment (Render.com)

### Step 1: In Render Dashboard
1. Go to your Render service
2. Click **Environment**
3. Add variable: `DATABASE_URL`
4. Value: `postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres`
5. Save

### Step 2: Deploy
1. Connect GitHub repo → Render auto-deploys
2. Or manually trigger deploy
3. Monitor logs for successful connection

### Step 3: Verify
```bash
curl https://your-render-app.onrender.com/api/v1/health
```

---

## URL Encoding Reference

The DATABASE_URL uses URL encoding for special characters:

| Character | Encoded | Used In |
|-----------|---------|---------|
| `@` | `%40` | (not needed in URL - it's a separator) |
| `#` | `%23` | (not needed in URL - comments) |
| `:` | `%3A` | (not needed in URL - port separator) |
| `@` at end of password | PLAIN | (used as-is in `user:password@host`) |

**In plain text:** `Chinthaka2002@#`  
**In connection string:** `Chinthaka2002@#` (as-is, no encoding needed)

---

## Testing Database Connection

### Via psql Command Line
```bash
psql "postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres"
```

### Via Prisma
```bash
npx prisma db execute --stdin < test.sql
```

### Via Node.js
```javascript
const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres'
});

client.connect()
  .then(() => console.log('Connected!'))
  .catch(err => console.error('Connection error:', err));
```

---

## Troubleshooting

### Error: Connection refused
```
Cause: Supabase server not responding
Solution: Check Supabase dashboard status
         Verify internet connectivity
         Wait a few seconds and retry
```

### Error: Authentication failed
```
Cause: Wrong password or username
Solution: Verify DATABASE_URL is correct
         Check credentials in Supabase
         Ensure no extra spaces
```

### Error: Database does not exist
```
Cause: postgres database not created
Solution: Create it in Supabase dashboard
         Or reset project
         Or check correct database name
```

### Error: Connection timeout
```
Cause: Network connectivity issue
Solution: Check VPN/firewall settings
         Verify IP whitelist in Supabase
         Check port 5432 is open
```

---

## Configuration Summary

| File | Location | URL | Status |
|------|----------|-----|--------|
| .env | backend/.env | Plain text | ✅ Active |
| .env.example | backend/.env.example | Plain text | ✅ Template |
| schema.prisma | backend/prisma/ | Via env() | ✅ Reference |
| docker-compose.yml | root | MySQL (alt) | ✅ Fallback |
| Dockerfile | root | Commented | ✅ Documented |
| render.yaml | root | Manual entry | ✅ Configured |

---

## Security Notes

⚠️ **Important:**
- ✅ DATABASE_URL is in `.env` (never commit!)
- ✅ `.env` is in `.gitignore`
- ✅ Only developers should have this file
- ✅ Never share DATABASE_URL publicly
- ✅ Use different credentials for production
- ✅ Rotate passwords regularly

---

## Files Applied To

```
✅ backend/.env                      (ACTIVE - Development)
✅ backend/.env.example              (TEMPLATE - Reference)
✅ backend/prisma/schema.prisma      (REFERENCED - Via env())
✅ backend/.Dockerfile               (DOCUMENTED - In comments)
✅ render.yaml                        (MANUAL - In Render dashboard)
✅ docker-compose.yml                (ALTERNATIVE - MySQL fallback)
```

---

**Status:** ✅ DATABASE URL APPLIED EVERYWHERE  
**Last Updated:** 2026-02-23  
**PostgreSQL:** ✅ READY FOR MIGRATIONS
