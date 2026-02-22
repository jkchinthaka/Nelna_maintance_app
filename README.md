# Nelna Integrated Maintenance Management System

> Enterprise-grade maintenance management solution for Nelna Company (Pvt) Ltd.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Frontend                         │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐  │
│  │Dashboard │ Vehicles │ Machines │ Services │ Reports  │  │
│  ├──────────┼──────────┼──────────┼──────────┼──────────┤  │
│  │Inventory │  Stores  │   Auth   │  Admin   │  RBAC    │  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘  │
│          Clean Architecture + Riverpod State Mgmt          │
└────────────────────────┬────────────────────────────────────┘
                         │ REST API (HTTPS)
┌────────────────────────┴────────────────────────────────────┐
│                     Nginx Reverse Proxy                      │
│            Rate Limiting · Gzip · SSL · Security             │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────────────┐
│                   Node.js + Express API                      │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐  │
│  │  Auth    │ Vehicles │ Machines │ Services │ Inventory│  │
│  ├──────────┼──────────┼──────────┼──────────┼──────────┤  │
│  │  Assets  │ Reports  │  Notify  │ Scheduler│  Audit   │  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘  │
│    JWT Auth · RBAC · Validation · Error Handling · Logger   │
└───────────┬─────────────────────────────┬───────────────────┘
            │                             │
┌───────────┴──────────┐   ┌──────────────┴──────────────────┐
│   MySQL 8.0          │   │       Redis 7                    │
│   Prisma ORM         │   │    Session Cache                 │
│   30+ Models         │   │    Rate Limiting                 │
│   Soft Deletes       │   │                                  │
└──────────────────────┘   └─────────────────────────────────┘
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Flutter 3.2+ (Dart) |
| State Management | flutter_riverpod |
| Navigation | go_router |
| HTTP Client | dio |
| Charts | fl_chart |
| Backend | Node.js 20 + Express.js |
| ORM | Prisma 5 |
| Database | MySQL 8.0 |
| Cache | Redis 7 |
| Auth | JWT (bcryptjs) |
| Reverse Proxy | Nginx |
| Containerization | Docker + Docker Compose |
| Logging | Winston |
| Scheduling | node-cron |

## Modules

| Module | Description |
|--------|-------------|
| **Authentication** | Login, token refresh, RBAC, password management |
| **Dashboard** | KPIs, monthly trends, service stats, activity feed |
| **Vehicles** | Fleet management, fuel logs, documents, drivers, cost analytics |
| **Machines** | Equipment management, maintenance schedules, breakdowns, AMC contracts |
| **Services** | Service requests, tasks, spare parts, SLA tracking, approvals |
| **Inventory** | Products, suppliers, purchase orders, GRN, stock management |
| **Stores/Assets** | Asset tracking, depreciation, repair logs, transfers |
| **Reports** | Maintenance, vehicle, inventory, expense analytics with PDF/Excel export |

## User Roles

| Role | Access Level |
|------|-------------|
| Super Admin | Full system access |
| Company Admin | Company-wide management |
| Maintenance Manager | Service requests, assignments, approvals |
| Technician | Assigned tasks, breakdowns, updates |
| Store Manager | Inventory, assets, purchase orders |
| Driver | Assigned vehicles, fuel logs |
| Finance Officer | Reports, expenses, purchase approvals |

---

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 20+ (for local development)
- Flutter SDK 3.2+ (for mobile development)
- MySQL 8.0 (if running without Docker)

### 1. Clone & Configure

```bash
git clone <repository-url>
cd Nelna_maintance_app

# Copy environment file
cp .env.example .env
# Edit .env with your settings
```

### 2. Start with Docker (Recommended)

```bash
# Start all services
docker-compose up -d

# Start with phpMyAdmin for development
docker-compose --profile dev up -d

# Run database migrations
docker-compose run --rm migrate
```

Access points:
- **API**: http://localhost:3000
- **Nginx Proxy**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081 (dev profile)

### 3. Start Backend Locally

