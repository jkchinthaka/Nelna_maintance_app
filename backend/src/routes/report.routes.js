// ============================================================================
// Nelna Maintenance System - Report & Analytics Routes
// ============================================================================
const { Router } = require('express');
const reportController = require('../controllers/report.controller');
const { authenticate, checkPermission } = require('../middleware/auth');

const router = Router();

// All report routes require authentication
router.use(authenticate);

// Dashboard KPIs
router.get('/dashboard-kpis', checkPermission('reports', 'read', 'dashboard'), reportController.getDashboardKPIs);

// Vehicle maintenance cost report
router.get('/vehicle-maintenance-costs', checkPermission('reports', 'read', 'vehicle_report'), reportController.getVehicleMaintenanceCostReport);

// Machine downtime report
router.get('/machine-downtime', checkPermission('reports', 'read', 'machine_report'), reportController.getMachineDowntimeReport);

// Inventory usage report
router.get('/inventory-usage', checkPermission('reports', 'read', 'inventory_report'), reportController.getInventoryUsageReport);

// Expense report
router.get('/expenses', checkPermission('reports', 'read', 'expense_report'), reportController.getExpenseReport);

// Monthly trend data (for charts)
router.get('/monthly-trends', checkPermission('reports', 'read', 'trend_report'), reportController.getMonthlyTrendData);

// Service request statistics
router.get('/service-request-stats', checkPermission('reports', 'read', 'service_report'), reportController.getServiceRequestStats);

module.exports = router;
