// ============================================================================
// Nelna Maintenance System - Report & Analytics Routes
// ============================================================================
const { Router } = require('express');
const reportController = require('../controllers/report.controller');
const { authenticate, checkPermission } = require('../middleware/auth');
const validate = require('../middleware/validate');
const {
  kpiValidator,
  dateRangeReportValidator,
  monthlyTrendValidator,
  expenseReportValidator,
} = require('../validators/report.validator');

const router = Router();

// All report routes require authentication
router.use(authenticate);

// Dashboard KPIs
router.get('/dashboard-kpis', kpiValidator, validate, checkPermission('reports', 'read', 'dashboard'), reportController.getDashboardKPIs);

// Vehicle maintenance cost report
router.get('/vehicle-maintenance-costs', dateRangeReportValidator, validate, checkPermission('reports', 'read', 'vehicle_report'), reportController.getVehicleMaintenanceCostReport);

// Machine downtime report
router.get('/machine-downtime', dateRangeReportValidator, validate, checkPermission('reports', 'read', 'machine_report'), reportController.getMachineDowntimeReport);

// Inventory usage report
router.get('/inventory-usage', dateRangeReportValidator, validate, checkPermission('reports', 'read', 'inventory_report'), reportController.getInventoryUsageReport);

// Expense report
router.get('/expenses', expenseReportValidator, validate, checkPermission('reports', 'read', 'expense_report'), reportController.getExpenseReport);

// Monthly trend data (for charts)
router.get('/monthly-trends', monthlyTrendValidator, validate, checkPermission('reports', 'read', 'trend_report'), reportController.getMonthlyTrendData);

// Service request statistics
router.get('/service-request-stats', kpiValidator, validate, checkPermission('reports', 'read', 'service_report'), reportController.getServiceRequestStats);

module.exports = router;
