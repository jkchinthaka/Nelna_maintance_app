-- ============================================================================
-- NELNA INTEGRATED MAINTENANCE MANAGEMENT SYSTEM
-- SQL Server Database Setup Script
-- Database : NELNA_APP  (nelna_user is db_owner here)
-- Server   : NELNA-BI-SVR\SQLEXPRESS
-- Credentials: User ID=nelna_user  / Password=Nelna@123
--
-- Run via sqlcmd:
--   sqlcmd -S "NELNA-BI-SVR\SQLEXPRESS" -U nelna_user -P "Nelna@123" -C -N
--          -d NELNA_APP -i create_database.sql
-- ============================================================================

USE NELNA_APP;
GO

-- ============================================================================
-- DROP old/conflicting tables in FK-safe order
-- (some belonged to a previous sub-system in this DB)
-- ============================================================================
-- Remove FKs from old tables that reference users/assets so they can be dropped
IF OBJECT_ID('FK__work_sche__creat__01142BA1', 'F')    IS NOT NULL ALTER TABLE work_schedule        DROP CONSTRAINT FK__work_sche__creat__01142BA1;
IF OBJECT_ID('FK__productio__creat__06CD04F7', 'F')    IS NOT NULL ALTER TABLE production_target_new DROP CONSTRAINT FK__productio__creat__06CD04F7;
IF OBJECT_ID('FK__audit_log__user___0A9D95DB', 'F')    IS NOT NULL ALTER TABLE audit_log             DROP CONSTRAINT FK__audit_log__user___0A9D95DB;
IF OBJECT_ID('FK_user_attendance_user', 'F')           IS NOT NULL ALTER TABLE user_attendance       DROP CONSTRAINT FK_user_attendance_user;
IF OBJECT_ID('FK_user_attendance_marked_by', 'F')      IS NOT NULL ALTER TABLE user_attendance       DROP CONSTRAINT FK_user_attendance_marked_by;
IF OBJECT_ID('FK__electrici__creat__70DDC3D8', 'F')    IS NOT NULL ALTER TABLE electricity_data      DROP CONSTRAINT FK__electrici__creat__70DDC3D8;
IF OBJECT_ID('FK__electrici__asset__6FE99F9F', 'F')    IS NOT NULL ALTER TABLE electricity_data      DROP CONSTRAINT FK__electrici__asset__6FE99F9F;
IF OBJECT_ID('FK__users__role_id__66603565', 'F')      IS NOT NULL ALTER TABLE users                 DROP CONSTRAINT FK__users__role_id__66603565;
GO

-- Drop old conflicting core tables (replaced by new comprehensive schema)
IF OBJECT_ID('assets', 'U') IS NOT NULL DROP TABLE assets;
IF OBJECT_ID('users',  'U') IS NOT NULL DROP TABLE users;
IF OBJECT_ID('roles',  'U') IS NOT NULL DROP TABLE roles;
GO

-- ============================================================================
-- DROP new Nelna maintenance tables in reverse dependency order (safe re-run)
-- ============================================================================
IF OBJECT_ID('service_spare_parts',   'U') IS NOT NULL DROP TABLE service_spare_parts;
IF OBJECT_ID('service_tasks',         'U') IS NOT NULL DROP TABLE service_tasks;
IF OBJECT_ID('service_requests',      'U') IS NOT NULL DROP TABLE service_requests;
IF OBJECT_ID('vehicle_drivers',       'U') IS NOT NULL DROP TABLE vehicle_drivers;
IF OBJECT_ID('grn_items',             'U') IS NOT NULL DROP TABLE grn_items;
IF OBJECT_ID('grns',                  'U') IS NOT NULL DROP TABLE grns;
IF OBJECT_ID('purchase_order_items',  'U') IS NOT NULL DROP TABLE purchase_order_items;
IF OBJECT_ID('purchase_orders',       'U') IS NOT NULL DROP TABLE purchase_orders;
IF OBJECT_ID('stock_movements',       'U') IS NOT NULL DROP TABLE stock_movements;
IF OBJECT_ID('asset_transfers',       'U') IS NOT NULL DROP TABLE asset_transfers;
IF OBJECT_ID('asset_repair_logs',     'U') IS NOT NULL DROP TABLE asset_repair_logs;
IF OBJECT_ID('notifications',         'U') IS NOT NULL DROP TABLE notifications;
IF OBJECT_ID('audit_logs',            'U') IS NOT NULL DROP TABLE audit_logs;
IF OBJECT_ID('expenses',              'U') IS NOT NULL DROP TABLE expenses;
IF OBJECT_ID('machine_service_history','U') IS NOT NULL DROP TABLE machine_service_history;
IF OBJECT_ID('amc_contracts',         'U') IS NOT NULL DROP TABLE amc_contracts;
IF OBJECT_ID('breakdown_logs',        'U') IS NOT NULL DROP TABLE breakdown_logs;
IF OBJECT_ID('machine_maintenance_schedules','U') IS NOT NULL DROP TABLE machine_maintenance_schedules;
IF OBJECT_ID('vehicle_service_history','U') IS NOT NULL DROP TABLE vehicle_service_history;
IF OBJECT_ID('fuel_logs',             'U') IS NOT NULL DROP TABLE fuel_logs;
IF OBJECT_ID('vehicle_documents',     'U') IS NOT NULL DROP TABLE vehicle_documents;
IF OBJECT_ID('assets',                'U') IS NOT NULL DROP TABLE assets;
IF OBJECT_ID('machines',              'U') IS NOT NULL DROP TABLE machines;
IF OBJECT_ID('vehicles',              'U') IS NOT NULL DROP TABLE vehicles;
IF OBJECT_ID('products',              'U') IS NOT NULL DROP TABLE products;
IF OBJECT_ID('product_categories',    'U') IS NOT NULL DROP TABLE product_categories;
IF OBJECT_ID('suppliers',             'U') IS NOT NULL DROP TABLE suppliers;
IF OBJECT_ID('system_configs',        'U') IS NOT NULL DROP TABLE system_configs;
IF OBJECT_ID('users',                 'U') IS NOT NULL DROP TABLE users;
IF OBJECT_ID('role_permissions',      'U') IS NOT NULL DROP TABLE role_permissions;
IF OBJECT_ID('permissions',           'U') IS NOT NULL DROP TABLE permissions;
IF OBJECT_ID('roles',                 'U') IS NOT NULL DROP TABLE roles;
IF OBJECT_ID('branches',              'U') IS NOT NULL DROP TABLE branches;
IF OBJECT_ID('companies',             'U') IS NOT NULL DROP TABLE companies;
GO

