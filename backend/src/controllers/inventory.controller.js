// ============================================================================
// Nelna Maintenance System - Inventory Controller
// ============================================================================
const inventoryService = require('../services/inventory.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class InventoryController {
  // ==========================================================================
  // PRODUCTS
  // ==========================================================================

  getAllProducts = asyncHandler(async (req, res) => {
    const result = await inventoryService.getAllProducts(req.query, req.user);
    ApiResponse.paginated(res, result.products, result.pagination);
  });

  getProductById = asyncHandler(async (req, res) => {
    const product = await inventoryService.getProductById(parseInt(req.params.id, 10));
    ApiResponse.success(res, product);
  });

  createProduct = asyncHandler(async (req, res) => {
    const product = await inventoryService.createProduct(req.body, req.user);
    ApiResponse.created(res, product, 'Product created successfully');
  });

  updateProduct = asyncHandler(async (req, res) => {
    const product = await inventoryService.updateProduct(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, product, 'Product updated successfully');
  });

  deleteProduct = asyncHandler(async (req, res) => {
    await inventoryService.deleteProduct(parseInt(req.params.id, 10));
    ApiResponse.success(res, null, 'Product deleted successfully');
  });

  // ==========================================================================
  // CATEGORIES
  // ==========================================================================

  getAllCategories = asyncHandler(async (req, res) => {
    const categories = await inventoryService.getAllCategories();
    ApiResponse.success(res, categories);
  });

  createCategory = asyncHandler(async (req, res) => {
    const category = await inventoryService.createCategory(req.body);
    ApiResponse.created(res, category, 'Category created successfully');
  });

  updateCategory = asyncHandler(async (req, res) => {
    const category = await inventoryService.updateCategory(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, category, 'Category updated successfully');
  });

  // ==========================================================================
  // STOCK MOVEMENTS
  // ==========================================================================

  stockIn = asyncHandler(async (req, res) => {
    const result = await inventoryService.stockIn(req.body, req.user);
    ApiResponse.created(res, result, 'Stock in recorded successfully');
  });

  stockOut = asyncHandler(async (req, res) => {
    const result = await inventoryService.stockOut(req.body, req.user);
    ApiResponse.created(res, result, 'Stock out recorded successfully');
  });

  adjustStock = asyncHandler(async (req, res) => {
    const result = await inventoryService.adjustStock(req.body, req.user);
    ApiResponse.success(res, result, 'Stock adjusted successfully');
  });

  getStockMovements = asyncHandler(async (req, res) => {
    const result = await inventoryService.getStockMovements(
      parseInt(req.params.productId, 10),
      req.query
    );
    ApiResponse.paginated(res, result.movements, result.pagination);
  });

  getLowStockAlerts = asyncHandler(async (req, res) => {
    const result = await inventoryService.getLowStockAlerts(req.query, req.user);
    ApiResponse.paginated(res, result.products, result.pagination);
  });

  // ==========================================================================
  // SUPPLIERS
  // ==========================================================================

  getAllSuppliers = asyncHandler(async (req, res) => {
    const result = await inventoryService.getAllSuppliers(req.query);
    ApiResponse.paginated(res, result.suppliers, result.pagination);
  });

  getSupplierById = asyncHandler(async (req, res) => {
    const supplier = await inventoryService.getSupplierById(parseInt(req.params.id, 10));
    ApiResponse.success(res, supplier);
  });

  createSupplier = asyncHandler(async (req, res) => {
    const supplier = await inventoryService.createSupplier(req.body, req.user);
    ApiResponse.created(res, supplier, 'Supplier created successfully');
  });

  updateSupplier = asyncHandler(async (req, res) => {
    const supplier = await inventoryService.updateSupplier(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, supplier, 'Supplier updated successfully');
  });

  deleteSupplier = asyncHandler(async (req, res) => {
    await inventoryService.deleteSupplier(parseInt(req.params.id, 10));
    ApiResponse.success(res, null, 'Supplier deleted successfully');
  });

  // ==========================================================================
  // PURCHASE ORDERS
  // ==========================================================================

  getAllPurchaseOrders = asyncHandler(async (req, res) => {
    const result = await inventoryService.getAllPurchaseOrders(req.query, req.user);
    ApiResponse.paginated(res, result.purchaseOrders, result.pagination);
  });

  getPurchaseOrderById = asyncHandler(async (req, res) => {
    const po = await inventoryService.getPurchaseOrderById(parseInt(req.params.id, 10));
    ApiResponse.success(res, po);
  });

  createPurchaseOrder = asyncHandler(async (req, res) => {
    const po = await inventoryService.createPurchaseOrder(req.body, req.user);
    ApiResponse.created(res, po, 'Purchase order created successfully');
  });

  updatePOStatus = asyncHandler(async (req, res) => {
    const po = await inventoryService.updatePOStatus(
      parseInt(req.params.id, 10),
      req.body.status
    );
    ApiResponse.success(res, po, 'Purchase order status updated successfully');
  });

  approvePO = asyncHandler(async (req, res) => {
    const po = await inventoryService.approvePO(parseInt(req.params.id, 10), req.user.id);
    ApiResponse.success(res, po, 'Purchase order approved successfully');
  });

  // ==========================================================================
  // GRN
  // ==========================================================================

  createGRN = asyncHandler(async (req, res) => {
    const grn = await inventoryService.createGRN(req.body, req.user);
    ApiResponse.created(res, grn, 'GRN created successfully');
  });

  getGRNsByPO = asyncHandler(async (req, res) => {
    const grns = await inventoryService.getGRNsByPO(parseInt(req.params.poId, 10));
    ApiResponse.success(res, grns);
  });
}

module.exports = new InventoryController();