```bash
cd backend

# Install dependencies
npm install

# Setup database
npx prisma migrate dev --name init
npx prisma db seed

# Start development server
npm run dev
```

### 4. Start Flutter App

```bash
cd frontend

# Get dependencies
flutter pub get

# Run code generation (freezed, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome
```

### Default Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Super Admin | admin@nelna.com | Admin@123 |
| Maintenance Manager | manager@nelna.com | Manager@123 |
| Technician | tech@nelna.com | Tech@123 |
| Store Manager | store@nelna.com | Store@123 |
| Driver | driver@nelna.com | Driver@123 |
| Finance Officer | finance@nelna.com | Finance@123 |

---

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/auth/refresh-token` | Refresh JWT |
| POST | `/api/v1/auth/logout` | Logout |
| GET | `/api/v1/auth/profile` | Get profile |
| PUT | `/api/v1/auth/profile` | Update profile |
| PUT | `/api/v1/auth/change-password` | Change password |
| POST | `/api/v1/auth/users` | Create user (admin) |
| GET | `/api/v1/auth/users` | List users (admin) |
| PUT | `/api/v1/auth/users/:id` | Update user (admin) |
| DELETE | `/api/v1/auth/users/:id` | Delete user (admin) |
| GET | `/api/v1/auth/roles` | List roles |

### Vehicles
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/vehicles` | List vehicles |
| POST | `/api/v1/vehicles` | Create vehicle |
| GET | `/api/v1/vehicles/:id` | Get vehicle |
| PUT | `/api/v1/vehicles/:id` | Update vehicle |
| DELETE | `/api/v1/vehicles/:id` | Delete vehicle |
| POST | `/api/v1/vehicles/:id/fuel-logs` | Add fuel log |
| GET | `/api/v1/vehicles/:id/fuel-logs` | Get fuel logs |
| POST | `/api/v1/vehicles/:id/documents` | Add document |
| POST | `/api/v1/vehicles/:id/assign-driver` | Assign driver |
| GET | `/api/v1/vehicles/reminders` | Service reminders |
| GET | `/api/v1/vehicles/:id/cost-analytics` | Cost analytics |

### Machines
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/machines` | List machines |
| POST | `/api/v1/machines` | Create machine |
| GET | `/api/v1/machines/:id` | Get machine |
| PUT | `/api/v1/machines/:id` | Update machine |
| DELETE | `/api/v1/machines/:id` | Delete machine |
| GET | `/api/v1/machines/:id/schedules` | Maintenance schedules |
| POST | `/api/v1/machines/:id/schedules` | Create schedule |
| PUT | `/api/v1/machines/schedules/:id` | Update schedule |
| GET | `/api/v1/machines/:id/breakdowns` | Breakdown logs |
| POST | `/api/v1/machines/:id/breakdowns` | Report breakdown |
| PUT | `/api/v1/machines/breakdowns/:id` | Update breakdown |
| GET | `/api/v1/machines/:id/amc-contracts` | AMC contracts |
| POST | `/api/v1/machines/:id/amc-contracts` | Create AMC |
| GET | `/api/v1/machines/upcoming-maintenance` | Upcoming maintenance |

### Service Requests
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/services` | List service requests |
| POST | `/api/v1/services` | Create request |
| GET | `/api/v1/services/:id` | Get request |
| PUT | `/api/v1/services/:id` | Update request |
| PUT | `/api/v1/services/:id/approve` | Approve request |
| PUT | `/api/v1/services/:id/reject` | Reject request |
| PUT | `/api/v1/services/:id/complete` | Complete request |
| GET | `/api/v1/services/:id/tasks` | Get tasks |
| POST | `/api/v1/services/:id/tasks` | Create task |
| PUT | `/api/v1/services/tasks/:id` | Update task |
| GET | `/api/v1/services/:id/spare-parts` | Get spare parts |
| POST | `/api/v1/services/:id/spare-parts` | Add spare part |
| GET | `/api/v1/services/sla-metrics` | SLA metrics |
| GET | `/api/v1/services/my-requests` | My requests |

