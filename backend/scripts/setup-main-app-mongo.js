const dbName =
  (typeof process !== 'undefined' && process.env.MAIN_APP_MONGODB_DB_NAME) ||
  'main_app';

const collections = [
  'companies',
  'branches',
  'roles',
  'permissions',
  'role_permissions',
  'users',
  'vehicles',
  'vehicle_documents',
  'fuel_logs',
  'vehicle_service_history',
  'vehicle_drivers',
  'machines',
  'machine_maintenance_schedules',
  'breakdown_logs',
  'amc_contracts',
  'machine_service_history',
  'service_requests',
  'service_tasks',
  'service_spare_parts',
  'product_categories',
  'products',
  'stock_movements',
  'suppliers',
  'purchase_orders',
  'purchase_order_items',
  'grns',
  'grn_items',
  'assets',
  'asset_repair_logs',
  'asset_transfers',
  'expenses',
  'audit_logs',
  'notifications',
  'system_configs',
];

const dbRef = db.getSiblingDB(dbName);

function ensureCollections() {
  const existing = new Set(dbRef.getCollectionNames());
  const created = [];

  for (const name of collections) {
    if (!existing.has(name)) {
      dbRef.createCollection(name);
      created.push(name);
    }
  }

  return created;
}

function applyValidators() {
  const validators = {
    companies: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['id', 'name', 'code', 'created_at', 'updated_at'],
        properties: {
          id: { bsonType: 'int' },
          name: { bsonType: 'string', minLength: 2 },
          code: { bsonType: 'string', minLength: 2 },
          is_active: { bsonType: 'bool' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
    branches: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['id', 'company_id', 'name', 'code', 'created_at', 'updated_at'],
        properties: {
          id: { bsonType: 'int' },
          company_id: { bsonType: 'int' },
          name: { bsonType: 'string' },
          code: { bsonType: 'string' },
          is_active: { bsonType: 'bool' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
    roles: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['id', 'name', 'display_name', 'created_at', 'updated_at'],
        properties: {
          id: { bsonType: 'int' },
          name: { bsonType: 'string' },
          display_name: { bsonType: 'string' },
          is_system: { bsonType: 'bool' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
    permissions: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['id', 'module', 'action', 'resource', 'created_at'],
        properties: {
          id: { bsonType: 'int' },
          module: { bsonType: 'string' },
          action: { bsonType: 'string' },
          resource: { bsonType: 'string' },
          created_at: { bsonType: 'date' },
        },
      },
    },
    users: {
      $jsonSchema: {
        bsonType: 'object',
        required: [
          'id',
          'company_id',
          'role_id',
          'first_name',
          'last_name',
          'email',
          'password_hash',
          'created_at',
          'updated_at',
        ],
        properties: {
          id: { bsonType: 'int' },
          company_id: { bsonType: 'int' },
          branch_id: { bsonType: ['int', 'null'] },
          role_id: { bsonType: 'int' },
          first_name: { bsonType: 'string' },
          last_name: { bsonType: 'string' },
          email: { bsonType: 'string' },
          password_hash: { bsonType: 'string' },
          is_active: { bsonType: 'bool' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
    vehicles: {
      $jsonSchema: {
        bsonType: 'object',
        required: [
          'id',
          'branch_id',
          'registration_no',
          'make',
          'model',
          'fuel_type',
          'vehicle_type',
          'status',
          'created_at',
          'updated_at',
        ],
        properties: {
          id: { bsonType: 'int' },
          branch_id: { bsonType: 'int' },
          registration_no: { bsonType: 'string' },
          make: { bsonType: 'string' },
          model: { bsonType: 'string' },
          fuel_type: { bsonType: 'string' },
          vehicle_type: { bsonType: 'string' },
          status: { bsonType: 'string' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
    machines: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['id', 'branch_id', 'name', 'status', 'created_at', 'updated_at'],
        properties: {
          id: { bsonType: 'int' },
          branch_id: { bsonType: 'int' },
          name: { bsonType: 'string' },
          status: { bsonType: 'string' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
    products: {
      $jsonSchema: {
        bsonType: 'object',
        required: [
          'id',
          'branch_id',
          'category_id',
          'name',
          'sku',
          'unit',
          'created_at',
          'updated_at',
        ],
        properties: {
          id: { bsonType: 'int' },
          branch_id: { bsonType: 'int' },
          category_id: { bsonType: 'int' },
          name: { bsonType: 'string' },
          sku: { bsonType: 'string' },
          unit: { bsonType: 'string' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
    service_requests: {
      $jsonSchema: {
        bsonType: 'object',
        required: [
          'id',
          'branch_id',
          'request_no',
          'title',
          'status',
          'priority',
          'requested_by',
          'created_at',
          'updated_at',
        ],
        properties: {
          id: { bsonType: 'int' },
          branch_id: { bsonType: 'int' },
          request_no: { bsonType: 'string' },
          title: { bsonType: 'string' },
          status: { bsonType: 'string' },
          priority: { bsonType: 'string' },
          requested_by: { bsonType: 'int' },
          created_at: { bsonType: 'date' },
          updated_at: { bsonType: 'date' },
        },
      },
    },
  };

  const applied = [];
  const skipped = [];
  for (const [collectionName, validator] of Object.entries(validators)) {
    try {
      dbRef.runCommand({
        collMod: collectionName,
        validator,
        validationLevel: 'moderate',
        validationAction: 'error',
      });
      applied.push(collectionName);
    } catch (error) {
      skipped.push({
        collection: collectionName,
        reason: (error && error.errmsg) || String(error),
      });
    }
  }

  return { applied, skipped };
}

function ensureIndexes() {
  const indexSpecs = [
    { collection: 'companies', keys: { code: 1 }, options: { unique: true, name: 'uq_companies_code' } },
    { collection: 'branches', keys: { code: 1 }, options: { unique: true, name: 'uq_branches_code' } },
    { collection: 'roles', keys: { name: 1 }, options: { unique: true, name: 'uq_roles_name' } },
    {
      collection: 'permissions',
      keys: { module: 1, action: 1, resource: 1 },
      options: { unique: true, name: 'uq_permissions_module_action_resource' },
    },
    { collection: 'users', keys: { email: 1 }, options: { unique: true, name: 'uq_users_email' } },
    { collection: 'vehicles', keys: { registration_no: 1 }, options: { unique: true, name: 'uq_vehicles_registration_no' } },
    { collection: 'products', keys: { sku: 1 }, options: { unique: true, name: 'uq_products_sku' } },
    { collection: 'service_requests', keys: { request_no: 1 }, options: { unique: true, name: 'uq_service_requests_request_no' } },
  ];

  for (const spec of indexSpecs) {
    dbRef.getCollection(spec.collection).createIndex(spec.keys, spec.options);
  }

  return indexSpecs.length;
}

function seedData() {
  const now = new Date();

  dbRef.companies.updateOne(
    { code: 'NELNA-HQ' },
    {
      $setOnInsert: {
        id: 1,
        name: 'Nelna Maintenance Pvt Ltd',
        code: 'NELNA-HQ',
        address: 'Colombo, Sri Lanka',
        phone: '+94-11-0000000',
        email: 'admin@nelna.com',
        is_active: true,
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.branches.updateOne(
    { code: 'NELNA-CMB' },
    {
      $setOnInsert: {
        id: 1,
        company_id: 1,
        name: 'Colombo Main Branch',
        code: 'NELNA-CMB',
        address: 'Colombo 03, Sri Lanka',
        phone: '+94-11-1111111',
        email: 'branch@nelna.com',
        is_active: true,
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.roles.updateOne(
    { name: 'admin' },
    {
      $setOnInsert: {
        id: 1,
        name: 'admin',
        display_name: 'System Administrator',
        description: 'Full system access',
        is_system: true,
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.permissions.updateOne(
    { module: 'system', action: 'manage', resource: 'all' },
    {
      $setOnInsert: {
        id: 1,
        module: 'system',
        action: 'manage',
        resource: 'all',
        description: 'Full access to all modules',
        created_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.role_permissions.updateOne(
    { role_id: 1, permission_id: 1 },
    {
      $setOnInsert: {
        id: 1,
        role_id: 1,
        permission_id: 1,
      },
    },
    { upsert: true }
  );

  dbRef.users.updateOne(
    { email: 'admin@nelna.com' },
    {
      $setOnInsert: {
        id: 1,
        company_id: 1,
        branch_id: 1,
        role_id: 1,
        employee_id: 'EMP-0001',
        first_name: 'System',
        last_name: 'Admin',
        email: 'admin@nelna.com',
        password_hash: '$2a$10$d9f4f7NvA9Q2Q9C3wVkiWOnWqR9L8xN0X1hLa0Pk0fM2oJv8X0sQa',
        phone: '+94-77-0000000',
        is_active: true,
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.product_categories.updateOne(
    { name: 'Spare Parts' },
    {
      $setOnInsert: {
        id: 1,
        branch_id: 1,
        name: 'Spare Parts',
        description: 'General spare parts inventory',
        is_active: true,
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.products.updateOne(
    { sku: 'SP-ENG-001' },
    {
      $setOnInsert: {
        id: 1,
        branch_id: 1,
        category_id: 1,
        name: 'Engine Oil 5W-30',
        sku: 'SP-ENG-001',
        unit: 'LITER',
        min_stock: 10,
        max_stock: 100,
        current_stock: 50,
        unit_cost: 2500,
        selling_price: 3000,
        is_active: true,
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.vehicles.updateOne(
    { registration_no: 'CAB-1234' },
    {
      $setOnInsert: {
        id: 1,
        branch_id: 1,
        registration_no: 'CAB-1234',
        make: 'Toyota',
        model: 'Hiace',
        year: 2021,
        fuel_type: 'DIESEL',
        vehicle_type: 'VAN',
        mileage: NumberDecimal('55000.00'),
        status: 'ACTIVE',
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.machines.updateOne(
    { name: 'Hydraulic Press #1' },
    {
      $setOnInsert: {
        id: 1,
        branch_id: 1,
        name: 'Hydraulic Press #1',
        machine_code: 'MCH-001',
        status: 'ACTIVE',
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  dbRef.service_requests.updateOne(
    { request_no: 'SR-0001' },
    {
      $setOnInsert: {
        id: 1,
        branch_id: 1,
        request_no: 'SR-0001',
        title: 'Routine vehicle service',
        description: 'Periodic maintenance for CAB-1234',
        priority: 'MEDIUM',
        status: 'OPEN',
        requested_by: 1,
        created_at: now,
        updated_at: now,
      },
    },
    { upsert: true }
  );

  return {
    companies: dbRef.companies.countDocuments(),
    branches: dbRef.branches.countDocuments(),
    roles: dbRef.roles.countDocuments(),
    permissions: dbRef.permissions.countDocuments(),
    users: dbRef.users.countDocuments(),
    product_categories: dbRef.product_categories.countDocuments(),
    products: dbRef.products.countDocuments(),
    vehicles: dbRef.vehicles.countDocuments(),
    machines: dbRef.machines.countDocuments(),
    service_requests: dbRef.service_requests.countDocuments(),
  };
}

const createdCollections = ensureCollections();
const validatorResult = applyValidators();
const indexCount = ensureIndexes();
const counts = seedData();

printjson({
  database: dbName,
  createdCollectionsCount: createdCollections.length,
  createdCollections,
  validatorAppliedCount: validatorResult.applied.length,
  validatorApplied: validatorResult.applied,
  validatorSkippedCount: validatorResult.skipped.length,
  validatorSkipped: validatorResult.skipped,
  indexesEnsured: indexCount,
  sampleCounts: counts,
  totalCollections: dbRef.getCollectionNames().length,
});
