// ============================================================================
// Nelna Maintenance System - Vehicle Validators
// ============================================================================
const { body, param, query } = require('express-validator');

const createVehicleValidator = [
  body('registrationNo').trim().notEmpty().withMessage('Registration number is required'),
  body('make').trim().notEmpty().withMessage('Make is required'),
  body('model').trim().notEmpty().withMessage('Model is required'),
  body('vehicleType').trim().notEmpty().withMessage('Vehicle type is required'),
  body('branchId').isInt({ min: 1 }).withMessage('Valid branch ID is required'),
  body('year').optional().isInt({ min: 1900, max: 2100 }).withMessage('Valid year required'),
  body('fuelType').optional().isIn(['PETROL', 'DIESEL', 'ELECTRIC', 'HYBRID', 'CNG', 'LPG']),
  body('purchaseDate').optional().isISO8601().withMessage('Valid date required'),
  body('purchasePrice').optional().isDecimal().withMessage('Valid price required'),
  body('insuranceExpiry').optional().isISO8601().withMessage('Valid date required'),
  body('licenseExpiry').optional().isISO8601().withMessage('Valid date required'),
];

const updateVehicleValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid vehicle ID required'),
  body('make').optional().trim().isLength({ min: 1 }),
  body('model').optional().trim().isLength({ min: 1 }),
  body('year').optional().isInt({ min: 1900, max: 2100 }),
  body('fuelType').optional().isIn(['PETROL', 'DIESEL', 'ELECTRIC', 'HYBRID', 'CNG', 'LPG']),
  body('status').optional().isIn(['ACTIVE', 'IN_SERVICE', 'OUT_OF_SERVICE', 'DISPOSED', 'RESERVED']),
];

const fuelLogValidator = [
  body('vehicleId').isInt({ min: 1 }).withMessage('Valid vehicle ID required'),
  body('date').isISO8601().withMessage('Valid date required'),
  body('fuelType').isIn(['PETROL', 'DIESEL', 'ELECTRIC', 'HYBRID', 'CNG', 'LPG']),
  body('quantity').isDecimal({ decimal_digits: '0,2' }).withMessage('Valid quantity required'),
  body('unitPrice').isDecimal({ decimal_digits: '0,2' }).withMessage('Valid unit price required'),
  body('totalCost').isDecimal({ decimal_digits: '0,2' }).withMessage('Valid total cost required'),
  body('mileage').isDecimal({ decimal_digits: '0,2' }).withMessage('Valid mileage required'),
];

const documentValidator = [
  body('vehicleId').isInt({ min: 1 }).withMessage('Valid vehicle ID required'),
  body('type').isIn(['INSURANCE', 'LICENSE', 'REGISTRATION', 'EMISSION', 'FITNESS', 'PERMIT', 'OTHER']),
  body('documentNo').trim().notEmpty().withMessage('Document number is required'),
  body('issueDate').isISO8601().withMessage('Valid issue date required'),
  body('expiryDate').isISO8601().withMessage('Valid expiry date required'),
];

const driverAssignValidator = [
  body('vehicleId').isInt({ min: 1 }).withMessage('Valid vehicle ID required'),
  body('driverId').isInt({ min: 1 }).withMessage('Valid driver ID required'),
  body('assignedDate').isISO8601().withMessage('Valid assigned date required'),
];

module.exports = {
  createVehicleValidator,
  updateVehicleValidator,
  fuelLogValidator,
  documentValidator,
  driverAssignValidator,
};
