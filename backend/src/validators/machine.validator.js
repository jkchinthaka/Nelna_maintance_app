// ============================================================================
// Nelna Maintenance System - Machine Validators
// ============================================================================
const { body, param, query } = require('express-validator');

const createMachineValidator = [
  body('machineCode').trim().notEmpty().withMessage('Machine code is required'),
  body('name').trim().notEmpty().withMessage('Machine name is required'),
  body('branchId').isInt({ min: 1 }).withMessage('Valid branch ID is required'),
  body('category').optional().trim().isLength({ min: 1 }),
  body('manufacturer').optional().trim().isLength({ min: 1 }),
  body('modelNumber').optional().trim().isLength({ min: 1 }),
  body('serialNumber').optional().trim().isLength({ min: 1 }),
  body('purchaseDate').optional().isISO8601().withMessage('Valid date required'),
  body('purchasePrice').optional().isDecimal().withMessage('Valid price required'),
  body('warrantyExpiry').optional().isISO8601().withMessage('Valid date required'),
  body('location').optional().trim().isLength({ min: 1 }),
  body('department').optional().trim().isLength({ min: 1 }),
  body('status').optional().isIn(['OPERATIONAL', 'UNDER_MAINTENANCE', 'BREAKDOWN', 'DECOMMISSIONED', 'STANDBY']).withMessage('Invalid machine status'),
  body('criticality').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']).withMessage('Invalid criticality'),
  body('operatingHours').optional().isDecimal().withMessage('Valid operating hours required'),
  body('maintenanceInterval').optional().isInt({ min: 1 }).withMessage('Valid interval in days required'),
  body('specifications').optional().isObject().withMessage('Specifications must be a JSON object'),
  body('notes').optional().trim(),
];

const updateMachineValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid machine ID required'),
  body('name').optional().trim().isLength({ min: 1 }),
  body('category').optional().trim().isLength({ min: 1 }),
  body('manufacturer').optional().trim().isLength({ min: 1 }),
  body('modelNumber').optional().trim().isLength({ min: 1 }),
  body('serialNumber').optional().trim().isLength({ min: 1 }),
  body('purchaseDate').optional().isISO8601().withMessage('Valid date required'),
  body('purchasePrice').optional().isDecimal().withMessage('Valid price required'),
  body('warrantyExpiry').optional().isISO8601().withMessage('Valid date required'),
  body('location').optional().trim().isLength({ min: 1 }),
  body('department').optional().trim().isLength({ min: 1 }),
  body('status').optional().isIn(['OPERATIONAL', 'UNDER_MAINTENANCE', 'BREAKDOWN', 'DECOMMISSIONED', 'STANDBY']).withMessage('Invalid machine status'),
  body('criticality').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']).withMessage('Invalid criticality'),
  body('operatingHours').optional().isDecimal().withMessage('Valid operating hours required'),
  body('maintenanceInterval').optional().isInt({ min: 1 }).withMessage('Valid interval in days required'),
  body('specifications').optional().isObject().withMessage('Specifications must be a JSON object'),
  body('notes').optional().trim(),
];

const maintenanceScheduleValidator = [
  body('machineId').isInt({ min: 1 }).withMessage('Valid machine ID required'),
  body('maintenanceType').trim().notEmpty().withMessage('Maintenance type is required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('frequencyDays').isInt({ min: 1 }).withMessage('Frequency in days is required'),
  body('frequencyHours').optional().isInt({ min: 1 }).withMessage('Valid frequency hours required'),
  body('nextDueDate').isISO8601().withMessage('Valid next due date required'),
  body('assignedTeam').optional().trim().isLength({ min: 1 }),
  body('estimatedDuration').optional().isInt({ min: 1 }).withMessage('Valid duration in minutes required'),
  body('estimatedCost').optional().isDecimal().withMessage('Valid cost required'),
];

const breakdownLogValidator = [
  body('machineId').isInt({ min: 1 }).withMessage('Valid machine ID required'),
  body('reportedAt').isISO8601().withMessage('Valid reported date/time required'),
  body('severity').isIn(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']).withMessage('Invalid severity'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('reportedBy').optional().trim().isLength({ min: 1 }),
  body('rootCause').optional().trim(),
];

const resolveBreakdownValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid breakdown ID required'),
  body('resolvedAt').isISO8601().withMessage('Valid resolved date/time required'),
  body('resolution').trim().notEmpty().withMessage('Resolution description is required'),
  body('rootCause').optional().trim(),
  body('costOfRepair').optional().isDecimal().withMessage('Valid cost required'),
  body('resolvedBy').optional().trim().isLength({ min: 1 }),
];

const amcContractValidator = [
  body('machineId').isInt({ min: 1 }).withMessage('Valid machine ID required'),
  body('contractNo').trim().notEmpty().withMessage('Contract number is required'),
  body('vendor').trim().notEmpty().withMessage('Vendor is required'),
  body('startDate').isISO8601().withMessage('Valid start date required'),
  body('endDate').isISO8601().withMessage('Valid end date required'),
  body('annualCost').isDecimal().withMessage('Valid annual cost required'),
  body('coverageDetails').optional().trim(),
  body('contactPerson').optional().trim().isLength({ min: 1 }),
  body('contactPhone').optional().trim().isLength({ min: 1 }),
  body('documentUrl').optional().trim().isURL().withMessage('Valid URL required'),
  body('status').optional().isIn(['ACTIVE', 'EXPIRED', 'CANCELLED', 'PENDING_RENEWAL']).withMessage('Invalid AMC status'),
];

const serviceHistoryValidator = [
  body('machineId').isInt({ min: 1 }).withMessage('Valid machine ID required'),
  body('serviceDate').isISO8601().withMessage('Valid service date required'),
  body('serviceType').trim().notEmpty().withMessage('Service type is required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('cost').isDecimal().withMessage('Valid cost required'),
  body('hoursAtService').optional().isDecimal().withMessage('Valid hours required'),
  body('performedBy').optional().trim().isLength({ min: 1 }),
  body('notes').optional().trim(),
];

module.exports = {
  createMachineValidator,
  updateMachineValidator,
  maintenanceScheduleValidator,
  breakdownLogValidator,
  resolveBreakdownValidator,
  amcContractValidator,
  serviceHistoryValidator,
};
