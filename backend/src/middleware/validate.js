// ============================================================================
// Nelna Maintenance System - Request Validation Middleware
// ============================================================================
const { validationResult } = require('express-validator');
const { ValidationError } = require('../utils/errors');

/**
 * Validate request using express-validator rules.
 * Use after defining validation chains in route definitions.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map((err) => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));
    throw new ValidationError('Validation failed', formattedErrors);
  }
  next();
};

module.exports = validate;
