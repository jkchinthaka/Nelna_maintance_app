// ============================================================================
// Nelna Maintenance System - Vehicle Controller
// ============================================================================
const vehicleService = require('../services/vehicle.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class VehicleController {
  getAll = asyncHandler(async (req, res) => {
    const result = await vehicleService.getAll(req.query, req.user);
    ApiResponse.paginated(res, result.vehicles, result.pagination);
  });

  getById = asyncHandler(async (req, res) => {
    const vehicle = await vehicleService.getById(parseInt(req.params.id, 10));
    ApiResponse.success(res, vehicle);
  });

  create = asyncHandler(async (req, res) => {
    const vehicle = await vehicleService.create(req.body);
    ApiResponse.created(res, vehicle, 'Vehicle created successfully');
  });

  update = asyncHandler(async (req, res) => {
    const vehicle = await vehicleService.update(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, vehicle, 'Vehicle updated successfully');
  });

  delete = asyncHandler(async (req, res) => {
    await vehicleService.delete(parseInt(req.params.id, 10));
    ApiResponse.success(res, null, 'Vehicle deleted successfully');
  });

  addFuelLog = asyncHandler(async (req, res) => {
    const log = await vehicleService.addFuelLog(req.body);
    ApiResponse.created(res, log, 'Fuel log added successfully');
  });

  getFuelLogs = asyncHandler(async (req, res) => {
    const result = await vehicleService.getFuelLogs(parseInt(req.params.id, 10), req.query);
    ApiResponse.paginated(res, result.logs, result.pagination);
  });

  addDocument = asyncHandler(async (req, res) => {
    const doc = await vehicleService.addDocument(req.body);
    ApiResponse.created(res, doc, 'Document added successfully');
  });

  assignDriver = asyncHandler(async (req, res) => {
    const assignment = await vehicleService.assignDriver(req.body);
    ApiResponse.created(res, assignment, 'Driver assigned successfully');
  });

  getServiceReminders = asyncHandler(async (req, res) => {
    const reminders = await vehicleService.getServiceReminders(req.query.branchId ? parseInt(req.query.branchId, 10) : null);
    ApiResponse.success(res, reminders);
  });

  getCostAnalytics = asyncHandler(async (req, res) => {
    const analytics = await vehicleService.getCostAnalytics(
      parseInt(req.params.id, 10),
      req.query.startDate,
      req.query.endDate
    );
    ApiResponse.success(res, analytics);
  });
}

module.exports = new VehicleController();