-- ============================================================================
-- COMPANIES
-- ============================================================================
CREATE TABLE companies (
    id          INT           IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(255) NOT NULL,
    code        NVARCHAR(50)  NOT NULL UNIQUE,
    address     NVARCHAR(MAX) NULL,
    phone       NVARCHAR(20)  NULL,
    email       NVARCHAR(255) NULL,
    logo        NVARCHAR(500) NULL,
    is_active   BIT           NOT NULL DEFAULT 1,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at  DATETIME2     NULL
);
GO

-- ============================================================================
-- BRANCHES
-- ============================================================================
CREATE TABLE branches (
    id          INT           IDENTITY(1,1) PRIMARY KEY,
    company_id  INT           NOT NULL,
    name        NVARCHAR(255) NOT NULL,
    code        NVARCHAR(50)  NOT NULL UNIQUE,
    address     NVARCHAR(MAX) NULL,
    phone       NVARCHAR(20)  NULL,
    email       NVARCHAR(255) NULL,
    is_active   BIT           NOT NULL DEFAULT 1,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at  DATETIME2     NULL,

    CONSTRAINT fk_branches_company FOREIGN KEY (company_id)
        REFERENCES companies (id)
);
CREATE INDEX ix_branches_company_id ON branches (company_id);
GO

-- ============================================================================
-- ROLES
-- ============================================================================
CREATE TABLE roles (
    id           INT           IDENTITY(1,1) PRIMARY KEY,
    name         NVARCHAR(100) NOT NULL UNIQUE,
    display_name NVARCHAR(100) NOT NULL,
    description  NVARCHAR(MAX) NULL,
    is_system    BIT           NOT NULL DEFAULT 0,
    created_at   DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at   DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);
GO

-- ============================================================================
-- PERMISSIONS
-- ============================================================================
CREATE TABLE permissions (
    id          INT           IDENTITY(1,1) PRIMARY KEY,
    module      NVARCHAR(100) NOT NULL,
    action      NVARCHAR(100) NOT NULL,
    resource    NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX) NULL,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT uq_permissions_module_action_resource UNIQUE (module, action, resource)
);
GO

-- ============================================================================
-- ROLE_PERMISSIONS
-- ============================================================================
CREATE TABLE role_permissions (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    role_id       INT NOT NULL,
    permission_id INT NOT NULL,
    CONSTRAINT uq_role_permissions UNIQUE (role_id, permission_id),
    CONSTRAINT fk_rp_role       FOREIGN KEY (role_id)       REFERENCES roles(id)       ON DELETE CASCADE,
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);
GO

-- ============================================================================
-- USERS
-- ============================================================================
CREATE TABLE users (
    id                     INT           IDENTITY(1,1) PRIMARY KEY,
    company_id             INT           NOT NULL,
    branch_id              INT           NULL,
    role_id                INT           NOT NULL,
    employee_id            NVARCHAR(50)  NULL UNIQUE,
    first_name             NVARCHAR(100) NOT NULL,
    last_name              NVARCHAR(100) NOT NULL,
    email                  NVARCHAR(255) NOT NULL UNIQUE,
    password_hash          NVARCHAR(255) NOT NULL,
    phone                  NVARCHAR(20)  NULL,
    avatar                 NVARCHAR(500) NULL,
    is_active              BIT           NOT NULL DEFAULT 1,
    last_login_at          DATETIME2     NULL,
    password_reset_token   NVARCHAR(255) NULL,
    password_reset_expiry  DATETIME2     NULL,
    refresh_token          NVARCHAR(MAX) NULL,
    fcm_token              NVARCHAR(500) NULL,
    created_at             DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at             DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at             DATETIME2     NULL,

    CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_users_branch  FOREIGN KEY (branch_id)  REFERENCES branches(id),
    CONSTRAINT fk_users_role    FOREIGN KEY (role_id)    REFERENCES roles(id)
);
CREATE INDEX ix_users_company_id ON users (company_id);
CREATE INDEX ix_users_branch_id  ON users (branch_id);
CREATE INDEX ix_users_role_id    ON users (role_id);
CREATE INDEX ix_users_email      ON users (email);
GO

