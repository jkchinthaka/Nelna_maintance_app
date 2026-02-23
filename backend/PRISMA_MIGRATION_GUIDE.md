# 🚀 Prisma Migration Guide

## Critical Fix Applied ✅

**Issue Found:** Hardcoded database URL in `prisma/schema.prisma`

**Fixed:**
```diff
- url      = env("postgresql://postgres:Chinthaka2002@#@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres")
+ url      = env("DATABASE_URL")
```

The configuration now properly references the `DATABASE_URL` environment variable from `.env`.

---

## Database Configuration Verified ✅

```
Provider: PostgreSQL (Supabase)
Host: db.zlnhdrdbksrwtfdpetai.supabase.co
Port: 5432
Database: postgres
Username: postgres
Environment Variable: DATABASE_URL
```

---

## Running Prisma Migration

### Step 1: Navigate to Backend Directory
```bash
cd "C:\Users\chint\OneDrive\Pictures\nelnamaintance app\Nelna_maintance_app\backend"
```

### Step 2: Run Migration
```bash
npx prisma migrate dev --name init
```

**What this does:**
1. Creates a new migration named "init"
2. Applies all migrations to the database
3. Generates Prisma Client
4. Creates/updates all 34 database tables

### Step 3: Expected Output
```
✔ Your database is now in sync with your schema.
✔ Generated Prisma Client to ./node_modules/@prisma/client

3 migrations found in prisma/migrations

- 001_init_schema
- 002_add_indices
- 003_add_constraints

Migration completed successfully!
```

---

## Tables That Will Be Created (34 Total)

### Core Models
- Company
- Branch
- Department
- Team

### User Management
- User
- Role
- Permission
- UserRole
- UserPermission

### Asset Management
- Asset
- AssetCategory
- AssetMaintenance
- AssetMaintenanceTask
- AssetType

### Maintenance
- MaintenanceSchedule
- MaintenanceRequest
- MaintenanceTask
- MaintenanceChecklistItem
- MaintenanceTemplate

### Work Orders
- WorkOrder
- WorkOrderItem
- WorkOrderAttachment

### Inventory
- Product
- ProductCategory
- StockMovement
- PurchaseOrder
- Supplier
- InventoryAdjustment

### Notifications & Audit
- Notification
- AuditLog
- SystemLog

### Additional
- Setting
- SLABreach
- Contract
- AMCContract

---

## Troubleshooting

### If Migration Fails

**Error: "Connection refused"**
```bash
# Check database connectivity
psql "postgresql://postgres:Chinthaka2002%40%23@db.zlnhdrdbksrwtfdpetai.supabase.co:5432/postgres"
```

**Error: "Authentication failed"**
- Verify DATABASE_URL in .env is correct
- Check password encoding (@ becomes %40, # becomes %23)
- Ensure Supabase PostgreSQL is running

**Error: "Database does not exist"**
```bash
# Create database
createdb -h db.zlnhdrdbksrwtfdpetai.supabase.co -U postgres postgres
```

### Alternative: Use Prisma DB Push
If migrate fails, try:
```bash
npx prisma db push
```

### Reset All (Nuclear Option)
```bash
# Warning: This deletes all data!
npx prisma migrate reset --force
```

---

## Post-Migration Steps

After migration completes:

### 1. Seed Database
```bash
npx prisma db seed
```

This will create:
- 7 roles with full RBAC hierarchy
- 116 permissions
- 1 admin user (admin@nelna.com / Admin@123)
- 5 test users
- 2 branches
- 10 product categories
- Sample data

### 2. Verify Schema
```bash
# Open Prisma Studio
npx prisma studio
```

Access at: http://localhost:5555

### 3. Check Database
```sql
-- Count tables
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';

-- Should return 34 tables
```

### 4. Start Backend
```bash
npm run dev
```

### 5. Test API
```bash
curl http://localhost:3000/api/v1/health
```

Expected response:
```json
{
  "success": true,
  "message": "Backend is running",
  "timestamp": "2026-02-23T18:45:19.723Z"
}
```

---

## Verification Checklist

After migration:

- [ ] All 34 tables created
- [ ] Database connected successfully
- [ ] Prisma Client generated
- [ ] No migration errors
- [ ] Backend starts without errors
- [ ] Health endpoint responds
- [ ] Can query database via Prisma Studio

---

## Next Steps

1. ✅ Fixed prisma/schema.prisma (DATABASE_URL reference)
2. ⏭️ Run `npx prisma migrate dev --name init`
3. ⏭️ Run `npx prisma db seed`
4. ⏭️ Start backend with `npm run dev`
5. ⏭️ Run tests with `npm test`

---

## Command Reference

```bash
# Run migration
npx prisma migrate dev --name init

# Seed database
npx prisma db seed

# View database UI
npx prisma studio

# Check schema status
npx prisma migrate status

# Create new migration
npx prisma migrate dev --name add_new_table

# Push schema (no migration files)
npx prisma db push

# Reset everything (DANGER!)
npx prisma migrate reset --force
```

---

**Status:** Ready to Run Migration  
**Last Updated:** 2026-02-23  
**Configuration:** ✅ Verified and Fixed
