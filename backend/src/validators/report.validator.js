// ============================================================================
// Nelna Maintenance System - Report Validators
// Validates query parameters for all report endpoints.
// ============================================================================
const { query } = require('express-validator');

/**
 * Validates date-range report params: startDate, endDate, branchId (optional).
 */
const dateRangeReportValidator = [
  query('startDate')
    .notEmpty()
    .withMessage('startDate is required')
    .isISO8601()
    .withMessage('startDate must be a valid ISO 8601 date (YYYY-MM-DD)'),
  query('endDate')
    .notEmpty()
    .withMessage('endDate is required')
    .isISO8601()
    .withMessage('endDate must be a valid ISO 8601 date (YYYY-MM-DD)')
    .custom((value, { req }) => {
      if (new Date(value) < new Date(req.query.startDate)) {
        throw new Error('endDate must be after startDate');
      }
      return true;
    }),
  query('branchId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('branchId must be a positive integer'),
];

/**
 * Validates KPI / stats params (optional branchId only).
 */
const kpiValidator = [
  query('branchId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('branchId must be a positive integer'),
];

/**
 * Validates monthly-trend params: year (optional), branchId (optional).
 */
const monthlyTrendValidator = [
  query('year')
    .optional()
    .isInt({ min: 2000, max: 2099 })
    .withMessage('year must be a valid four-digit year'),
  query('branchId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('branchId must be a positive integer'),
];

/**
 * Validates expense report params: same as date-range plus optional groupBy.
 */
const expenseReportValidator = [
  ...dateRangeReportValidator,
  query('groupBy')
    .optional()
    .isIn(['category', 'branch', 'month', 'vehicle', 'machine'])
    .withMessage('groupBy must be one of: category, branch, month, vehicle, machine'),
];

module.exports = {
  dateRangeReportValidator,
  kpiValidator,
  monthlyTrendValidator,
  expenseReportValidator,
};
