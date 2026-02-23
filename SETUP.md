# Nelna Maintenance System — Backend Local Setup Guide

> **Version:** 1.0.0
> **Stack:** Node.js · Express.js · MySQL 8.0 · Prisma ORM · JWT Authentication
> **Last Updated:** February 2026

---

## Table of Contents

- [Nelna Maintenance System — Backend Local Setup Guide](#nelna-maintenance-system--backend-local-setup-guide)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Clone the Repository](#clone-the-repository)
  - [Database Setup (Choose One)](#database-setup-choose-one)
    - [Option A — MySQL via Docker (Recommended)](#option-a--mysql-via-docker-recommended)
    - [Option B — Local MySQL Installation](#option-b--local-mysql-installation)
  - [Environment Configuration](#environment-configuration)
  - [Install Dependencies](#install-dependencies)
  - [Database Migration](#database-migration)
  - [Seed the Database](#seed-the-database)
  - [Start the Development Server](#start-the-development-server)
  - [Verify the Setup](#verify-the-setup)
    - [Health Check](#health-check)
    - [Test Authentication](#test-authentication)
    - [Prisma Studio (Visual Database Browser)](#prisma-studio-visual-database-browser)
  - [API Endpoints Overview](#api-endpoints-overview)
  - [Default Login Credentials](#default-login-credentials)
  - [Common Errors \& Troubleshooting](#common-errors--troubleshooting)
    - [Database Connection Refused](#database-connection-refused)
    - [Access Denied for User](#access-denied-for-user)
    - [Database Does Not Exist (P1003)](#database-does-not-exist-p1003)
    - [Prisma Client Not Generated](#prisma-client-not-generated)
    - [Port 3000 Already in Use](#port-3000-already-in-use)
    - [Seed Script Fails with Unique Constraint](#seed-script-fails-with-unique-constraint)
    - [`nodemon` Not Recognized](#nodemon-not-recognized)
    - [JWT Secret Warning on Startup](#jwt-secret-warning-on-startup)
    - [Migration Drift Detected](#migration-drift-detected)
  - [Production Readiness Checklist](#production-readiness-checklist)
    - [Security](#security)
    - [Database](#database)
    - [Infrastructure](#infrastructure)
    - [Performance](#performance)
    - [Monitoring](#monitoring)
  - [Useful Commands Reference](#useful-commands-reference)
    - [Application](#application)
    - [Prisma / Database](#prisma--database)
    - [Docker](#docker)
  - [Quick Start (TL;DR)](#quick-start-tldr)

---

## Prerequisites

Ensure the following tools are installed on your machine **before** proceeding:

| Tool | Minimum Version | Verify Command | Download Link |
| --- | --- | --- | --- |
| **Node.js** | `>= 18.0.0` | `node -v` | [nodejs.org](https://nodejs.org/) |
| **npm** | `>= 9.0.0` | `npm -v` | Bundled with Node.js |
| **MySQL** | `8.0` | `mysql --version` | [dev.mysql.com](https://dev.mysql.com/downloads/) |
| **Docker** | `>= 20.10` *(optional)* | `docker --version` | [docker.com](https://www.docker.com/get-started/) |
| **Git** | `>= 2.30` | `git --version` | [git-scm.com](https://git-scm.com/) |

> **Note:** You need **either** a local MySQL installation **or** Docker — not both.

---

## Clone the Repository

```bash
git clone <repository-url>
cd Nelna_maintance_app
```

---

## Database Setup (Choose One)

### Option A — MySQL via Docker (Recommended)

This is the fastest way to get a correctly configured MySQL 8.0 instance running.

```bash
# From the project root directory
docker-compose up -d mysql
```

Wait for the health check to pass (~30 seconds):

```bash
docker ps --filter "name=nelna_mysql" --format "table {{.Names}}\t{{.Status}}"
```

Expected output:

```text
NAMES          STATUS
nelna_mysql    Up 30s (healthy)
```

**Docker MySQL defaults:**

| Variable | Value |
| --- | --- |
| Host | `localhost` |
| Port | `3306` |
| Root Password | `NelnaRoot@2024` |
| Database | `nelna_maintenance` |
| User | `nelna_user` |
| Password | `NelnaPass@2024` |

### Option B — Local MySQL Installation

1. Install MySQL 8.0 from [dev.mysql.com](https://dev.mysql.com/downloads/mysql/).
2. Start the MySQL service.
3. Log in and create the database and user:

```sql
-- Connect as root
mysql -u root -p

-- Create the database
CREATE DATABASE nelna_maintenance
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Create a dedicated user
CREATE USER 'nelna_user'@'localhost' IDENTIFIED BY 'NelnaPass@2024';

-- Grant privileges
GRANT ALL PRIVILEGES ON nelna_maintenance.* TO 'nelna_user'@'localhost';
FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES LIKE 'nelna_maintenance';
EXIT;
```

---

## Environment Configuration

Copy the example environment file and configure it:

```bash
cd backend
cp .env.example .env
```

Open `backend/.env` and update the values:

```dotenv
# ============================================================================
# NELNA MAINTENANCE MANAGEMENT SYSTEM - Environment Configuration
# ============================================================================

# Application
NODE_ENV=development
PORT=3000
APP_NAME=Nelna Maintenance System
APP_VERSION=1.0.0

# Database
# If using Docker (Option A):
DATABASE_URL="mysql://nelna_user:NelnaPass@2024@localhost:3306/nelna_maintenance"
# If using local MySQL with root (Option B alternative):
# DATABASE_URL="mysql://root:YOUR_ROOT_PASSWORD@localhost:3306/nelna_maintenance"

# JWT Configuration — CHANGE THESE IN PRODUCTION
JWT_SECRET=nelna-jwt-secret-change-in-production-2024-min-32-characters-long
JWT_REFRESH_SECRET=nelna-refresh-secret-change-in-production-2024-min-32-chars
JWT_EXPIRY=24h
JWT_REFRESH_EXPIRY=7d

# CORS — Allowed origins (comma-separated)
CORS_ORIGIN=http://localhost:3000,http://localhost:8080

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# File Upload
UPLOAD_MAX_SIZE=10485760
UPLOAD_PATH=./uploads

# Logging
LOG_LEVEL=debug
LOG_DIR=./logs

# Firebase (FCM Push Notifications) — Optional for local dev
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# Email (SMTP) — Optional for local dev
SMTP_HOST=
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=
SMTP_PASS=
SMTP_FROM=noreply@nelna.com
```

> **Important:** The `DATABASE_URL` must match the credentials from whichever database setup option you chose in Step 3.

---

## Install Dependencies

```bash
# Make sure you are inside the backend/ directory
cd backend
npm install
```

Expected output:

```text
added 250+ packages, and audited 250+ packages in 15s
found 0 vulnerabilities
```

This installs all production and development dependencies including Prisma CLI, Express, JWT, bcrypt, and more.

---

## Database Migration

Generate and apply all database migrations. This creates **34 tables** in your MySQL database covering:

| Module | Tables |
| --- | --- |
| **Auth & Users** | `companies`, `branches`, `roles`, `permissions`, `role_permissions`, `users` |
| **Vehicles** | `vehicles`, `vehicle_documents`, `fuel_logs`, `vehicle_service_history`, `vehicle_drivers` |
| **Machines** | `machines`, `machine_maintenance_schedules`, `breakdown_logs`, `amc_contracts`, `machine_service_history` |
| **Services** | `service_requests`, `service_tasks`, `service_spare_parts` |
| **Inventory** | `product_categories`, `products`, `stock_movements`, `suppliers`, `purchase_orders`, `purchase_order_items`, `grns`, `grn_items` |
| **Assets** | `assets`, `asset_repair_logs`, `asset_transfers` |
| **Finance** | `expenses` |
| **System** | `audit_logs`, `notifications`, `system_configs` |

Run the migration:

```bash
npx prisma migrate dev --name init
```

Expected output:

```text
Environment variables loaded from .env
Prisma schema loaded from prisma/schema.prisma
Datasource "db": MySQL database "nelna_maintenance" at "localhost:3306"

Applying migration `20260223XXXXXX_init`

The following migration(s) have been created and applied from new schema changes:

migrations/
  └─ 20260223XXXXXX_init/
    └─ migration.sql

Your database is now in sync with your schema.

✔ Generated Prisma Client (v5.10.x) to ./node_modules/@prisma/client in XXXms
```

> **Tip:** If you see `Generated Prisma Client` at the end, the migration was successful.

---

## Seed the Database

Populate the database with essential default data:

```bash
npx prisma db seed
```

The seed script inserts:

| Data | Count | Details |
| --- | --- | --- |
| **Roles** | 7 | `super_admin`, `company_admin`, `maintenance_manager`, `technician`, `store_manager`, `driver`, `finance_officer` |
| **Permissions** | 120+ | CRUD across 8 modules — vehicles, machines, services, inventory, assets, reports, users, system |
| **Role ↔ Permission** | Full | All permissions mapped per role based on responsibility level |
| **Company** | 1 | Nelna Company (Pvt) Ltd |
| **Branches** | 2 | Head Office (Colombo), Factory Branch (Horana) |
| **Users** | 6 | 1 per role — admin, manager, technician, store manager, driver, finance officer |
| **Product Categories** | 10 | Spare Parts, Lubricants, Filters, Electrical Parts, Belts & Hoses, Safety Equipment, Cleaning Supplies, Tools, Bearings & Seals, Hydraulic Parts |
| **System Configs** | 10 | Currency (LKR), date format, SLA thresholds, alert settings |

Expected output:

```text
🌱 Starting database seed...

Creating roles...
  ✅ 7 roles created
Creating permissions...
  ✅ 120 permissions created
Assigning permissions to Super Admin...
  ✅ 120 permissions assigned to Super Admin
Assigning permissions to other roles...
  ✅ Role permissions assigned
Creating default company and branch...
  ✅ Company and branches created
Creating default users...
  ✅ 6 users created (password: Admin@123)
Creating product categories...
  ✅ 10 categories created
Creating system configurations...
  ✅ 10 system configs created

✅ Database seeding completed successfully!

Default Login Credentials:
  Email: admin@nelna.com
  Password: Admin@123
```

---

## Start the Development Server

```bash
npm run dev
```

Expected output:

```text
[nodemon] 3.1.x
[nodemon] to restart at any time, enter `rs`
[nodemon] watching path(s): *.*
[nodemon] watching extensions: js,mjs,cjs,json
[nodemon] starting `node src/server.js`
✅ Database connection established successfully
🚀 Nelna Maintenance System v1.0.0 started
📡 Environment: development
🌐 Server running on http://localhost:3000
📋 API Base: http://localhost:3000/api/v1
❤️  Health Check: http://localhost:3000/api/v1/health
```

The server is now running on `http://localhost:3000`.

---

## Verify the Setup

### Health Check

```bash
curl http://localhost:3000/api/v1/health
```

Expected JSON response:

```json
{
  "success": true,
  "message": "Nelna Maintenance System API is running",
  "data": {
    "name": "Nelna Maintenance System",
    "version": "1.0.0",
    "environment": "development",
    "timestamp": "2026-02-23T10:00:00.000Z",
    "uptime": 5.123
  }
}
```

### Test Authentication

```bash
curl -X POST http://localhost:3000/api/v1/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\": \"admin@nelna.com\", \"password\": \"Admin@123\"}"
```

> On Linux/Mac, replace `^` with `\` and use single quotes around the JSON body.

A successful response returns a JWT access token, refresh token, and the user profile.

### Prisma Studio (Visual Database Browser)

```bash
npx prisma studio
```

Opens a browser UI at `http://localhost:5555` to browse and edit all 34 database tables visually.

---

## API Endpoints Overview

All endpoints are prefixed with `/api/v1`. Authentication is required for all routes except health check and login.

| Module | Base Route | Description |
| --- | --- | --- |
| **Auth** | `/api/v1/auth` | Login, register, refresh token, logout, password reset |
| **Vehicles** | `/api/v1/vehicles` | Vehicle CRUD, fuel logs, documents, driver assignment |
| **Machines** | `/api/v1/machines` | Machine CRUD, maintenance schedules, breakdowns, AMC contracts |
| **Services** | `/api/v1/services` | Service requests, task assignment, spare parts tracking |
| **Inventory** | `/api/v1/inventory` | Products, categories, stock movements, suppliers, purchase orders, GRN |
| **Assets** | `/api/v1/assets` | Asset CRUD, repair logs, asset transfers |
| **Reports** | `/api/v1/reports` | Dashboard analytics, PDF & Excel report generation |
| **Health** | `/api/v1/health` | System health check (no auth required) |

**Authentication Header:**

```text
Authorization: Bearer <your-jwt-token>
```

---

## Default Login Credentials

| Role | Email | Password | Employee ID |
| --- | --- | --- | --- |
| **Super Admin** | `admin@nelna.com` | `Admin@123` | EMP001 |
| **Maintenance Mgr** | `kamal@nelna.com` | `Admin@123` | EMP002 |
| **Technician** | `nimal@nelna.com` | `Admin@123` | EMP003 |
| **Store Manager** | `sunil@nelna.com` | `Admin@123` | EMP004 |
| **Driver** | `ruwan@nelna.com` | `Admin@123` | EMP005 |
| **Finance Officer** | `chamari@nelna.com` | `Admin@123` | EMP006 |

> ⚠️ **Security Warning:** Change all default passwords immediately in non-development environments.

---

## Common Errors & Troubleshooting

### Database Connection Refused

```text
Error: Can't reach database server at `localhost:3306`
```

**Cause:** MySQL is not running or not listening on port 3306.

**Fix:**

| Setup | Command |
| --- | --- |
| Docker | `docker-compose up -d mysql` — wait for `(healthy)` status |
| Windows Local | `net start mysql80` |
| Linux/Mac | `sudo systemctl start mysql` |
| Verify port | Windows: `netstat -an \| findstr 3306` · Linux: `lsof -i :3306` |

---

### Access Denied for User

```text
Error: Access denied for user 'nelna_user'@'localhost'
```

**Cause:** Incorrect credentials in `DATABASE_URL`.

**Fix:**

- Double-check username, password, and database name in `backend/.env`.
- Docker default URL: `mysql://nelna_user:NelnaPass@2024@localhost:3306/nelna_maintenance`
- If your password contains special characters, URL-encode them (e.g., `@` → `%40` when it appears in the password portion).
- Test direct connection: `mysql -u nelna_user -p'NelnaPass@2024' -h 127.0.0.1 nelna_maintenance`

---

### Database Does Not Exist (P1003)

```text
Error: P1003 — Database `nelna_maintenance` does not exist on the database server
```

**Cause:** The database has not been created yet.

**Fix:**

- Docker: `docker-compose up -d mysql` auto-creates the database from environment variables.
- Local: Run `CREATE DATABASE nelna_maintenance CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;` manually.

---

### Prisma Client Not Generated

```text
Error: @prisma/client did not initialize yet. Please run "prisma generate"
```

**Fix:**

```bash
npx prisma generate
```

---

### Port 3000 Already in Use

```text
Error: listen EADDRINUSE: address already in use :::3000
```

**Fix (Windows):**

```powershell
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F
```

**Fix (Alternative):** Change the port in `backend/.env`:

```dotenv
PORT=3001
```

---

### Seed Script Fails with Unique Constraint

```text
Error: Unique constraint failed on the fields: (`email`)
```

**Cause:** Seed data already exists from a previous run.

**Fix:** The seed uses `upsert` operations, so this should not normally occur. If it does, reset the database entirely:

```bash
npx prisma migrate reset
```

> ⚠️ This **drops all data**, re-runs all migrations, and re-runs the seed script.

---

### `nodemon` Not Recognized

```text
'nodemon' is not recognized as an internal or external command
```

**Fix:**

```bash
npm install          # Installs dev dependencies including nodemon
# OR install globally:
npm install -g nodemon
```

---

### JWT Secret Warning on Startup

```text
⚠️  Warning: Missing configuration: jwt.secret
```

**Cause:** `JWT_SECRET` or `JWT_REFRESH_SECRET` not set in `.env`.

**Fix:** Ensure both values exist in `backend/.env`:

```dotenv
JWT_SECRET=nelna-jwt-secret-change-in-production-2024-min-32-characters-long
JWT_REFRESH_SECRET=nelna-refresh-secret-change-in-production-2024-min-32-chars
```

---

### Migration Drift Detected

```text
Error: Drift detected: Your database schema is not in sync
```

**Cause:** The database was modified outside of Prisma migrations.

**Fix:**

```bash
# Reset to a clean state (WARNING: drops all data)
npx prisma migrate reset

# Or, if you want to baseline the current schema:
npx prisma db pull
npx prisma migrate dev --name fix-drift
```

---

## Production Readiness Checklist

### Security

- [ ] Generate cryptographically strong `JWT_SECRET` and `JWT_REFRESH_SECRET` (64+ characters):

  ```bash
  node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
  ```

- [ ] Set `NODE_ENV=production`
- [ ] Replace all default MySQL passwords with strong, unique passwords
- [ ] Enable HTTPS / TLS termination via the included Nginx reverse proxy (`nginx/` directory)
- [ ] Restrict `CORS_ORIGIN` to your actual frontend domain(s) only
- [ ] Disable Prisma Studio access in production
- [ ] Set `LOG_LEVEL=info` or `warn` (never `debug` in production)
- [ ] Remove or disable the phpMyAdmin service in `docker-compose.yml`

### Database

- [ ] Use `npx prisma migrate deploy` instead of `migrate dev` in production
- [ ] Enable MySQL SSL/TLS connections
- [ ] Set up automated daily database backups with retention policy
- [ ] Configure connection pooling via `DATABASE_URL` query params:

  ```text
  DATABASE_URL="mysql://user:pass@host:3306/db?connection_limit=20&pool_timeout=10"
  ```

### Infrastructure

- [ ] Deploy using Docker Compose (production profile) or Kubernetes
- [ ] Set up uptime monitoring on `/api/v1/health`
- [ ] Configure Nginx reverse proxy (config provided in `nginx/conf.d/default.conf`)
- [ ] Set up external log aggregation (Winston writes to `./logs/`)
- [ ] Use PM2 as a process manager if not using Docker:

  ```bash
  npm install -g pm2
  pm2 start src/server.js --name nelna-api -i max
  ```

### Performance

- [ ] Enable response compression (already configured in `app.js`)
- [ ] Tune rate limiting values for expected production traffic
- [ ] Activate Redis caching (Redis service included in `docker-compose.yml`)
- [ ] All critical DB columns already have indexes defined in `schema.prisma`

### Monitoring

- [ ] Set up error alerting (Sentry, Datadog, or similar)
- [ ] Monitor MySQL slow queries
- [ ] Track API response times and error rates
- [ ] Configure disk space alerts for uploads and log directories

---

## Useful Commands Reference

### Application

| Command | Description |
| --- | --- |
| `npm run dev` | Start server with hot-reload (nodemon) |
| `npm start` | Start server (production mode) |
| `npm test` | Run all tests with coverage |
| `npm run test:unit` | Run unit tests only |
| `npm run test:integration` | Run integration tests only |
| `npm run lint` | Check code style with ESLint |
| `npm run lint:fix` | Auto-fix ESLint issues |

### Prisma / Database

| Command | Description |
| --- | --- |
| `npx prisma migrate dev` | Create and apply new migrations |
| `npx prisma migrate dev --name X` | Create a named migration |
| `npx prisma migrate reset` | Drop DB, re-run all migrations + seed |
| `npx prisma migrate deploy` | Apply pending migrations (production) |
| `npx prisma db seed` | Run the seed script |
| `npx prisma db pull` | Pull existing DB state into schema |
| `npx prisma db push` | Push schema changes without migration |
| `npx prisma studio` | Open visual DB browser (port 5555) |
| `npx prisma generate` | Regenerate Prisma Client |
| `npx prisma format` | Format schema.prisma file |

### Docker

| Command | Description |
| --- | --- |
| `docker-compose up -d mysql` | Start MySQL container only |
| `docker-compose up -d` | Start all services (MySQL, Redis, API, Nginx) |
| `docker-compose up -d --profile dev` | Include phpMyAdmin for development |
| `docker-compose down` | Stop all containers |
| `docker-compose down -v` | Stop containers and remove volumes (⚠️ deletes data) |
| `docker-compose logs -f mysql` | Stream MySQL container logs |
| `docker-compose ps` | Show running container status |

---

## Quick Start (TL;DR)

```bash
# 1. Start MySQL via Docker
docker-compose up -d mysql

# 2. Configure environment
cd backend
cp .env.example .env
# Edit .env → set DATABASE_URL to:
#   mysql://nelna_user:NelnaPass@2024@localhost:3306/nelna_maintenance

# 3. Install dependencies
npm install

# 4. Run migrations (creates 34 database tables)
npx prisma migrate dev --name init

# 5. Seed default data (roles, permissions, admin user, etc.)
npx prisma db seed

# 6. Start the server
npm run dev

# 7. Verify — should return JSON with success: true
curl http://localhost:3000/api/v1/health
```

**Login:** `admin@nelna.com` / `Admin@123`

---

**Nelna Integrated Maintenance Management System**
Built with Node.js · Express.js · Prisma · MySQL
© 2026 Nelna Company (Pvt) Ltd. All rights reserved.
