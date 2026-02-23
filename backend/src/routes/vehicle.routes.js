// ============================================================================
// Nelna Maintenance System - Vehicle Routes
// ============================================================================
const { Router } = require('express');
const vehicleController = require('../controllers/vehicle.controller');
const { authenticate, checkPermission } = require('../middleware/auth');
const { auditLog, captureOldValues } = require('../middleware/auditLog');
const validate = require('../middleware/validate');
const {
  createVehicleValidator,
  updateVehicleValidator,
  fuelLogValidator,
  documentValidator,
  driverAssignValidator,
} = require('../validators/vehicle.validator');

const router = Router();

// All vehicle routes require authentication
router.use(authenticate);

// CRUD operations
router.get('/', checkPermission('vehicles', 'read', 'vehicle'), vehicleController.getAll);
router.post('/', checkPermission('vehicles', 'create', 'vehicle'), createVehicleValidator, validate, auditLog('CREATE', 'vehicles', 'Vehicle'), vehicleController.create);
router.get('/reminders', checkPermission('vehicles', 'read', 'vehicle'), vehicleController.getServiceReminders);
router.get('/:id', checkPermission('vehicles', 'read', 'vehicle'), vehicleController.getById);
router.put('/:id', checkPermission('vehicles', 'update', 'vehicle'), captureOldValues('vehicle'), updateVehicleValidator, validate, auditLog('UPDATE', 'vehicles', 'Vehicle'), vehicleController.update);
router.delete('/:id', checkPermission('vehicles', 'delete', 'vehicle'), captureOldValues('vehicle'), auditLog('DELETE', 'vehicles', 'Vehicle'), vehicleController.delete);

// Fuel logs (nested under vehicle :id)
router.get('/:id/fuel-logs', checkPermission('vehicles', 'read', 'fuel_log'), vehicleController.getFuelLogs);
router.post('/:id/fuel-logs', checkPermission('vehicles', 'create', 'fuel_log'), fuelLogValidator, validate, vehicleController.addFuelLog);

// Documents (nested under vehicle :id)
router.post('/:id/documents', checkPermission('vehicles', 'create', 'vehicle_document'), documentValidator, validate, vehicleController.addDocument);

// Driver assignment (nested under vehicle :id)
router.post('/:id/assign-driver', checkPermission('vehicles', 'update', 'vehicle_driver'), driverAssignValidator, validate, vehicleController.assignDriver);

// Analytics (nested under vehicle :id)
router.get('/:id/cost-analytics', checkPermission('vehicles', 'read', 'vehicle_analytics'), vehicleController.getCostAnalytics);

module.exports = router;
