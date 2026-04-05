const dbName = 'main_app';
const collections = [
  'companies', 'branches', 'roles', 'permissions', 'role_permissions', 'users',
  'vehicles', 'vehicle_documents', 'fuel_logs', 'vehicle_service_history', 'vehicle_drivers',
  'machines', 'machine_maintenance_schedules', 'breakdown_logs', 'amc_contracts', 'machine_service_history',
  'service_requests', 'service_tasks', 'service_spare_parts', 'product_categories', 'products',
  'stock_movements', 'suppliers', 'purchase_orders', 'purchase_order_items', 'grns', 'grn_items',
  'assets', 'asset_repair_logs', 'asset_transfers', 'expenses', 'audit_logs', 'notifications', 'system_configs'
];

const dbRef = db.getSiblingDB(dbName);
const existing = new Set(dbRef.getCollectionNames());
const created = [];

for (const name of collections) {
  if (!existing.has(name)) {
    dbRef.createCollection(name);
    created.push(name);
  }
}

const finalCollections = dbRef.getCollectionNames();
printjson({
  database: dbName,
  createdCount: created.length,
  created,
  totalCollections: finalCollections.length,
});
