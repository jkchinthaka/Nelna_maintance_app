// ============================================================================
// Nelna Maintenance System - Service Request Routes
// ============================================================================
const { Router } = require('express');
const serviceController = require('../controllers/service.controller');
const { authenticate, checkPermission } = require('../middleware/auth');
const { auditLog, captureOldValues } = require('../middleware/auditLog');
const validate = require('../middleware/validate');
const {
  createServiceRequestValidator,
  updateServiceRequestValidator,
  approveRequestValidator,
  rejectRequestValidator,
  assignTaskValidator,
  updateTaskValidator,
  addSparePartValidator,
  closeTicketValidator,
  listQueryValidator,
} = require('../validators/service.validator');

const router = Router();

// All service routes require authentication
router.use(authenticate);

// --------------------------------------------------------------------------
// Query routes (before /:id to avoid route conflicts)
// --------------------------------------------------------------------------
router.get(
  '/my-requests',
  listQueryValidator,
  validate,
  serviceController.getMyRequests
);

router.get(
  '/my-tasks',
  listQueryValidator,
  validate,
  serviceController.getAssignedTasks
);

router.get(
  '/sla-breaches',
  checkPermission('services', 'read', 'sla_breach'),
  listQueryValidator,
  validate,
  serviceController.getSLABreaches
);

// --------------------------------------------------------------------------
// CRUD routes
// --------------------------------------------------------------------------
router.get(
  '/',
  checkPermission('services', 'read', 'service_request'),
  listQueryValidator,
  validate,
  serviceController.getAll
);

router.get(
  '/:id',
  checkPermission('services', 'read', 'service_request'),
  serviceController.getById
);

router.post(
  '/',
  checkPermission('services', 'create', 'service_request'),
  createServiceRequestValidator,
  validate,
  auditLog('CREATE', 'services', 'ServiceRequest'),
  serviceController.create
);

router.put(
  '/:id',
  checkPermission('services', 'update', 'service_request'),
  captureOldValues('serviceRequest'),
  updateServiceRequestValidator,
  validate,
  auditLog('UPDATE', 'services', 'ServiceRequest'),
  serviceController.update
);

router.delete(
  '/:id',
  checkPermission('services', 'delete', 'service_request'),
  captureOldValues('serviceRequest'),
  auditLog('DELETE', 'services', 'ServiceRequest'),
  serviceController.delete
);

// --------------------------------------------------------------------------
// Approval workflow
// --------------------------------------------------------------------------
router.put(
  '/:id/approve',
  checkPermission('services', 'update', 'service_approval'),
  approveRequestValidator,
  validate,
  auditLog('UPDATE', 'services', 'ServiceRequest'),
  serviceController.approve
);

router.put(
  '/:id/reject',
  checkPermission('services', 'update', 'service_approval'),
  rejectRequestValidator,
  validate,
  auditLog('UPDATE', 'services', 'ServiceRequest'),
  serviceController.reject
);

// --------------------------------------------------------------------------
// Task management
// --------------------------------------------------------------------------
router.post(
  '/:id/tasks',
  checkPermission('services', 'create', 'service_task'),
  assignTaskValidator,
  validate,
  auditLog('CREATE', 'services', 'ServiceTask'),
  serviceController.assignTask
);

router.put(
  '/tasks/:taskId',
  checkPermission('services', 'update', 'service_task'),
  updateTaskValidator,
  validate,
  auditLog('UPDATE', 'services', 'ServiceTask'),
  serviceController.updateTask
);

// --------------------------------------------------------------------------
// Spare parts
// --------------------------------------------------------------------------
router.post(
  '/:id/spare-parts',
  checkPermission('services', 'create', 'service_spare_part'),
  addSparePartValidator,
  validate,
  auditLog('CREATE', 'services', 'ServiceSparePart'),
  serviceController.addSparePart
);

// --------------------------------------------------------------------------
// Cost & lifecycle
// --------------------------------------------------------------------------
router.get(
  '/:id/cost',
  checkPermission('services', 'read', 'service_request'),
  serviceController.calculateCost
);

router.put(
  '/:id/close',
  checkPermission('services', 'update', 'service_request'),
  closeTicketValidator,
  validate,
  auditLog('UPDATE', 'services', 'ServiceRequest'),
  serviceController.closeTicket
);

module.exports = router;
