// ============================================================================
// Nelna Maintenance System - Asset (Stores) Validators
// ============================================================================
const { body, param, query } = require('express-validator');

const createAssetValidator = [
  body('name').trim().notEmpty().withMessage('Asset name is required'),
  body('branchId').isInt({ min: 1 }).withMessage('Valid branch ID is required'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('location').optional().trim().isLength({ min: 1 }),
  body('department').optional().trim().isLength({ min: 1 }),
  body('serialNumber').optional().trim().isLength({ min: 1 }),
  body('purchaseDate').optional().isISO8601().withMessage('Valid date required'),
  body('purchasePrice').optional().isDecimal().withMessage('Valid price required'),
  body('currentValue').optional().isDecimal().withMessage('Valid value required'),
  body('depreciationRate')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid depreciation rate required (0-100)'),
  body('warrantyExpiry').optional().isISO8601().withMessage('Valid date required'),
  body('condition')
    .optional()
    .isIn(['EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'DAMAGED', 'SCRAP'])
    .withMessage('Invalid asset condition'),
  body('status')
    .optional()
    .isIn(['IN_USE', 'IN_STORAGE', 'UNDER_REPAIR', 'DISPOSED', 'TRANSFERRED', 'LOST'])
    .withMessage('Invalid asset status'),
  body('assignedTo').optional().trim().isLength({ min: 1 }),
  body('imageUrl').optional().trim().isURL().withMessage('Valid URL required'),
  body('notes').optional().trim(),
];

const updateAssetValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid asset ID required'),
  body('name').optional().trim().isLength({ min: 1 }),
  body('category').optional().trim().isLength({ min: 1 }),
  body('location').optional().trim().isLength({ min: 1 }),
  body('department').optional().trim().isLength({ min: 1 }),
  body('serialNumber').optional().trim().isLength({ min: 1 }),
  body('purchaseDate').optional().isISO8601().withMessage('Valid date required'),
  body('purchasePrice').optional().isDecimal().withMessage('Valid price required'),
  body('currentValue').optional().isDecimal().withMessage('Valid value required'),
  body('depreciationRate')
    .optional()
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid depreciation rate required'),
  body('warrantyExpiry').optional().isISO8601().withMessage('Valid date required'),
  body('condition')
    .optional()
    .isIn(['EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'DAMAGED', 'SCRAP'])
    .withMessage('Invalid asset condition'),
  body('status')
    .optional()
    .isIn(['IN_USE', 'IN_STORAGE', 'UNDER_REPAIR', 'DISPOSED', 'TRANSFERRED', 'LOST'])
    .withMessage('Invalid asset status'),
  body('assignedTo').optional().trim().isLength({ min: 1 }),
  body('imageUrl').optional().trim().isURL().withMessage('Valid URL required'),
  body('notes').optional().trim(),
];

const createRepairLogValidator = [
  body('assetId').isInt({ min: 1 }).withMessage('Valid asset ID required'),
  body('repairDate').isISO8601().withMessage('Valid repair date required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('cost').isDecimal().withMessage('Valid cost required'),
  body('vendor').optional().trim().isLength({ min: 1 }),
  body('completedDate').optional().isISO8601().withMessage('Valid completed date required'),
  body('notes').optional().trim(),
];

const createTransferValidator = [
  body('assetId').isInt({ min: 1 }).withMessage('Valid asset ID required'),
  body('fromLocation').trim().notEmpty().withMessage('From location is required'),
  body('toLocation').trim().notEmpty().withMessage('To location is required'),
  body('fromDepartment').optional().trim().isLength({ min: 1 }),
  body('toDepartment').optional().trim().isLength({ min: 1 }),
  body('transferDate').isISO8601().withMessage('Valid transfer date required'),
  body('reason').optional().trim(),
  body('approvedBy').optional().trim().isLength({ min: 1 }),
];

module.exports = {
  createAssetValidator,
  updateAssetValidator,
  createRepairLogValidator,
  createTransferValidator,
};
