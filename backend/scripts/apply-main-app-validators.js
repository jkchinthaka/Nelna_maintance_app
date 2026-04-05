const dbName =
  (typeof process !== 'undefined' && process.env.MAIN_APP_MONGODB_DB_NAME) ||
  'main_app';

const dbRef = db.getSiblingDB(dbName);

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
const failed = [];

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
    failed.push({
      collection: collectionName,
      reason: (error && error.errmsg) || String(error),
    });
  }
}

printjson({
  database: dbName,
  appliedCount: applied.length,
  applied,
  failedCount: failed.length,
  failed,
});

if (failed.length > 0) {
  quit(1);
}
