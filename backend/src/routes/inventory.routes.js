// ============================================================================
// Nelna Maintenance System - Inventory Routes
// ============================================================================
const { Router } = require('express');
const inventoryController = require('../controllers/inventory.controller');
const { authenticate, checkPermission } = require('../middleware/auth');
const validate = require('../middleware/validate');
const {
  createProductValidator,
  updateProductValidator,
  stockInValidator,
  stockOutValidator,
  createCategoryValidator,
  createSupplierValidator,
  updateSupplierValidator,
  createPurchaseOrderValidator,
  createGRNValidator,
  listQueryValidator,
} = require('../validators/inventory.validator');

const router = Router();

// All inventory routes require authentication
router.use(authenticate);

// --------------------------------------------------------------------------
// Low Stock Alerts (before /:id to avoid route conflicts)
// --------------------------------------------------------------------------
router.get(
  '/low-stock-alerts',
  checkPermission('inventory', 'read', 'stock_alert'),
  listQueryValidator,
  validate,
  inventoryController.getLowStockAlerts
);

// --------------------------------------------------------------------------
// Product Categories
// --------------------------------------------------------------------------
router.get(
  '/categories',
  checkPermission('inventory', 'read', 'product_category'),
  inventoryController.getAllCategories
);

router.post(
  '/categories',
  checkPermission('inventory', 'create', 'product_category'),
  createCategoryValidator,
  validate,
  inventoryController.createCategory
);

router.put(
  '/categories/:id',
  checkPermission('inventory', 'update', 'product_category'),
  createCategoryValidator,
  validate,
  inventoryController.updateCategory
);

// --------------------------------------------------------------------------
// Stock Movements
// --------------------------------------------------------------------------
router.post(
  '/stock/in',
  checkPermission('inventory', 'create', 'stock_movement'),
  stockInValidator,
  validate,
  inventoryController.stockIn
);

router.post(
  '/stock/out',
  checkPermission('inventory', 'create', 'stock_movement'),
  stockOutValidator,
  validate,
  inventoryController.stockOut
);

router.post(
  '/stock/adjust',
  checkPermission('inventory', 'update', 'stock_movement'),
  stockInValidator,
  validate,
  inventoryController.adjustStock
);

router.get(
  '/stock/movements/:productId',
  checkPermission('inventory', 'read', 'stock_movement'),
  listQueryValidator,
  validate,
  inventoryController.getStockMovements
);

// --------------------------------------------------------------------------
// Suppliers
// --------------------------------------------------------------------------
router.get(
  '/suppliers',
  checkPermission('inventory', 'read', 'supplier'),
  listQueryValidator,
  validate,
  inventoryController.getAllSuppliers
);

router.get(
  '/suppliers/:id',
  checkPermission('inventory', 'read', 'supplier'),
  inventoryController.getSupplierById
);

router.post(
  '/suppliers',
  checkPermission('inventory', 'create', 'supplier'),
  createSupplierValidator,
  validate,
  inventoryController.createSupplier
);

router.put(
  '/suppliers/:id',
  checkPermission('inventory', 'update', 'supplier'),
  updateSupplierValidator,
  validate,
  inventoryController.updateSupplier
);

router.delete(
  '/suppliers/:id',
  checkPermission('inventory', 'delete', 'supplier'),
  inventoryController.deleteSupplier
);

// --------------------------------------------------------------------------
// Purchase Orders
// --------------------------------------------------------------------------
router.get(
  '/purchase-orders',
  checkPermission('inventory', 'read', 'purchase_order'),
  listQueryValidator,
  validate,
  inventoryController.getAllPurchaseOrders
);

router.get(
  '/purchase-orders/:id',
  checkPermission('inventory', 'read', 'purchase_order'),
  inventoryController.getPurchaseOrderById
);

router.post(
  '/purchase-orders',
  checkPermission('inventory', 'create', 'purchase_order'),
  createPurchaseOrderValidator,
  validate,
  inventoryController.createPurchaseOrder
);

router.put(
  '/purchase-orders/:id/status',
  checkPermission('inventory', 'update', 'purchase_order'),
  inventoryController.updatePOStatus
);

router.put(
  '/purchase-orders/:id/approve',
  checkPermission('inventory', 'update', 'purchase_order_approval'),
  inventoryController.approvePO
);

// --------------------------------------------------------------------------
// GRN (Goods Received Notes)
// --------------------------------------------------------------------------
router.post(
  '/grn',
  checkPermission('inventory', 'create', 'grn'),
  createGRNValidator,
  validate,
  inventoryController.createGRN
);

router.get(
  '/grn/po/:poId',
  checkPermission('inventory', 'read', 'grn'),
  inventoryController.getGRNsByPO
);

// --------------------------------------------------------------------------
// Products (CRUD — placed last so /products/:id doesn't catch other routes)
// --------------------------------------------------------------------------
router.get(
  '/products',
  checkPermission('inventory', 'read', 'product'),
  listQueryValidator,
  validate,
  inventoryController.getAllProducts
);

router.get(
  '/products/:id',
  checkPermission('inventory', 'read', 'product'),
  inventoryController.getProductById
);

router.post(
  '/products',
  checkPermission('inventory', 'create', 'product'),
  createProductValidator,
  validate,
  inventoryController.createProduct
);

router.put(
  '/products/:id',
  checkPermission('inventory', 'update', 'product'),
  updateProductValidator,
  validate,
  inventoryController.updateProduct
);

router.delete(
  '/products/:id',
  checkPermission('inventory', 'delete', 'product'),
  inventoryController.deleteProduct
);

module.exports = router;
