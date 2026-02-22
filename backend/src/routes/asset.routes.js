// ============================================================================
// Nelna Maintenance System - Asset (Stores) Routes
// ============================================================================
const { Router } = require('express');
const assetController = require('../controllers/asset.controller');
const { authenticate, checkPermission } = require('../middleware/auth');
const { auditLog, captureOldValues } = require('../middleware/auditLog');
const validate = require('../middleware/validate');
const {
  createAssetValidator,
  updateAssetValidator,
  createRepairLogValidator,
  createTransferValidator,
} = require('../validators/asset.validator');

const router = Router();

// All asset routes require authentication
router.use(authenticate);

// Analytics (before /:id to avoid route conflict)
router.get('/condition-summary', checkPermission('stores', 'read', 'asset_analytics'), assetController.getAssetsByCondition);

// CRUD operations
router.get('/', checkPermission('stores', 'read', 'asset'), assetController.getAll);
router.get('/:id', checkPermission('stores', 'read', 'asset'), assetController.getById);
router.post('/', checkPermission('stores', 'create', 'asset'), createAssetValidator, validate, auditLog('CREATE', 'stores', 'Asset'), assetController.create);
router.put('/:id', checkPermission('stores', 'update', 'asset'), captureOldValues('asset'), updateAssetValidator, validate, auditLog('UPDATE', 'stores', 'Asset'), assetController.update);
router.delete('/:id', checkPermission('stores', 'delete', 'asset'), captureOldValues('asset'), auditLog('DELETE', 'stores', 'Asset'), assetController.delete);

// Repair Logs
router.get('/:id/repair-logs', checkPermission('stores', 'read', 'asset_repair_log'), assetController.getRepairHistory);
router.post('/repair-logs', checkPermission('stores', 'create', 'asset_repair_log'), createRepairLogValidator, validate, auditLog('CREATE', 'stores', 'AssetRepairLog'), assetController.addRepairLog);

// Transfers
router.post('/transfers', checkPermission('stores', 'create', 'asset_transfer'), createTransferValidator, validate, auditLog('CREATE', 'stores', 'AssetTransfer'), assetController.transferAsset);

// Lifecycle
router.get('/:id/lifecycle', checkPermission('stores', 'read', 'asset_analytics'), assetController.getAssetLifecycle);

module.exports = router;
