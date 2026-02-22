// ============================================================================
// Nelna Maintenance System - Asset (Stores) Controller
// ============================================================================
const assetService = require('../services/asset.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class AssetController {
  // CRUD
  getAll = asyncHandler(async (req, res) => {
    const result = await assetService.getAll(req.query, req.user);
    ApiResponse.paginated(res, result.assets, result.pagination);
  });

  getById = asyncHandler(async (req, res) => {
    const asset = await assetService.getById(parseInt(req.params.id, 10));
    ApiResponse.success(res, asset);
  });

  create = asyncHandler(async (req, res) => {
    const asset = await assetService.create(req.body);
    ApiResponse.created(res, asset, 'Asset created successfully');
  });

  update = asyncHandler(async (req, res) => {
    const asset = await assetService.update(parseInt(req.params.id, 10), req.body);
    ApiResponse.success(res, asset, 'Asset updated successfully');
  });

  delete = asyncHandler(async (req, res) => {
    await assetService.delete(parseInt(req.params.id, 10));
    ApiResponse.success(res, null, 'Asset deleted successfully');
  });

  // Repair Logs
  addRepairLog = asyncHandler(async (req, res) => {
    const repairLog = await assetService.addRepairLog(req.body);
    ApiResponse.created(res, repairLog, 'Repair log added successfully');
  });

  getRepairHistory = asyncHandler(async (req, res) => {
    const result = await assetService.getRepairHistory(
      parseInt(req.params.id, 10),
      req.query
    );
    ApiResponse.paginated(res, result.repairLogs, result.pagination);
  });

  // Transfers
  transferAsset = asyncHandler(async (req, res) => {
    const transfer = await assetService.transferAsset(req.body);
    ApiResponse.created(res, transfer, 'Asset transferred successfully');
  });

  // Lifecycle & Analytics
  getAssetLifecycle = asyncHandler(async (req, res) => {
    const lifecycle = await assetService.getAssetLifecycle(parseInt(req.params.id, 10));
    ApiResponse.success(res, lifecycle);
  });

  getAssetsByCondition = asyncHandler(async (req, res) => {
    const result = await assetService.getAssetsByCondition(req.query, req.user);
    ApiResponse.success(res, result);
  });
}

module.exports = new AssetController();
