// ============================================================================
// Nelna Maintenance System - Service Request Validators
// ============================================================================
const { body, param, query } = require('express-validator');

const SERVICE_CATEGORIES = [
  'VEHICLE_SERVICE',
  'MACHINE_MAINTENANCE',
  'ASSET_REPAIR',
  'PREVENTIVE_MAINTENANCE',
  'EMERGENCY_REPAIR',
  'INSPECTION',
  'GENERAL',
];

const PRIORITIES = ['LOW', 'MEDIUM', 'HIGH', 'URGENT', 'CRITICAL'];

const SERVICE_STATUSES = [
  'PENDING',
  'APPROVED',
  'REJECTED',
  'IN_PROGRESS',
  'ON_HOLD',
  'COMPLETED',
  'CLOSED',
  'CANCELLED',
];

const TASK_STATUSES = ['ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'ON_HOLD', 'CANCELLED'];

const createServiceRequestValidator = [
  body('branchId').isInt({ min: 1 }).withMessage('Valid branch ID is required'),
  body('category')
    .isIn(SERVICE_CATEGORIES)
    .withMessage(`Category must be one of: ${SERVICE_CATEGORIES.join(', ')}`),
  body('priority')
    .optional()
    .isIn(PRIORITIES)
    .withMessage(`Priority must be one of: ${PRIORITIES.join(', ')}`),
  body('subject')
    .trim()
    .notEmpty()
    .withMessage('Subject is required')
    .isLength({ max: 255 })
    .withMessage('Subject must not exceed 255 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required'),
  body('vehicleId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid vehicle ID required'),
  body('machineId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid machine ID required'),
  body('assetId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid asset ID required'),
  body('estimatedCost')
    .optional()
    .isDecimal()
    .withMessage('Valid estimated cost required'),
];

const updateServiceRequestValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid service request ID required'),
  body('category')
    .optional()
    .isIn(SERVICE_CATEGORIES)
    .withMessage(`Category must be one of: ${SERVICE_CATEGORIES.join(', ')}`),
  body('priority')
    .optional()
    .isIn(PRIORITIES)
    .withMessage(`Priority must be one of: ${PRIORITIES.join(', ')}`),
  body('subject')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Subject cannot be empty')
    .isLength({ max: 255 })
    .withMessage('Subject must not exceed 255 characters'),
  body('description')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Description cannot be empty'),
  body('vehicleId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid vehicle ID required'),
  body('machineId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid machine ID required'),
  body('assetId')
    .optional({ nullable: true })
    .isInt({ min: 1 })
    .withMessage('Valid asset ID required'),
  body('status')
    .optional()
    .isIn(SERVICE_STATUSES)
    .withMessage(`Status must be one of: ${SERVICE_STATUSES.join(', ')}`),
  body('estimatedCost')
    .optional()
    .isDecimal()
    .withMessage('Valid estimated cost required'),
];

const approveRequestValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid service request ID required'),
];

const rejectRequestValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid service request ID required'),
  body('rejectedReason')
    .trim()
    .notEmpty()
    .withMessage('Rejection reason is required'),
];

const assignTaskValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid service request ID required'),
  body('technicianId')
    .isInt({ min: 1 })
    .withMessage('Valid technician ID is required'),
  body('taskDescription')
    .trim()
    .notEmpty()
    .withMessage('Task description is required'),
  body('laborCost')
    .optional()
    .isDecimal()
    .withMessage('Valid labor cost required'),
  body('notes')
    .optional()
    .trim(),
];

const updateTaskValidator = [
  param('taskId').isInt({ min: 1 }).withMessage('Valid task ID required'),
  body('status')
    .optional()
    .isIn(TASK_STATUSES)
    .withMessage(`Task status must be one of: ${TASK_STATUSES.join(', ')}`),
  body('timeSpentMinutes')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Time spent must be a non-negative integer'),
  body('laborCost')
    .optional()
    .isDecimal()
    .withMessage('Valid labor cost required'),
  body('notes')
    .optional()
    .trim(),
];

const addSparePartValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid service request ID required'),
  body('productId')
    .isInt({ min: 1 })
    .withMessage('Valid product ID is required'),
  body('quantity')
    .isDecimal({ decimal_digits: '0,2' })
    .withMessage('Valid quantity is required')
    .custom((value) => parseFloat(value) > 0)
    .withMessage('Quantity must be greater than zero'),
  body('unitCost')
    .isDecimal()
    .withMessage('Valid unit cost is required'),
];

const closeTicketValidator = [
  param('id').isInt({ min: 1 }).withMessage('Valid service request ID required'),
  body('closedReason')
    .optional()
    .trim(),
];

const listQueryValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('status').optional().isIn(SERVICE_STATUSES).withMessage('Invalid status filter'),
  query('priority').optional().isIn(PRIORITIES).withMessage('Invalid priority filter'),
  query('category').optional().isIn(SERVICE_CATEGORIES).withMessage('Invalid category filter'),
  query('branchId').optional().isInt({ min: 1 }).withMessage('Valid branch ID required'),
  query('search').optional().trim(),
  query('sortBy').optional().trim(),
  query('sortOrder').optional().isIn(['asc', 'desc']).withMessage('Sort order must be asc or desc'),
];

module.exports = {
  createServiceRequestValidator,
  updateServiceRequestValidator,
  approveRequestValidator,
  rejectRequestValidator,
  assignTaskValidator,
  updateTaskValidator,
  addSparePartValidator,
  closeTicketValidator,
  listQueryValidator,
};
