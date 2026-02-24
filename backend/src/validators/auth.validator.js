// ============================================================================
// Nelna Maintenance System - Auth Validators
// ============================================================================
const { body } = require('express-validator');

const loginValidator = [
  body('email')
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
];

const registerValidator = [
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('First name must be 2-100 characters'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Last name must be 2-100 characters'),
  body('email')
    .isEmail()
    .withMessage('Valid email is required')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/)
    .withMessage('Password must contain uppercase, lowercase, number, and special character'),
  body('phone')
    .optional()
    .isMobilePhone()
    .withMessage('Invalid phone number'),
  body('roleId')
    .isInt({ min: 1, max: 7 })
    .withMessage('Valid role ID is required (1-7)'),
  body('companyId')
    .isInt({ min: 1 })
    .withMessage('Valid company ID is required'),
  body('branchId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid branch ID is required'),
  body('employeeId')
    .optional()
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Employee ID must be 1-50 characters'),
];

const changePasswordValidator = [
  body('currentPassword')
    .isLength({ min: 1 })
    .withMessage('Current password is required'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/)
    .withMessage('Password must contain uppercase, lowercase, number, and special character'),
];

const refreshTokenValidator = [
  body('refreshToken')
    .isLength({ min: 1 })
    .withMessage('Refresh token is required'),
];

module.exports = {
  loginValidator,
  registerValidator,
  changePasswordValidator,
  refreshTokenValidator,
};
