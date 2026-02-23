// ============================================================================
// Nelna Maintenance System - Role Routes
// ============================================================================
const { Router } = require('express');
const roleController = require('../controllers/role.controller');
const { optionalAuth } = require('../middleware/auth');

const router = Router();

// GET /api/v1/roles — public with optional auth for elevated visibility
router.get('/', optionalAuth, roleController.getRoles);

module.exports = router;