-- ============================================================================
-- VEHICLES
-- ============================================================================
CREATE TABLE vehicles (
    id                    INT             IDENTITY(1,1) PRIMARY KEY,
    branch_id             INT             NOT NULL,
    registration_no       NVARCHAR(50)    NOT NULL UNIQUE,
    make                  NVARCHAR(100)   NOT NULL,
    model                 NVARCHAR(100)   NOT NULL,
    year                  INT             NULL,
    engine_no             NVARCHAR(100)   NULL,
    chassis_no            NVARCHAR(100)   NULL,
    fuel_type             NVARCHAR(20)    NOT NULL DEFAULT 'DIESEL'
                              CHECK (fuel_type IN ('PETROL','DIESEL','ELECTRIC','HYBRID','CNG','LPG')),
    vehicle_type          NVARCHAR(50)    NOT NULL,
    color                 NVARCHAR(50)    NULL,
    mileage               DECIMAL(12,2)   NOT NULL DEFAULT 0,
    status                NVARCHAR(30)    NOT NULL DEFAULT 'ACTIVE'
                              CHECK (status IN ('ACTIVE','IN_SERVICE','OUT_OF_SERVICE','DISPOSED','RESERVED')),
    purchase_date         DATETIME2       NULL,
    purchase_price        DECIMAL(12,2)   NULL,
    insurance_expiry      DATETIME2       NULL,
    license_expiry        DATETIME2       NULL,
    last_service_date     DATETIME2       NULL,
    next_service_date     DATETIME2       NULL,
    next_service_mileage  DECIMAL(12,2)   NULL,
    image_url             NVARCHAR(500)   NULL,
    notes                 NVARCHAR(MAX)   NULL,
    created_at            DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    updated_at            DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    deleted_at            DATETIME2       NULL,

    CONSTRAINT fk_vehicles_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
);
CREATE INDEX ix_vehicles_branch_id       ON vehicles (branch_id);
CREATE INDEX ix_vehicles_registration_no ON vehicles (registration_no);
CREATE INDEX ix_vehicles_status          ON vehicles (status);
GO

-- ============================================================================
-- VEHICLE_DOCUMENTS
-- ============================================================================
CREATE TABLE vehicle_documents (
    id          INT           IDENTITY(1,1) PRIMARY KEY,
    vehicle_id  INT           NOT NULL,
    type        NVARCHAR(30)  NOT NULL
                    CHECK (type IN ('INSURANCE','LICENSE','REGISTRATION','EMISSION','FITNESS','PERMIT','OTHER')),
    document_no NVARCHAR(100) NOT NULL,
    issue_date  DATETIME2     NOT NULL,
    expiry_date DATETIME2     NOT NULL,
    provider    NVARCHAR(255) NULL,
    amount      DECIMAL(12,2) NULL,
    file_url    NVARCHAR(500) NULL,
    notes       NVARCHAR(MAX) NULL,
    is_active   BIT           NOT NULL DEFAULT 1,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_vd_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);
CREATE INDEX ix_vd_vehicle_id  ON vehicle_documents (vehicle_id);
CREATE INDEX ix_vd_expiry_date ON vehicle_documents (expiry_date);
GO

-- ============================================================================
-- FUEL_LOGS
-- ============================================================================
CREATE TABLE fuel_logs (
    id          INT           IDENTITY(1,1) PRIMARY KEY,
    vehicle_id  INT           NOT NULL,
    date        DATETIME2     NOT NULL,
    fuel_type   NVARCHAR(20)  NOT NULL
                    CHECK (fuel_type IN ('PETROL','DIESEL','ELECTRIC','HYBRID','CNG','LPG')),
    quantity    DECIMAL(10,2) NOT NULL,
    unit_price  DECIMAL(10,2) NOT NULL,
    total_cost  DECIMAL(12,2) NOT NULL,
    mileage     DECIMAL(12,2) NOT NULL,
    station     NVARCHAR(255) NULL,
    receipt_no  NVARCHAR(100) NULL,
    receipt_url NVARCHAR(500) NULL,
    notes       NVARCHAR(MAX) NULL,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_fl_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);
CREATE INDEX ix_fl_vehicle_id ON fuel_logs (vehicle_id);
CREATE INDEX ix_fl_date       ON fuel_logs (date);
GO

-- ============================================================================
-- VEHICLE_SERVICE_HISTORY
-- ============================================================================
CREATE TABLE vehicle_service_history (
    id                    INT           IDENTITY(1,1) PRIMARY KEY,
    vehicle_id            INT           NOT NULL,
    service_date          DATETIME2     NOT NULL,
    service_type          NVARCHAR(100) NOT NULL,
    description           NVARCHAR(MAX) NOT NULL,
    mileage_at_service    DECIMAL(12,2) NOT NULL,
    cost                  DECIMAL(12,2) NOT NULL,
    service_provider      NVARCHAR(255) NULL,
    invoice_no            NVARCHAR(100) NULL,
    next_service_date     DATETIME2     NULL,
    next_service_mileage  DECIMAL(12,2) NULL,
    notes                 NVARCHAR(MAX) NULL,
    created_at            DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at            DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_vsh_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);
CREATE INDEX ix_vsh_vehicle_id   ON vehicle_service_history (vehicle_id);
CREATE INDEX ix_vsh_service_date ON vehicle_service_history (service_date);
GO