### Inventory
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/inventory/products` | List products |
| POST | `/api/v1/inventory/products` | Create product |
| GET | `/api/v1/inventory/products/:id` | Get product |
| PUT | `/api/v1/inventory/products/:id` | Update product |
| DELETE | `/api/v1/inventory/products/:id` | Delete product |
| GET | `/api/v1/inventory/categories` | List categories |
| POST | `/api/v1/inventory/categories` | Create category |
| GET | `/api/v1/inventory/suppliers` | List suppliers |
| POST | `/api/v1/inventory/suppliers` | Create supplier |
| PUT | `/api/v1/inventory/suppliers/:id` | Update supplier |
| GET | `/api/v1/inventory/purchase-orders` | List POs |
| POST | `/api/v1/inventory/purchase-orders` | Create PO |
| GET | `/api/v1/inventory/purchase-orders/:id` | Get PO |
| PUT | `/api/v1/inventory/purchase-orders/:id` | Update PO |
| PUT | `/api/v1/inventory/purchase-orders/:id/approve` | Approve PO |
| POST | `/api/v1/inventory/grn` | Create GRN |
| GET | `/api/v1/inventory/grn/:poId` | Get GRNs for PO |
| GET | `/api/v1/inventory/products/:id/stock-movements` | Stock movements |
| POST | `/api/v1/inventory/products/:id/adjust-stock` | Adjust stock |
| GET | `/api/v1/inventory/stock-alerts` | Low stock alerts |

### Assets/Stores
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/assets` | List assets |
| POST | `/api/v1/assets` | Create asset |
| GET | `/api/v1/assets/:id` | Get asset |
| PUT | `/api/v1/assets/:id` | Update asset |
| PUT | `/api/v1/assets/:id/dispose` | Dispose asset |
| GET | `/api/v1/assets/:id/repair-logs` | Repair logs |
| POST | `/api/v1/assets/:id/repair-logs` | Create repair log |
| PUT | `/api/v1/assets/repair-logs/:id` | Update repair log |
| GET | `/api/v1/assets/transfers` | List transfers |
| POST | `/api/v1/assets/transfers` | Create transfer |
| PUT | `/api/v1/assets/transfers/:id/approve` | Approve transfer |
| GET | `/api/v1/assets/depreciation-summary` | Depreciation summary |

