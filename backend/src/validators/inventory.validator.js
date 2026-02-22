// ============================================================================
// Nelna Maintenance System - Inventory Validators
// ============================================================================
const { body, param, query } = require('express-validator');

const STOCK_MOVEMENT_TYPES = [
  'STOCK_IN',
  'STOCK_OUT',
  'ADJUSTMENT',
  'TRANSFER',
  'RETURN',
  'DAMAGE',
  'EXPIRED',
];

const PO_STATUSES = [
  'DRAFT',
  'SUBMITTED',
  'APPROVED',
  'PARTIALLY_RECEIVED',
  'RECEIVED',
  'CANCELLED',
  'CLOSED',
];

const GRN_STATUSES = [
  'PENDING',
  'INSPECTING',
  'ACCEPTED',
  'PARTIALLY_ACCEPTED',
  'REJECTED',
];

const UNITS = [
  'PCS', 'KG', 'L', 'M', 'FT', 'SET', 'BOX', 'PACK', 'ROLL', 'PAIR', 'UNIT', 'GAL', 'ML', 'CM', 'IN',
];

// --------------------------------------------------------------------------
// Product validators
// --------------------------------------------------------------------------
const createProductValidator = [
  body('branchId')
    .isInt({ min: 1 })
    .withMessage('Valid branch ID is required'),
  body('categoryId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid category ID required'),
  body('sku')
    .trim()
    .notEmpty()
    .withMessage('SKU is required')
    .isLength({ max: 50 })
    .withMessage('SKU must not exceed 50 characters'),
  body('barcode')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Barcode must not exceed 100 characters'),
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Product name is required')
    .isLength({ max: 255 })
    .withMessage('Product name must not exceed 255 characters'),
  body('description')
    .optional()
    .trim(),
  body('unit')
    .trim()
    .notEmpty()
    .withMessage('Unit is required')
    .isIn(UNITS)
    .withMessage(`Unit must be one of: ${UNITS.join(', ')}`),
  body('unitPrice')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid unit price is required')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Unit price must be non-negative'),
  body('costPrice')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid cost price is required')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Cost price must be non-negative'),
  body('currentStock')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid current stock is required'),
  body('minimumStock')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid minimum stock required'),
  body('maximumStock')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid maximum stock required'),
  body('reorderLevel')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid reorder level required'),
  body('reorderQuantity')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid reorder quantity required'),
  body('location')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('Location must not exceed 255 characters'),
];

const updateProductValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid product ID required'),
  body('categoryId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid category ID required'),
  body('sku')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('SKU cannot be empty')
    .isLength({ max: 50 })
    .withMessage('SKU must not exceed 50 characters'),
  body('barcode')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Barcode must not exceed 100 characters'),
  body('name')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Product name cannot be empty')
    .isLength({ max: 255 })
    .withMessage('Product name must not exceed 255 characters'),
  body('description')
    .optional()
    .trim(),
  body('unit')
    .optional()
    .isIn(UNITS)
    .withMessage(`Unit must be one of: ${UNITS.join(', ')}`),
  body('unitPrice')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid unit price is required')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Unit price must be non-negative'),
  body('costPrice')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid cost price is required')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Cost price must be non-negative'),
  body('minimumStock')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid minimum stock required'),
  body('maximumStock')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid maximum stock required'),
  body('reorderLevel')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid reorder level required'),
  body('reorderQuantity')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid reorder quantity required'),
  body('location')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('Location must not exceed 255 characters'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean'),
];

// --------------------------------------------------------------------------
// Stock movement validators
// --------------------------------------------------------------------------
const stockInValidator = [
  body('productId')
    .isInt({ min: 1 })
    .withMessage('Valid product ID is required'),
  body('quantity')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid quantity is required')
    .custom((value) => parseFloat(value) > 0)
    .withMessage('Quantity must be greater than zero'),
  body('unitCost')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid unit cost required'),
  body('referenceType')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Reference type must not exceed 50 characters'),
  body('referenceId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid reference ID required'),
  body('reason')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Reason must not exceed 500 characters'),
];

const stockOutValidator = [
  body('productId')
    .isInt({ min: 1 })
    .withMessage('Valid product ID is required'),
  body('quantity')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid quantity is required')
    .custom((value) => parseFloat(value) > 0)
    .withMessage('Quantity must be greater than zero'),
  body('referenceType')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Reference type must not exceed 50 characters'),
  body('referenceId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid reference ID required'),
  body('reason')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Reason must not exceed 500 characters'),
];

// --------------------------------------------------------------------------
// Category validators
// --------------------------------------------------------------------------
const createCategoryValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Category name is required')
    .isLength({ max: 100 })
    .withMessage('Category name must not exceed 100 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description must not exceed 500 characters'),
  body('parentId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid parent category ID required'),
];

