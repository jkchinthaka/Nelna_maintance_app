// ============================================================================
// Nelna Maintenance System - Service Request Controller
// ============================================================================
const serviceService = require('../services/service.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class ServiceController {
  // ==========================================================================
  // SERVICE REQUEST CRUD
  // ==========================================================================

  getAll = asyncHandler(async (req, res) => {
    const result = await serviceService.getAll(req.query, req.user);
    ApiResponse.paginated(res, result.serviceRequests, result.pagination);
  });

  getById = asyncHandler(async (req, res) => {
    const serviceRequest = await serviceService.getById(parseInt(req.params.id, 10));
    ApiResponse.success(res, serviceRequest);
  });

  create = asyncHandler(async (req, res) => {
    const serviceRequest = await serviceService.create(req.body, req.user);
    ApiResponse.created(res, serviceRequest, 'Service request created successfully');
  });

  update = asyncHandler(async (req, res) => {
    const serviceRequest = await serviceService.update(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, serviceRequest, 'Service request updated successfully');
  });

  delete = asyncHandler(async (req, res) => {
    await serviceService.delete(parseInt(req.params.id, 10));
    ApiResponse.success(res, null, 'Service request deleted successfully');
  });

  // ==========================================================================
  // APPROVAL WORKFLOW
  // ==========================================================================

  approve = asyncHandler(async (req, res) => {
    const serviceRequest = await serviceService.approve(parseInt(req.params.id, 10), req.user.id);
    ApiResponse.success(res, serviceRequest, 'Service request approved successfully');
  });

  reject = asyncHandler(async (req, res) => {
    const serviceRequest = await serviceService.reject(
      parseInt(req.params.id, 10),
      req.user.id,
      req.body.rejectedReason
    );
    ApiResponse.success(res, serviceRequest, 'Service request rejected');
  });

  // ==========================================================================
  // TASK MANAGEMENT
  // ==========================================================================

  assignTask = asyncHandler(async (req, res) => {
    const task = await serviceService.assignTask(parseInt(req.params.id, 10), req.body);
    ApiResponse.created(res, task, 'Task assigned successfully');
  });

  updateTask = asyncHandler(async (req, res) => {
    const task = await serviceService.updateTaskStatus(parseInt(req.params.taskId, 10), req.body);
    ApiResponse.success(res, task, 'Task updated successfully');
  });

  // ==========================================================================
  // SPARE PARTS
  // ==========================================================================

  addSparePart = asyncHandler(async (req, res) => {
    const sparePart = await serviceService.addSparePart(parseInt(req.params.id, 10), req.body);
    ApiResponse.created(res, sparePart, 'Spare part added successfully');
  });

  // ==========================================================================
  // COST
  // ==========================================================================

  calculateCost = asyncHandler(async (req, res) => {
    const result = await serviceService.calculateCost(parseInt(req.params.id, 10));
    ApiResponse.success(res, result);
  });

  // ==========================================================================
  // TICKET LIFECYCLE
  // ==========================================================================

  closeTicket = asyncHandler(async (req, res) => {
    const serviceRequest = await serviceService.closeTicket(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, serviceRequest, 'Service request closed successfully');
  });

  // ==========================================================================
  // QUERIES
  // ==========================================================================

  getMyRequests = asyncHandler(async (req, res) => {
    const result = await serviceService.getMyRequests(req.user.id, req.query);
    ApiResponse.paginated(res, result.serviceRequests, result.pagination);
  });

  getAssignedTasks = asyncHandler(async (req, res) => {
    const result = await serviceService.getAssignedTasks(req.user.id, req.query);
    ApiResponse.paginated(res, result.tasks, result.pagination);
  });

  getSLABreaches = asyncHandler(async (req, res) => {
    const result = await serviceService.getSLABreaches(req.query, req.user);
    ApiResponse.paginated(res, result.serviceRequests, result.pagination);
  });
}

module.exports = new ServiceController();
