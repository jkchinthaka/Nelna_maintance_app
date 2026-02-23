// ============================================================================
// Nelna Maintenance System - Database Seed Script
// ============================================================================
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...\n');

  // Guard: skip seeding if database already has roles (i.e. already seeded)
  const existingRoleCount = await prisma.role.count();
  if (existingRoleCount > 0) {
    console.log('⏭️  Database already seeded (found ' + existingRoleCount + ' roles). Skipping.\n');
    return;
  }

  // ========================================================================
  // 1. Create Roles (with stable IDs)
  // ========================================================================
  console.log('Creating roles...');

  // Reset auto-increment and upsert with explicit IDs for stability
  const roleDefinitions = [
    { id: 1, name: 'super_admin', displayName: 'Super Admin', description: 'Full system access — can manage everything including roles and users across all branches' },
    { id: 2, name: 'company_admin', displayName: 'Company Admin', description: 'Company-level administration — manages branches, users, and all operational data' },
    { id: 3, name: 'maintenance_manager', displayName: 'Maintenance Manager', description: 'Manages vehicles, machines, and service requests — approves maintenance work' },
    { id: 4, name: 'technician', displayName: 'Technician', description: 'Performs maintenance tasks — can view and update assigned service requests' },
    { id: 5, name: 'store_manager', displayName: 'Store Manager', description: 'Manages inventory, suppliers, purchase orders, and asset tracking' },
    { id: 6, name: 'driver', displayName: 'Driver', description: 'Vehicle driver — can view assigned vehicles and raise service requests' },
    { id: 7, name: 'finance_officer', displayName: 'Finance Officer', description: 'Manages expenses, reviews reports, and oversees purchase approvals' },
  ];

  // Fresh database — insert roles directly with explicit stable IDs
  for (const def of roleDefinitions) {
    await prisma.$executeRawUnsafe(
      `INSERT INTO roles (id, name, display_name, description, is_system, created_at, updated_at)
       VALUES ($1, $2, $3, $4, true, NOW(), NOW())
       ON CONFLICT (id) DO NOTHING`,
      def.id, def.name, def.displayName, def.description
    );
  }
  // Ensure PostgreSQL sequence starts after our last stable ID
  await prisma.$executeRawUnsafe(`SELECT setval(pg_get_serial_sequence('roles', 'id'), (SELECT MAX(id) FROM roles))`);

  const roles = await prisma.role.findMany({ orderBy: { id: 'asc' } });
  console.log(`  ✅ ${roles.length} roles created (IDs 1-7 stable)`);

  // ========================================================================
  // 2. Create Permissions
  // ========================================================================
  console.log('Creating permissions...');
  const modules = [
    { module: 'vehicles', resources: ['vehicle', 'fuel_log', 'vehicle_document', 'vehicle_driver', 'vehicle_analytics'] },
    { module: 'machines', resources: ['machine', 'maintenance_schedule', 'breakdown', 'amc_contract', 'machine_analytics'] },
    { module: 'services', resources: ['service_request', 'service_task', 'service_spare_part'] },
    { module: 'inventory', resources: ['product', 'category', 'stock', 'supplier', 'purchase_order', 'grn'] },
    { module: 'assets', resources: ['asset', 'repair_log', 'asset_transfer'] },
    { module: 'reports', resources: ['dashboard', 'report'] },
    { module: 'users', resources: ['user', 'role'] },
    { module: 'system', resources: ['audit_log', 'notification', 'config'] },
  ];
  const actions = ['create', 'read', 'update', 'delete'];

  const permData = [];
  for (const mod of modules) {
    for (const resource of mod.resources) {
      for (const action of actions) {
        permData.push({
          module: mod.module,
          action,
          resource,
          description: `${action} ${resource} in ${mod.module}`,
        });
      }
    }
  }
  await prisma.permission.createMany({ data: permData, skipDuplicates: true });
  console.log(`  ✅ ${permData.length} permissions created`);

  // ========================================================================
  // 3. Assign Permissions to Roles (batch operations for Supabase compat)
  // ========================================================================
  console.log('Assigning permissions to roles...');
  const superAdminRole = roles[0];
  const allPermissions = await prisma.permission.findMany();

  // Helper: batch-assign permissions to a role
  async function assignPerms(role, perms) {
    await prisma.rolePermission.createMany({
      data: perms.map(p => ({ roleId: role.id, permissionId: p.id })),
      skipDuplicates: true,
    });
  }

  // Super Admin & Company Admin — all permissions
  await assignPerms(superAdminRole, allPermissions);
  await assignPerms(roles[1], allPermissions);

  // Maintenance Manager — vehicles, machines, services, assets (full), reports+inventory (read)
  const mmPerms = await prisma.permission.findMany({
    where: { OR: [
      { module: { in: ['vehicles', 'machines', 'services', 'assets'] } },
      { module: 'reports', action: 'read' },
      { module: 'inventory', action: 'read' },
    ]},
  });
  await assignPerms(roles[2], mmPerms);

  // Technician — services (read, update), vehicles+machines (read)
  const techPerms = await prisma.permission.findMany({
    where: { OR: [
      { module: 'services', action: { in: ['read', 'update'] } },
      { module: { in: ['vehicles', 'machines'] }, action: 'read' },
    ]},
  });
  await assignPerms(roles[3], techPerms);

  // Store Manager — inventory+assets (full), reports (read)
  const smPerms = await prisma.permission.findMany({
    where: { OR: [
      { module: { in: ['inventory', 'assets'] } },
      { module: 'reports', action: 'read' },
    ]},
  });
  await assignPerms(roles[4], smPerms);

  // Driver — vehicles (read), services (create, read)
  const driverPerms = await prisma.permission.findMany({
    where: { OR: [
      { module: 'vehicles', action: 'read' },
      { module: 'services', action: { in: ['create', 'read'] } },
    ]},
  });
  await assignPerms(roles[5], driverPerms);

  // Finance Officer — reports (full), inventory+services+vehicles+machines (read)
  const finPerms = await prisma.permission.findMany({
    where: { OR: [
      { module: 'reports' },
      { module: { in: ['inventory', 'services', 'vehicles', 'machines'] }, action: 'read' },
    ]},
  });
  await assignPerms(roles[6], finPerms);

  const totalRolePerms = await prisma.rolePermission.count();
  console.log(`  ✅ ${totalRolePerms} role-permission assignments created`);

  // ========================================================================
  // 4. Create Default Company and Branch
  // ========================================================================
  console.log('Creating default company and branch...');
  const company = await prisma.company.upsert({
    where: { code: 'NELNA' },
    update: {},
    create: {
      name: 'Nelna Company (Pvt) Ltd',
      code: 'NELNA',
      address: 'Colombo, Sri Lanka',
      phone: '+94112345678',
      email: 'admin@nelna.com',
    },
  });

  const branch = await prisma.branch.upsert({
    where: { code: 'NELNA-HQ' },
    update: {},
    create: {
      companyId: company.id,
      name: 'Head Office',
      code: 'NELNA-HQ',
      address: 'Colombo 03, Sri Lanka',
      phone: '+94112345678',
      email: 'hq@nelna.com',
    },
  });

  const branch2 = await prisma.branch.upsert({
    where: { code: 'NELNA-FY' },
    update: {},
    create: {
      companyId: company.id,
      name: 'Factory Branch',
      code: 'NELNA-FY',
      address: 'Horana, Sri Lanka',
      phone: '+94342265000',
      email: 'factory@nelna.com',
    },
  });
  console.log('  ✅ Company and branches created');

  // ========================================================================
  // 5. Create Default Users
  // ========================================================================
  console.log('Creating default users...');
  const passwordHash = await bcrypt.hash('Admin@123', 12);

  const defaultUsers = [
    { employeeId: 'EMP001', firstName: 'System', lastName: 'Administrator', email: 'admin@nelna.com', roleId: superAdminRole.id, branchId: branch.id },
    { employeeId: 'EMP002', firstName: 'Kamal', lastName: 'Perera', email: 'kamal@nelna.com', roleId: roles[2].id, branchId: branch.id },
    { employeeId: 'EMP003', firstName: 'Nimal', lastName: 'Silva', email: 'nimal@nelna.com', roleId: roles[3].id, branchId: branch.id },
    { employeeId: 'EMP004', firstName: 'Sunil', lastName: 'Fernando', email: 'sunil@nelna.com', roleId: roles[4].id, branchId: branch.id },
    { employeeId: 'EMP005', firstName: 'Ruwan', lastName: 'Jayasena', email: 'ruwan@nelna.com', roleId: roles[5].id, branchId: branch.id },
    { employeeId: 'EMP006', firstName: 'Chamari', lastName: 'Wijesinghe', email: 'chamari@nelna.com', roleId: roles[6].id, branchId: branch.id },
  ];

  for (const userData of defaultUsers) {
    await prisma.user.upsert({
      where: { email: userData.email },
      update: { roleId: userData.roleId },
      create: {
        companyId: company.id,
        branchId: userData.branchId,
        roleId: userData.roleId,
        employeeId: userData.employeeId,
        firstName: userData.firstName,
        lastName: userData.lastName,
        email: userData.email,
        passwordHash,
        isActive: true,
      },
    });
  }
  console.log(`  ✅ ${defaultUsers.length} users created (password: Admin@123)`);

  // ========================================================================
  // 6. Create Sample Product Categories
  // ========================================================================
  console.log('Creating product categories...');
  const categories = [
    'Spare Parts', 'Lubricants & Oils', 'Filters', 'Electrical Parts',
    'Belts & Hoses', 'Safety Equipment', 'Cleaning Supplies', 'Tools',
    'Bearings & Seals', 'Hydraulic Parts',
  ];
  for (const name of categories) {
    await prisma.productCategory.upsert({
      where: { name },
      update: {},
      create: { name, description: `${name} category` },
    });
  }
  console.log(`  ✅ ${categories.length} categories created`);

  // ========================================================================
  // 7. Create System Configs
  // ========================================================================
  console.log('Creating system configurations...');
  const configs = [
    { key: 'system.currency', value: 'LKR', type: 'string', module: 'system' },
    { key: 'system.date_format', value: 'YYYY-MM-DD', type: 'string', module: 'system' },
    { key: 'vehicle.service_reminder_days', value: '30', type: 'number', module: 'vehicles' },
    { key: 'vehicle.insurance_reminder_days', value: '30', type: 'number', module: 'vehicles' },
    { key: 'inventory.low_stock_alert', value: 'true', type: 'boolean', module: 'inventory' },
    { key: 'service.sla_low_hours', value: '72', type: 'number', module: 'services' },
    { key: 'service.sla_medium_hours', value: '48', type: 'number', module: 'services' },
    { key: 'service.sla_high_hours', value: '24', type: 'number', module: 'services' },
    { key: 'service.sla_urgent_hours', value: '8', type: 'number', module: 'services' },
    { key: 'service.sla_critical_hours', value: '4', type: 'number', module: 'services' },
  ];
  for (const cfg of configs) {
    await prisma.systemConfig.upsert({
      where: { key: cfg.key },
      update: {},
      create: cfg,
    });
  }
  console.log(`  ✅ ${configs.length} system configs created`);

  console.log('\n✅ Database seeding completed successfully!\n');
  console.log('Default Login Credentials:');
  console.log('  Email: admin@nelna.com');
  console.log('  Password: Admin@123');
  console.log('');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