-- ============================================================================
-- MACHINES
-- ============================================================================
CREATE TABLE machines (
    id                     INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id              INT           NOT NULL,
    machine_code           NVARCHAR(50)  NOT NULL UNIQUE,
    name                   NVARCHAR(255) NOT NULL,
    category               NVARCHAR(100) NULL,
    manufacturer           NVARCHAR(255) NULL,
    model_number           NVARCHAR(100) NULL,
    serial_number          NVARCHAR(100) NULL,
    purchase_date          DATETIME2     NULL,
    purchase_price         DECIMAL(12,2) NULL,
    warranty_expiry        DATETIME2     NULL,
    location               NVARCHAR(255) NULL,
    department             NVARCHAR(100) NULL,
    status                 NVARCHAR(30)  NOT NULL DEFAULT 'OPERATIONAL'
                               CHECK (status IN ('OPERATIONAL','UNDER_MAINTENANCE','BREAKDOWN','DECOMMISSIONED','STANDBY')),
    criticality            NVARCHAR(20)  NOT NULL DEFAULT 'MEDIUM'
                               CHECK (criticality IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    operating_hours        DECIMAL(10,2) NOT NULL DEFAULT 0,
    last_maintenance_date  DATETIME2     NULL,
    next_maintenance_date  DATETIME2     NULL,
    maintenance_interval_days INT        NULL,
    qr_code                NVARCHAR(500) NULL,
    image_url              NVARCHAR(500) NULL,
    specifications         NVARCHAR(MAX) NULL,   -- stored as JSON string
    notes                  NVARCHAR(MAX) NULL,
    created_at             DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at             DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at             DATETIME2     NULL,

    CONSTRAINT fk_machines_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
);
CREATE INDEX ix_machines_branch_id   ON machines (branch_id);
CREATE INDEX ix_machines_machine_code ON machines (machine_code);
CREATE INDEX ix_machines_status      ON machines (status);
GO

-- ============================================================================
-- MACHINE_MAINTENANCE_SCHEDULES
-- ============================================================================
CREATE TABLE machine_maintenance_schedules (
    id                    INT           IDENTITY(1,1) PRIMARY KEY,
    machine_id            INT           NOT NULL,
    maintenance_type      NVARCHAR(100) NOT NULL,
    description           NVARCHAR(MAX) NOT NULL,
    frequency_days        INT           NOT NULL,
    frequency_hours       INT           NULL,
    last_performed_date   DATETIME2     NULL,
    next_due_date         DATETIME2     NOT NULL,
    assigned_team         NVARCHAR(100) NULL,
    estimated_duration_minutes INT      NULL,
    estimated_cost        DECIMAL(12,2) NULL,
    is_active             BIT           NOT NULL DEFAULT 1,
    created_at            DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at            DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_mms_machine FOREIGN KEY (machine_id) REFERENCES machines(id)
);
CREATE INDEX ix_mms_machine_id  ON machine_maintenance_schedules (machine_id);
CREATE INDEX ix_mms_next_due    ON machine_maintenance_schedules (next_due_date);
GO

-- ============================================================================
-- BREAKDOWN_LOGS
-- ============================================================================
CREATE TABLE breakdown_logs (
    id               INT           IDENTITY(1,1) PRIMARY KEY,
    machine_id       INT           NOT NULL,
    reported_at      DATETIME2     NOT NULL,
    resolved_at      DATETIME2     NULL,
    severity         NVARCHAR(20)  NOT NULL DEFAULT 'MEDIUM'
                         CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    description      NVARCHAR(MAX) NOT NULL,
    root_cause       NVARCHAR(MAX) NULL,
    resolution       NVARCHAR(MAX) NULL,
    downtime_minutes INT           NULL,
    cost_of_repair   DECIMAL(12,2) NULL,
    reported_by      NVARCHAR(100) NULL,
    resolved_by      NVARCHAR(100) NULL,
    created_at       DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at       DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_bl_machine FOREIGN KEY (machine_id) REFERENCES machines(id)
);
CREATE INDEX ix_bl_machine_id  ON breakdown_logs (machine_id);
CREATE INDEX ix_bl_reported_at ON breakdown_logs (reported_at);
GO

-- ============================================================================
-- AMC_CONTRACTS
-- ============================================================================
CREATE TABLE amc_contracts (
    id               INT           IDENTITY(1,1) PRIMARY KEY,
    machine_id       INT           NOT NULL,
    contract_no      NVARCHAR(100) NOT NULL UNIQUE,
    vendor           NVARCHAR(255) NOT NULL,
    start_date       DATETIME2     NOT NULL,
    end_date         DATETIME2     NOT NULL,
    annual_cost      DECIMAL(12,2) NOT NULL,
    coverage_details NVARCHAR(MAX) NULL,
    contact_person   NVARCHAR(100) NULL,
    contact_phone    NVARCHAR(20)  NULL,
    document_url     NVARCHAR(500) NULL,
    status           NVARCHAR(30)  NOT NULL DEFAULT 'ACTIVE'
                         CHECK (status IN ('ACTIVE','EXPIRED','CANCELLED','PENDING_RENEWAL')),
    created_at       DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at       DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_amc_machine FOREIGN KEY (machine_id) REFERENCES machines(id)
);
CREATE INDEX ix_amc_machine_id ON amc_contracts (machine_id);
CREATE INDEX ix_amc_end_date   ON amc_contracts (end_date);
GO

-- ============================================================================
-- MACHINE_SERVICE_HISTORY
-- ============================================================================
CREATE TABLE machine_service_history (
    id               INT           IDENTITY(1,1) PRIMARY KEY,
    machine_id       INT           NOT NULL,
    service_date     DATETIME2     NOT NULL,
    service_type     NVARCHAR(100) NOT NULL,
    description      NVARCHAR(MAX) NOT NULL,
    hours_at_service DECIMAL(10,2) NULL,
    cost             DECIMAL(12,2) NOT NULL,
    performed_by     NVARCHAR(100) NULL,
    notes            NVARCHAR(MAX) NULL,
    created_at       DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at       DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_msh_machine FOREIGN KEY (machine_id) REFERENCES machines(id)
);
CREATE INDEX ix_msh_machine_id ON machine_service_history (machine_id);
GO

-- ============================================================================
-- ASSETS
-- ============================================================================
CREATE TABLE assets (
    id                INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id         INT           NOT NULL,
    asset_code        NVARCHAR(50)  NOT NULL UNIQUE,
    name              NVARCHAR(255) NOT NULL,
    category          NVARCHAR(100) NOT NULL,
    location          NVARCHAR(255) NULL,
    department        NVARCHAR(100) NULL,
    serial_number     NVARCHAR(100) NULL,
    purchase_date     DATETIME2     NULL,
    purchase_price    DECIMAL(12,2) NULL,
    current_value     DECIMAL(12,2) NULL,
    depreciation_rate DECIMAL(5,2)  NULL,
    warranty_expiry   DATETIME2     NULL,
    condition         NVARCHAR(20)  NOT NULL DEFAULT 'GOOD'
                          CHECK (condition IN ('EXCELLENT','GOOD','FAIR','POOR','DAMAGED','SCRAP')),
    status            NVARCHAR(20)  NOT NULL DEFAULT 'IN_USE'
                          CHECK (status IN ('IN_USE','IN_STORAGE','UNDER_REPAIR','DISPOSED','TRANSFERRED','LOST')),
    assigned_to       NVARCHAR(100) NULL,
    image_url         NVARCHAR(500) NULL,
    notes             NVARCHAR(MAX) NULL,
    created_at        DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at        DATETIME2     NULL,

    CONSTRAINT fk_assets_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
);
CREATE INDEX ix_assets_branch_id  ON assets (branch_id);
CREATE INDEX ix_assets_asset_code ON assets (asset_code);
CREATE INDEX ix_assets_status     ON assets (status);
GO

-- ============================================================================
-- ASSET_REPAIR_LOGS
-- ============================================================================
CREATE TABLE asset_repair_logs (
    id             INT           IDENTITY(1,1) PRIMARY KEY,
    asset_id       INT           NOT NULL,
    repair_date    DATETIME2     NOT NULL,
    description    NVARCHAR(MAX) NOT NULL,
    cost           DECIMAL(12,2) NOT NULL,
    vendor         NVARCHAR(255) NULL,
    completed_date DATETIME2     NULL,
    notes          NVARCHAR(MAX) NULL,
    created_at     DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at     DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_arl_asset FOREIGN KEY (asset_id) REFERENCES assets(id)
);
CREATE INDEX ix_arl_asset_id ON asset_repair_logs (asset_id);
GO

-- ============================================================================
-- ASSET_TRANSFERS
-- ============================================================================
CREATE TABLE asset_transfers (
    id              INT           IDENTITY(1,1) PRIMARY KEY,
    asset_id        INT           NOT NULL,
    from_location   NVARCHAR(255) NOT NULL,
    to_location     NVARCHAR(255) NOT NULL,
    from_department NVARCHAR(100) NULL,
    to_department   NVARCHAR(100) NULL,
    transfer_date   DATETIME2     NOT NULL,
    reason          NVARCHAR(MAX) NULL,
    approved_by     NVARCHAR(100) NULL,
    created_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_at_asset FOREIGN KEY (asset_id) REFERENCES assets(id)
);
CREATE INDEX ix_at_asset_id ON asset_transfers (asset_id);
GO

-- ============================================================================
-- PRODUCT_CATEGORIES (self-referential)
-- ============================================================================
CREATE TABLE product_categories (
    id          INT           IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(255) NOT NULL UNIQUE,
    description NVARCHAR(MAX) NULL,
    parent_id   INT           NULL,
    is_active   BIT           NOT NULL DEFAULT 1,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_pc_parent FOREIGN KEY (parent_id)
        REFERENCES product_categories(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX ix_pc_parent_id ON product_categories (parent_id);
GO

-- ============================================================================
-- SUPPLIERS
-- ============================================================================
CREATE TABLE suppliers (
    id             INT           IDENTITY(1,1) PRIMARY KEY,
    name           NVARCHAR(255) NOT NULL,
    code           NVARCHAR(50)  NOT NULL UNIQUE,
    contact_person NVARCHAR(100) NULL,
    email          NVARCHAR(255) NULL,
    phone          NVARCHAR(20)  NULL,
    address        NVARCHAR(MAX) NULL,
    tax_id         NVARCHAR(50)  NULL,
    bank_details   NVARCHAR(MAX) NULL,
    payment_terms  NVARCHAR(100) NULL,
    rating         INT           NULL DEFAULT 0,
    is_active      BIT           NOT NULL DEFAULT 1,
    created_at     DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at     DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at     DATETIME2     NULL
);
GO

-- ============================================================================
-- PRODUCTS
-- ============================================================================
CREATE TABLE products (
    id              INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id       INT           NOT NULL,
    category_id     INT           NULL,
    sku             NVARCHAR(100) NOT NULL UNIQUE,
    barcode         NVARCHAR(100) NULL UNIQUE,
    name            NVARCHAR(255) NOT NULL,
    description     NVARCHAR(MAX) NULL,
    unit            NVARCHAR(50)  NOT NULL,
    unit_price      DECIMAL(12,2) NOT NULL,
    cost_price      DECIMAL(12,2) NULL,
    current_stock   DECIMAL(12,2) NOT NULL DEFAULT 0,
    minimum_stock   DECIMAL(12,2) NOT NULL DEFAULT 0,
    maximum_stock   DECIMAL(12,2) NULL,
    reorder_level   DECIMAL(12,2) NOT NULL DEFAULT 0,
    reorder_quantity DECIMAL(12,2) NULL,
    location        NVARCHAR(100) NULL,
    image_url       NVARCHAR(500) NULL,
    is_active       BIT           NOT NULL DEFAULT 1,
    created_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at      DATETIME2     NULL,

    CONSTRAINT fk_products_branch   FOREIGN KEY (branch_id)   REFERENCES branches(id),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES product_categories(id)
);
CREATE INDEX ix_products_branch_id    ON products (branch_id);
CREATE INDEX ix_products_category_id  ON products (category_id);
CREATE INDEX ix_products_sku          ON products (sku);
CREATE INDEX ix_products_current_stock ON products (current_stock);
GO

-- ============================================================================
-- STOCK_MOVEMENTS
-- ============================================================================
CREATE TABLE stock_movements (
    id             INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id      INT           NOT NULL,
    product_id     INT           NOT NULL,
    type           NVARCHAR(30)  NOT NULL
                       CHECK (type IN ('STOCK_IN','STOCK_OUT','ADJUSTMENT','TRANSFER','RETURN','DAMAGE','EXPIRED')),
    quantity       DECIMAL(12,2) NOT NULL,
    unit_cost      DECIMAL(12,2) NULL,
    reference_type NVARCHAR(50)  NULL,
    reference_id   INT           NULL,
    reason         NVARCHAR(MAX) NULL,
    previous_stock DECIMAL(12,2) NOT NULL,
    new_stock      DECIMAL(12,2) NOT NULL,
    performed_by   NVARCHAR(100) NULL,
    created_at     DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_sm_branch  FOREIGN KEY (branch_id)  REFERENCES branches(id),
    CONSTRAINT fk_sm_product FOREIGN KEY (product_id) REFERENCES products(id)
);
CREATE INDEX ix_sm_branch_id  ON stock_movements (branch_id);
CREATE INDEX ix_sm_product_id ON stock_movements (product_id);
CREATE INDEX ix_sm_type       ON stock_movements (type);
CREATE INDEX ix_sm_created_at ON stock_movements (created_at);
GO

-- ============================================================================
-- PURCHASE_ORDERS
-- ============================================================================
CREATE TABLE purchase_orders (
    id              INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id       INT           NOT NULL,
    supplier_id     INT           NOT NULL,
    po_number       NVARCHAR(50)  NOT NULL UNIQUE,
    order_date      DATETIME2     NOT NULL,
    expected_date   DATETIME2     NULL,
    status          NVARCHAR(30)  NOT NULL DEFAULT 'DRAFT'
                        CHECK (status IN ('DRAFT','SUBMITTED','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED','CLOSED')),
    subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_amount      DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
    notes           NVARCHAR(MAX) NULL,
    approved_by     NVARCHAR(100) NULL,
    approved_at     DATETIME2     NULL,
    created_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_po_branch   FOREIGN KEY (branch_id)   REFERENCES branches(id),
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE INDEX ix_po_branch_id   ON purchase_orders (branch_id);
CREATE INDEX ix_po_supplier_id ON purchase_orders (supplier_id);
CREATE INDEX ix_po_po_number   ON purchase_orders (po_number);
GO

-- ============================================================================
-- PURCHASE_ORDER_ITEMS
-- ============================================================================
CREATE TABLE purchase_order_items (
    id               INT           IDENTITY(1,1) PRIMARY KEY,
    purchase_order_id INT          NOT NULL,
    product_id       INT           NOT NULL,
    quantity         DECIMAL(12,2) NOT NULL,
    unit_price       DECIMAL(12,2) NOT NULL,
    total_price      DECIMAL(12,2) NOT NULL,
    received_qty     DECIMAL(12,2) NOT NULL DEFAULT 0,

    CONSTRAINT fk_poi_purchase_order FOREIGN KEY (purchase_order_id)
        REFERENCES purchase_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_poi_product FOREIGN KEY (product_id) REFERENCES products(id)
);
CREATE INDEX ix_poi_purchase_order_id ON purchase_order_items (purchase_order_id);
GO

-- ============================================================================
-- GRNS (Goods Received Notes)
-- ============================================================================
CREATE TABLE grns (
    id                INT           IDENTITY(1,1) PRIMARY KEY,
    purchase_order_id INT           NOT NULL,
    supplier_id       INT           NOT NULL,
    grn_number        NVARCHAR(50)  NOT NULL UNIQUE,
    received_date     DATETIME2     NOT NULL,
    invoice_no        NVARCHAR(100) NULL,
    notes             NVARCHAR(MAX) NULL,
    received_by       NVARCHAR(100) NULL,
    status            NVARCHAR(30)  NOT NULL DEFAULT 'PENDING'
                          CHECK (status IN ('PENDING','INSPECTING','ACCEPTED','PARTIALLY_ACCEPTED','REJECTED')),
    created_at        DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at        DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_grn_purchase_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
    CONSTRAINT fk_grn_supplier       FOREIGN KEY (supplier_id)       REFERENCES suppliers(id)
);
CREATE INDEX ix_grn_purchase_order_id ON grns (purchase_order_id);
GO

-- ============================================================================
-- GRN_ITEMS
-- ============================================================================
CREATE TABLE grn_items (
    id           INT           IDENTITY(1,1) PRIMARY KEY,
    grn_id       INT           NOT NULL,
    product_id   INT           NOT NULL,
    ordered_qty  DECIMAL(12,2) NOT NULL,
    received_qty DECIMAL(12,2) NOT NULL,
    accepted_qty DECIMAL(12,2) NOT NULL,
    rejected_qty DECIMAL(12,2) NOT NULL DEFAULT 0,
    reject_reason NVARCHAR(MAX) NULL,
    unit_cost    DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_gi_grn     FOREIGN KEY (grn_id)     REFERENCES grns(id) ON DELETE CASCADE,
    CONSTRAINT fk_gi_product FOREIGN KEY (product_id) REFERENCES products(id)
);
CREATE INDEX ix_gi_grn_id ON grn_items (grn_id);
GO

-- ============================================================================
-- SERVICE_REQUESTS
-- ============================================================================
CREATE TABLE service_requests (
    id              INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id       INT           NOT NULL,
    ticket_no       NVARCHAR(50)  NOT NULL UNIQUE,
    requester_id    INT           NOT NULL,
    approver_id     INT           NULL,
    vehicle_id      INT           NULL,
    machine_id      INT           NULL,
    asset_id        INT           NULL,
    category        NVARCHAR(40)  NOT NULL
                        CHECK (category IN ('VEHICLE_SERVICE','MACHINE_MAINTENANCE','ASSET_REPAIR','PREVENTIVE_MAINTENANCE','EMERGENCY_REPAIR','INSPECTION','GENERAL')),
    priority        NVARCHAR(20)  NOT NULL DEFAULT 'MEDIUM'
                        CHECK (priority IN ('LOW','MEDIUM','HIGH','URGENT','CRITICAL')),
    subject         NVARCHAR(255) NOT NULL,
    description     NVARCHAR(MAX) NOT NULL,
    status          NVARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING','APPROVED','REJECTED','IN_PROGRESS','ON_HOLD','COMPLETED','CLOSED','CANCELLED')),
    approved_at     DATETIME2     NULL,
    rejected_reason NVARCHAR(MAX) NULL,
    estimated_cost  DECIMAL(12,2) NULL,
    actual_cost     DECIMAL(12,2) NULL,
    sla_deadline    DATETIME2     NULL,
    completed_at    DATETIME2     NULL,
    closed_at       DATETIME2     NULL,
    closed_reason   NVARCHAR(MAX) NULL,
    report_url      NVARCHAR(500) NULL,
    created_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    deleted_at      DATETIME2     NULL,

    CONSTRAINT fk_sr_branch    FOREIGN KEY (branch_id)    REFERENCES branches(id),
    CONSTRAINT fk_sr_requester FOREIGN KEY (requester_id) REFERENCES users(id),
    CONSTRAINT fk_sr_approver  FOREIGN KEY (approver_id)  REFERENCES users(id),
    CONSTRAINT fk_sr_vehicle   FOREIGN KEY (vehicle_id)   REFERENCES vehicles(id),
    CONSTRAINT fk_sr_machine   FOREIGN KEY (machine_id)   REFERENCES machines(id),
    CONSTRAINT fk_sr_asset     FOREIGN KEY (asset_id)     REFERENCES assets(id)
);
CREATE INDEX ix_sr_branch_id   ON service_requests (branch_id);
CREATE INDEX ix_sr_requester   ON service_requests (requester_id);
CREATE INDEX ix_sr_status      ON service_requests (status);
CREATE INDEX ix_sr_ticket_no   ON service_requests (ticket_no);
CREATE INDEX ix_sr_sla         ON service_requests (sla_deadline);
GO

-- ============================================================================
-- SERVICE_TASKS
-- ============================================================================
CREATE TABLE service_tasks (
    id                  INT           IDENTITY(1,1) PRIMARY KEY,
    service_request_id  INT           NOT NULL,
    technician_id       INT           NOT NULL,
    task_description    NVARCHAR(MAX) NOT NULL,
    status              NVARCHAR(20)  NOT NULL DEFAULT 'ASSIGNED'
                            CHECK (status IN ('ASSIGNED','IN_PROGRESS','COMPLETED','ON_HOLD','CANCELLED')),
    started_at          DATETIME2     NULL,
    completed_at        DATETIME2     NULL,
    time_spent_minutes  INT           NULL,
    labor_cost          DECIMAL(12,2) NULL,
    notes               NVARCHAR(MAX) NULL,
    created_at          DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at          DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_st_service_request FOREIGN KEY (service_request_id) REFERENCES service_requests(id),
    CONSTRAINT fk_st_technician      FOREIGN KEY (technician_id)      REFERENCES users(id)
);
CREATE INDEX ix_st_service_request_id ON service_tasks (service_request_id);
CREATE INDEX ix_st_technician         ON service_tasks (technician_id);
GO

-- ============================================================================
-- SERVICE_SPARE_PARTS
-- ============================================================================
CREATE TABLE service_spare_parts (
    id                  INT           IDENTITY(1,1) PRIMARY KEY,
    service_request_id  INT           NOT NULL,
    product_id          INT           NOT NULL,
    quantity            DECIMAL(10,2) NOT NULL,
    unit_cost           DECIMAL(12,2) NOT NULL,
    total_cost          DECIMAL(12,2) NOT NULL,
    created_at          DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_ssp_service_request FOREIGN KEY (service_request_id) REFERENCES service_requests(id),
    CONSTRAINT fk_ssp_product         FOREIGN KEY (product_id)         REFERENCES products(id)
);
CREATE INDEX ix_ssp_service_request_id ON service_spare_parts (service_request_id);
GO

-- ============================================================================
-- VEHICLE_DRIVERS
-- ============================================================================
CREATE TABLE vehicle_drivers (
    id            INT           IDENTITY(1,1) PRIMARY KEY,
    vehicle_id    INT           NOT NULL,
    driver_id     INT           NOT NULL,
    assigned_date DATETIME2     NOT NULL,
    released_date DATETIME2     NULL,
    is_active     BIT           NOT NULL DEFAULT 1,
    notes         NVARCHAR(MAX) NULL,
    created_at    DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at    DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_vdr_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    CONSTRAINT fk_vdr_driver  FOREIGN KEY (driver_id)  REFERENCES users(id)
);
CREATE INDEX ix_vdr_vehicle_id ON vehicle_drivers (vehicle_id);
CREATE INDEX ix_vdr_driver_id  ON vehicle_drivers (driver_id);
GO

-- ============================================================================
-- EXPENSES
-- ============================================================================
CREATE TABLE expenses (
    id              INT           IDENTITY(1,1) PRIMARY KEY,
    branch_id       INT           NOT NULL,
    created_by_id   INT           NOT NULL,
    expense_no      NVARCHAR(50)  NOT NULL UNIQUE,
    category        NVARCHAR(30)  NOT NULL
                        CHECK (category IN ('VEHICLE_MAINTENANCE','MACHINE_MAINTENANCE','FUEL','SPARE_PARTS','LABOR','INSURANCE','LICENSE','AMC','ASSET_REPAIR','GENERAL')),
    reference_type  NVARCHAR(50)  NULL,
    reference_id    INT           NULL,
    description     NVARCHAR(MAX) NOT NULL,
    amount          DECIMAL(12,2) NOT NULL,
    date            DATETIME2     NOT NULL,
    invoice_no      NVARCHAR(100) NULL,
    vendor          NVARCHAR(255) NULL,
    receipt_url     NVARCHAR(500) NULL,
    status          NVARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING','APPROVED','REJECTED','PAID')),
    approved_by     NVARCHAR(100) NULL,
    approved_at     DATETIME2     NULL,
    notes           NVARCHAR(MAX) NULL,
    created_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_exp_branch     FOREIGN KEY (branch_id)     REFERENCES branches(id),
    CONSTRAINT fk_exp_created_by FOREIGN KEY (created_by_id) REFERENCES users(id)
);
CREATE INDEX ix_exp_branch_id ON expenses (branch_id);
CREATE INDEX ix_exp_category  ON expenses (category);
CREATE INDEX ix_exp_date      ON expenses (date);
GO

-- ============================================================================
-- AUDIT_LOGS
-- ============================================================================
CREATE TABLE audit_logs (
    id          INT           IDENTITY(1,1) PRIMARY KEY,
    user_id     INT           NULL,
    action      NVARCHAR(50)  NOT NULL,
    module      NVARCHAR(100) NOT NULL,
    entity_type NVARCHAR(100) NOT NULL,
    entity_id   INT           NULL,
    old_values  NVARCHAR(MAX) NULL,   -- stored as JSON string
    new_values  NVARCHAR(MAX) NULL,   -- stored as JSON string
    ip_address  NVARCHAR(45)  NULL,
    user_agent  NVARCHAR(500) NULL,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_al_user FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX ix_al_user_id    ON audit_logs (user_id);
CREATE INDEX ix_al_module     ON audit_logs (module);
CREATE INDEX ix_al_entity     ON audit_logs (entity_type, entity_id);
CREATE INDEX ix_al_created_at ON audit_logs (created_at);
GO

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================
CREATE TABLE notifications (
    id         INT           IDENTITY(1,1) PRIMARY KEY,
    user_id    INT           NOT NULL,
    title      NVARCHAR(255) NOT NULL,
    body       NVARCHAR(MAX) NOT NULL,
    type       NVARCHAR(50)  NOT NULL,
    data       NVARCHAR(MAX) NULL,   -- stored as JSON string
    is_read    BIT           NOT NULL DEFAULT 0,
    read_at    DATETIME2     NULL,
    created_at DATETIME2     NOT NULL DEFAULT GETUTCDATE(),

    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX ix_notif_user_id ON notifications (user_id);
CREATE INDEX ix_notif_is_read ON notifications (is_read);
GO

-- ============================================================================
-- SYSTEM_CONFIGS
-- ============================================================================
CREATE TABLE system_configs (
    id         INT           IDENTITY(1,1) PRIMARY KEY,
    [key]      NVARCHAR(100) NOT NULL UNIQUE,
    value      NVARCHAR(MAX) NOT NULL,
    type       NVARCHAR(20)  NOT NULL DEFAULT 'string',
    module     NVARCHAR(100) NULL,
    created_at DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);
GO

-- ============================================================================
-- SEED: Default Roles
-- ============================================================================
INSERT INTO roles (name, display_name, description, is_system)
VALUES
    ('super_admin',    'Super Admin',        'Full system access',               1),
    ('admin',          'Administrator',      'Company-level administration',     1),
    ('branch_manager', 'Branch Manager',     'Branch-level management',          1),
    ('technician',     'Technician',         'Field technician - service tasks', 1),
    ('driver',         'Driver',             'Vehicle driver',                   1),
    ('store_keeper',   'Store Keeper',       'Inventory / store management',     1),
    ('viewer',         'Viewer',             'Read-only access',                 1);
GO

-- ============================================================================
-- SEED: Default Company and Branch
-- ============================================================================
INSERT INTO companies (name, code, address, email, is_active)
VALUES ('Nelna Company', 'NELNA', 'Sri Lanka', 'admin@nelna.com', 1);

INSERT INTO branches (company_id, name, code, is_active)
VALUES (1, 'Head Office', 'HO-001', 1);
GO

-- ============================================================================
-- SEED: Default Admin User (password: Admin@123)
-- bcrypt hash for "Admin@123" with salt rounds 10
-- ============================================================================
INSERT INTO users (company_id, branch_id, role_id, employee_id, first_name, last_name,
                   email, password_hash, is_active)
VALUES (1, 1, 1, 'EMP-001', 'System', 'Admin',
        'admin@nelna.com',
        '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        1);
GO

PRINT '============================================================';
PRINT 'NELNA database setup completed successfully!';
PRINT 'Tables created: 33';
PRINT 'Default admin: admin@nelna.com / Admin@123';
PRINT '============================================================';
