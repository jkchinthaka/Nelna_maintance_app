// ============================================================================
// Nelna Maintenance System - Auth Routes
// ============================================================================
const { Router } = require('express');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');
const {
  loginValidator,
  registerValidator,
  changePasswordValidator,
  refreshTokenValidator,
} = require('../validators/auth.validator');

const router = Router();

// Public routes
router.post('/login', loginValidator, validate, authController.login);
router.post('/register', registerValidator, validate, authController.register);
router.post('/refresh-token', refreshTokenValidator, validate, authController.refreshToken);

// Protected routes
router.post('/logout', authenticate, authController.logout);
router.get('/profile', authenticate, authController.getProfile);
router.put('/change-password', authenticate, changePasswordValidator, validate, authController.changePassword);
router.put('/fcm-token', authenticate, authController.updateFCMToken);

module.exports = router;
