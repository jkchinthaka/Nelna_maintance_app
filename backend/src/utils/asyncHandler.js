// ============================================================================
// Nelna Maintenance System - Async Handler Wrapper
// ============================================================================

/**
 * Wraps async route handlers to catch errors and pass to Express error middleware.
 * Eliminates need for try-catch in every controller method.
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = asyncHandler;