// --------------------------------------------------------------------------
// Supplier validators
// --------------------------------------------------------------------------
const createSupplierValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Supplier name is required')
    .isLength({ max: 255 })
    .withMessage('Supplier name must not exceed 255 characters'),
  body('code')
    .trim()
    .notEmpty()
    .withMessage('Supplier code is required')
    .isLength({ max: 50 })
    .withMessage('Supplier code must not exceed 50 characters'),
  body('contactPerson')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('Contact person must not exceed 255 characters'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Valid email address required')
    .normalizeEmail(),
  body('phone')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Phone must not exceed 20 characters'),
  body('address')
    .optional()
    .trim(),
  body('taxId')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Tax ID must not exceed 50 characters'),
  body('bankDetails')
    .optional()
    .trim(),
  body('paymentTerms')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Payment terms must not exceed 100 characters'),
  body('rating')
    .optional()
    .isFloat({ min: 0, max: 5 })
    .withMessage('Rating must be between 0 and 5'),
];

const updateSupplierValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid supplier ID required'),
  body('name')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Supplier name cannot be empty')
    .isLength({ max: 255 })
    .withMessage('Supplier name must not exceed 255 characters'),
  body('code')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Supplier code cannot be empty')
    .isLength({ max: 50 })
    .withMessage('Supplier code must not exceed 50 characters'),
  body('contactPerson')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('Contact person must not exceed 255 characters'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Valid email address required')
    .normalizeEmail(),
  body('phone')
    .optional()
    .trim()
    .isLength({ max: 20 })
    .withMessage('Phone must not exceed 20 characters'),
  body('address')
    .optional()
    .trim(),
  body('taxId')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Tax ID must not exceed 50 characters'),
  body('bankDetails')
    .optional()
    .trim(),
  body('paymentTerms')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Payment terms must not exceed 100 characters'),
  body('rating')
    .optional()
    .isFloat({ min: 0, max: 5 })
    .withMessage('Rating must be between 0 and 5'),
];

// --------------------------------------------------------------------------
// Purchase Order validators
// --------------------------------------------------------------------------
const createPurchaseOrderValidator = [
  body('branchId')
    .isInt({ min: 1 })
    .withMessage('Valid branch ID is required'),
  body('supplierId')
    .isInt({ min: 1 })
    .withMessage('Valid supplier ID is required'),
  body('orderDate')
    .optional()
    .isISO8601()
    .withMessage('Valid order date is required (ISO 8601)'),
  body('expectedDate')
    .optional()
    .isISO8601()
    .withMessage('Valid expected date is required (ISO 8601)'),
  body('taxAmount')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid tax amount required'),
  body('discountAmount')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid discount amount required'),
  body('items')
    .isArray({ min: 1 })
    .withMessage('At least one item is required'),
  body('items.*.productId')
    .isInt({ min: 1 })
    .withMessage('Valid product ID is required for each item'),
  body('items.*.quantity')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid quantity is required for each item')
    .custom((value) => parseFloat(value) > 0)
    .withMessage('Quantity must be greater than zero'),
  body('items.*.unitPrice')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid unit price is required for each item')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Unit price must be non-negative'),
];

// --------------------------------------------------------------------------
// GRN validators
// --------------------------------------------------------------------------
const createGRNValidator = [
  body('purchaseOrderId')
    .isInt({ min: 1 })
    .withMessage('Valid purchase order ID is required'),
  body('supplierId')
    .isInt({ min: 1 })
    .withMessage('Valid supplier ID is required'),
  body('receivedDate')
    .optional()
    .isISO8601()
    .withMessage('Valid received date required (ISO 8601)'),
  body('invoiceNo')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Invoice number must not exceed 100 characters'),
  body('items')
    .isArray({ min: 1 })
    .withMessage('At least one item is required'),
  body('items.*.productId')
    .isInt({ min: 1 })
    .withMessage('Valid product ID is required for each item'),
  body('items.*.orderedQty')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid ordered quantity is required')
    .custom((value) => parseFloat(value) > 0)
    .withMessage('Ordered quantity must be greater than zero'),
  body('items.*.receivedQty')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid received quantity is required')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Received quantity must be non-negative'),
  body('items.*.acceptedQty')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid accepted quantity is required')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Accepted quantity must be non-negative'),
  body('items.*.rejectedQty')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid rejected quantity required')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Rejected quantity must be non-negative'),
  body('items.*.rejectReason')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Reject reason must not exceed 500 characters'),
  body('items.*.unitCost')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid unit cost is required for each item')
    .custom((value) => parseFloat(value) >= 0)
    .withMessage('Unit cost must be non-negative'),
];

// --------------------------------------------------------------------------
// List / query validators
// --------------------------------------------------------------------------
const listQueryValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('branchId').optional().isInt({ min: 1 }).withMessage('Valid branch ID required'),
  query('categoryId').optional().isInt({ min: 1 }).withMessage('Valid category ID required'),
  query('lowStock').optional().isBoolean().withMessage('lowStock must be a boolean'),
  query('search').optional().trim(),
  query('sortBy').optional().trim(),
  query('sortOrder').optional().isIn(['asc', 'desc']).withMessage('Sort order must be asc or desc'),
];

module.exports = {
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
};
