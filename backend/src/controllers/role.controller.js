// ============================================================================
// Nelna Maintenance System - Role Controller
// ============================================================================
const roleService = require('../services/role.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class RoleController {
  /**
   * GET /api/v1/roles
   * Returns roles visible to the caller.
   * Unauthenticated → only self-register roles (Technician, Driver)
   * Admin → all roles
   */
  getRoles = asyncHandler(async (req, res) => {
    const roles = await roleService.getRoles(req.user || null);
    ApiResponse.success(res, roles, 'Roles retrieved successfully');
  });
}

module.exports = new RoleController();
