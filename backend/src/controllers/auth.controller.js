// ============================================================================
// Nelna Maintenance System - Auth Controller
// ============================================================================
const authService = require('../services/auth.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class AuthController {
  /**
   * POST /api/v1/auth/login
   */
  login = asyncHandler(async (req, res) => {
    const { email, password } = req.body;
    const result = await authService.login(email, password);
    ApiResponse.success(res, result, 'Login successful');
  });

  /**
   * POST /api/v1/auth/register
   * Supports both self-registration (public) and admin-created accounts.
   */
  register = asyncHandler(async (req, res) => {
    // Attach request metadata for audit logging
    req.body._ip = req.ip || req.socket?.remoteAddress;
    req.body._userAgent = req.headers['user-agent'];
    const result = await authService.register(req.body, req.user || null);
    ApiResponse.created(res, result, 'User registered successfully');
  });

  /**
   * POST /api/v1/auth/refresh-token
   */
  refreshToken = asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    const result = await authService.refreshToken(refreshToken);
    ApiResponse.success(res, result, 'Token refreshed successfully');
  });

  /**
   * POST /api/v1/auth/logout
   */
  logout = asyncHandler(async (req, res) => {
    await authService.logout(req.user.id);
    ApiResponse.success(res, null, 'Logged out successfully');
  });

  /**
   * PUT /api/v1/auth/change-password
   */
  changePassword = asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    await authService.changePassword(req.user.id, currentPassword, newPassword);
    ApiResponse.success(res, null, 'Password changed successfully');
  });

  /**
   * GET /api/v1/auth/profile
   */
  getProfile = asyncHandler(async (req, res) => {
    const profile = await authService.getProfile(req.user.id);
    ApiResponse.success(res, profile);
  });

  /**
   * PUT /api/v1/auth/fcm-token
   */
  updateFCMToken = asyncHandler(async (req, res) => {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
      return ApiResponse.badRequest(res, 'A valid FCM token string is required');
    }
    await authService.updateFCMToken(req.user.id, fcmToken.trim());
    ApiResponse.success(res, null, 'FCM token updated');
  });
}

module.exports = new AuthController();
