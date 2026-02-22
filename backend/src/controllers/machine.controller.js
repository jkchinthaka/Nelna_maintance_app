// ============================================================================
// Nelna Maintenance System - Machine Controller
// ============================================================================
const machineService = require('../services/machine.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class MachineController {
  // CRUD
  getAll = asyncHandler(async (req, res) => {
    const result = await machineService.getAll(req.query, req.user);
    ApiResponse.paginated(res, result.machines, result.pagination);
  });

  getById = asyncHandler(async (req, res) => {
    const machine = await machineService.getById(parseInt(req.params.id, 10));
    ApiResponse.success(res, machine);
  });

  create = asyncHandler(async (req, res) => {
    const machine = await machineService.create(req.body);
    ApiResponse.created(res, machine, 'Machine created successfully');
  });

  update = asyncHandler(async (req, res) => {
    const machine = await machineService.update(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, machine, 'Machine updated successfully');
  });

  delete = asyncHandler(async (req, res) => {
    await machineService.delete(parseInt(req.params.id, 10));
    ApiResponse.success(res, null, 'Machine deleted successfully');
  });

  // Maintenance Schedules
  addMaintenanceSchedule = asyncHandler(async (req, res) => {
    const schedule = await machineService.addMaintenanceSchedule(req.body);
    ApiResponse.created(res, schedule, 'Maintenance schedule added successfully');
  });

  getMaintenanceSchedules = asyncHandler(async (req, res) => {
    const result = await machineService.getMaintenanceSchedules(
      parseInt(req.params.id, 10),
      req.query
    );
    ApiResponse.paginated(res, result.schedules, result.pagination);
  });

  // Breakdown Logs
  logBreakdown = asyncHandler(async (req, res) => {
    const breakdown = await machineService.logBreakdown(req.body);
    ApiResponse.created(res, breakdown, 'Breakdown logged successfully');
  });

  getBreakdowns = asyncHandler(async (req, res) => {
    const result = await machineService.getBreakdowns(
      parseInt(req.params.id, 10),
      req.query
    );
    ApiResponse.paginated(res, result.breakdowns, result.pagination);
  });

  resolveBreakdown = asyncHandler(async (req, res) => {
    const resolved = await machineService.resolveBreakdown(
      parseInt(req.params.id, 10),
      req.body
    );
    ApiResponse.success(res, resolved, 'Breakdown resolved successfully');
  });

  // Downtime
  calculateDowntime = asyncHandler(async (req, res) => {
    const result = await machineService.calculateDowntime(
      parseInt(req.params.id, 10),
      req.query.startDate,
      req.query.endDate
    );
    ApiResponse.success(res, result);
  });

  // AMC Contracts
  addAMCContract = asyncHandler(async (req, res) => {
    const contract = await machineService.addAMCContract(req.body);
    ApiResponse.created(res, contract, 'AMC contract added successfully');
  });

  getAMCContracts = asyncHandler(async (req, res) => {
    const result = await machineService.getAMCContracts(
      parseInt(req.params.id, 10),
      req.query
    );
    ApiResponse.paginated(res, result.contracts, result.pagination);
  });

  // Service History
  addServiceHistory = asyncHandler(async (req, res) => {
    const record = await machineService.addServiceHistory(req.body);
    ApiResponse.created(res, record, 'Service history added successfully');
  });

  // Overdue Maintenances
  getOverdueMaintenances = asyncHandler(async (req, res) => {
    const result = await machineService.getOverdueMaintenances(req.query, req.user);
    ApiResponse.paginated(res, result.schedules, result.pagination);
  });
}

module.exports = new MachineController();
