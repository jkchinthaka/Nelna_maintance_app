// ============================================================================
// Nelna Maintenance System - Machine Routes
// ============================================================================
const { Router } = require('express');
const machineController = require('../controllers/machine.controller');
const { authenticate, checkPermission } = require('../middleware/auth');
const { auditLog, captureOldValues } = require('../middleware/auditLog');
const validate = require('../middleware/validate');
const {
  createMachineValidator,
  updateMachineValidator,
  maintenanceScheduleValidator,
  breakdownLogValidator,
  resolveBreakdownValidator,
  amcContractValidator,
  serviceHistoryValidator,
} = require('../validators/machine.validator');

const router = Router();

// All machine routes require authentication
router.use(authenticate);

// Overdue maintenances (before /:id to avoid route conflict)
router.get('/overdue-maintenances', checkPermission('machines', 'read', 'maintenance_schedule'), machineController.getOverdueMaintenances);

// CRUD operations
router.get('/', checkPermission('machines', 'read', 'machine'), machineController.getAll);
router.get('/:id', checkPermission('machines', 'read', 'machine'), machineController.getById);
router.post('/', checkPermission('machines', 'create', 'machine'), createMachineValidator, validate, auditLog('CREATE', 'machines', 'Machine'), machineController.create);
router.put('/:id', checkPermission('machines', 'update', 'machine'), captureOldValues('machine'), updateMachineValidator, validate, auditLog('UPDATE', 'machines', 'Machine'), machineController.update);
router.delete('/:id', checkPermission('machines', 'delete', 'machine'), captureOldValues('machine'), auditLog('DELETE', 'machines', 'Machine'), machineController.delete);

// Maintenance Schedules
router.get('/:id/maintenance-schedules', checkPermission('machines', 'read', 'maintenance_schedule'), machineController.getMaintenanceSchedules);
router.post('/maintenance-schedules', checkPermission('machines', 'create', 'maintenance_schedule'), maintenanceScheduleValidator, validate, auditLog('CREATE', 'machines', 'MachineMaintenanceSchedule'), machineController.addMaintenanceSchedule);

// Breakdown Logs
router.get('/:id/breakdowns', checkPermission('machines', 'read', 'breakdown_log'), machineController.getBreakdowns);
router.post('/breakdowns', checkPermission('machines', 'create', 'breakdown_log'), breakdownLogValidator, validate, auditLog('CREATE', 'machines', 'BreakdownLog'), machineController.logBreakdown);
router.put('/breakdowns/:id/resolve', checkPermission('machines', 'update', 'breakdown_log'), resolveBreakdownValidator, validate, auditLog('UPDATE', 'machines', 'BreakdownLog'), machineController.resolveBreakdown);

// Downtime Analytics
router.get('/:id/downtime', checkPermission('machines', 'read', 'machine_analytics'), machineController.calculateDowntime);

// AMC Contracts
router.get('/:id/amc-contracts', checkPermission('machines', 'read', 'amc_contract'), machineController.getAMCContracts);
router.post('/amc-contracts', checkPermission('machines', 'create', 'amc_contract'), amcContractValidator, validate, auditLog('CREATE', 'machines', 'AMCContract'), machineController.addAMCContract);

// Service History
router.post('/service-history', checkPermission('machines', 'create', 'machine_service_history'), serviceHistoryValidator, validate, auditLog('CREATE', 'machines', 'MachineServiceHistory'), machineController.addServiceHistory);

module.exports = router;
