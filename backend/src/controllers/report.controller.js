// ============================================================================
// Nelna Maintenance System - Report & Analytics Controller
// ============================================================================
const reportService = require('../services/report.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class ReportController {
  getDashboardKPIs = asyncHandler(async (req, res) => {
    const kpis = await reportService.getDashboardKPIs(req.query.branchId);
    ApiResponse.success(res, kpis);
  });

  getVehicleMaintenanceCostReport = asyncHandler(async (req, res) => {
    const { branchId, startDate, endDate } = req.query;
    const report = await reportService.getVehicleMaintenanceCostReport(branchId, startDate, endDate);
    ApiResponse.success(res, report);
  });

  getMachineDowntimeReport = asyncHandler(async (req, res) => {
    const { branchId, startDate, endDate } = req.query;
    const report = await reportService.getMachineDowntimeReport(branchId, startDate, endDate);
    ApiResponse.success(res, report);
  });

  getInventoryUsageReport = asyncHandler(async (req, res) => {
    const { branchId, startDate, endDate } = req.query;
    const report = await reportService.getInventoryUsageReport(branchId, startDate, endDate);
    ApiResponse.success(res, report);
  });

  getExpenseReport = asyncHandler(async (req, res) => {
    const { branchId, startDate, endDate, groupBy } = req.query;
    const report = await reportService.getExpenseReport(branchId, startDate, endDate, groupBy);
    ApiResponse.success(res, report);
  });

  getMonthlyTrendData = asyncHandler(async (req, res) => {
    const { branchId, year } = req.query;
    const trends = await reportService.getMonthlyTrendData(branchId, year);
    ApiResponse.success(res, trends);
  });

  getServiceRequestStats = asyncHandler(async (req, res) => {
    const stats = await reportService.getServiceRequestStats(req.query.branchId);
    ApiResponse.success(res, stats);
  });
}

module.exports = new ReportController();