### Reports
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/reports/maintenance` | Maintenance report |
| GET | `/api/v1/reports/vehicles` | Vehicle report |
| GET | `/api/v1/reports/inventory` | Inventory report |
| GET | `/api/v1/reports/expenses` | Expense report |
| GET | `/api/v1/reports/export/:type` | Export report (PDF/Excel) |

---

## Database Schema (ER Overview)

### Core Entities
- **Company** → has many Branches
- **Branch** → has many Users, Vehicles, Machines, Products, Assets
- **User** → belongs to Role, has Permissions via RolePermissions
- **Role** → has many Permissions (super_admin, company_admin, maintenance_manager, technician, store_manager, driver, finance_officer)

### Vehicle Management
- **Vehicle** → has many FuelLogs, VehicleDocuments, VehicleDrivers, VehicleServiceHistory

### Machine Management
- **Machine** → has many MaintenanceSchedules, BreakdownLogs, AMCContracts, MachineServiceHistory

### Service Management
- **ServiceRequest** → has many ServiceTasks, ServiceSpareParts
- **ServiceTask** → assigned to User
- **ServiceSparePart** → references Product

### Inventory Management
- **ProductCategory** → has many Products
- **Product** → has many StockMovements
- **Supplier** → has many PurchaseOrders
- **PurchaseOrder** → has many PurchaseOrderItems, GRNs
- **GRN** → has many GRNItems

### Asset Management
- **Asset** → has many AssetRepairLogs, AssetTransfers

### System
- **AuditLog** → tracks all user actions
- **Notification** → in-app notifications with read status
- **SystemConfig** → key-value system configuration
- **Expense** → financial tracking

---

## Project Structure

```
Nelna_maintance_app/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── nginx/
│   ├── nginx.conf
│   ├── conf.d/
│   └── ssl/
├── backend/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── .gitignore
│   ├── .env.example
│   ├── package.json
│   ├── prisma/
│   │   ├── schema.prisma          # 30+ models, 15+ enums
│   │   └── seed.js                # Roles, permissions, default data
│   └── src/
│       ├── server.js              # Entry point
│       ├── app.js                 # Express setup
│       ├── config/
│       │   ├── index.js           # Central config
│       │   ├── database.js        # Prisma client singleton
│       │   └── logger.js          # Winston logger
│       ├── middleware/
│       │   ├── auth.js            # JWT + RBAC
│       │   ├── errorHandler.js    # Global error handler
│       │   ├── validate.js        # Express-validator
│       │   └── auditLog.js        # Action audit trail
│       ├── utils/
│       │   ├── errors.js          # Custom error classes
│       │   ├── apiResponse.js     # Standardized responses
│       │   ├── asyncHandler.js    # Async wrapper
│       │   ├── helpers.js         # Utility functions
│       │   └── scheduler.js       # Cron jobs
│       ├── validators/            # express-validator schemas
│       ├── services/              # Business logic
│       ├── controllers/           # Request handlers
│       └── routes/                # Route definitions
└── frontend/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants/         # API & app constants
        │   ├── errors/            # Failure & exception classes
        │   ├── network/           # Dio API client
        │   ├── theme/             # Material 3 theme
        │   ├── routing/           # GoRouter config
        │   ├── extensions/        # Dart extensions
        │   └── widgets/           # Shared widgets
        └── features/
            ├── auth/              # Login, splash, auth state
            ├── dashboard/         # KPIs, charts, activity
            ├── vehicles/          # Fleet management
            ├── machines/          # Equipment management
            ├── services/          # Service requests
            ├── inventory/         # Stock management
            ├── stores/            # Asset management
            └── reports/           # Analytics & export
```

---

## Development Commands

### Backend
```bash
cd backend
npm install                          # Install dependencies
npm run dev                          # Start with nodemon (hot reload)
npm start                            # Start production
npx prisma studio                    # Open Prisma GUI
npx prisma migrate dev --name <name> # Create migration
npx prisma db seed                   # Seed database
npx prisma generate                  # Regenerate client
```

### Frontend
```bash
cd frontend
flutter pub get                      # Get dependencies
flutter run                          # Run on connected device
flutter run -d chrome                # Run on web
flutter build apk --release          # Build Android APK
flutter build ios --release          # Build iOS
flutter build web --release          # Build web
flutter test                         # Run tests
```

### Docker
```bash
docker-compose up -d                 # Start all services
docker-compose --profile dev up -d   # Start with phpMyAdmin
docker-compose down                  # Stop all services
docker-compose logs -f api           # Follow API logs
docker-compose exec api sh           # Shell into API container
docker-compose run --rm migrate      # Run migrations
```

---

## Security Features

- **JWT Authentication** with access + refresh tokens
- **Role-Based Access Control** (7 roles, 160+ permissions)
- **Rate Limiting** (general + auth-specific)
- **Helmet.js** security headers
- **CORS** configuration
- **Input Validation** on all endpoints (express-validator)
- **SQL Injection Protection** via Prisma ORM
- **Soft Deletes** preserving data integrity
- **Audit Logging** for all write operations
- **Password Hashing** with bcryptjs (10 salt rounds)
- **File Upload Validation** (type, size, sanitization)

---

## Scheduled Tasks (Cron)

| Schedule | Task | Description |
|----------|------|-------------|
| Daily 8:00 AM | Vehicle Reminders | Insurance/license expiry, overdue services |
| Daily 7:00 AM | Machine Maintenance | Upcoming/overdue maintenance checks |
| Daily 9:00 AM | Low Stock Alerts | Products below reorder point |
| Hourly | SLA Breach Check | Service requests approaching/exceeding SLA |
| Monthly 1st | AMC Expiry Check | Contracts expiring within 30 days |

---

## License

Proprietary - Nelna Company (Pvt) Ltd. All rights reserved.
