// ============================================================================
// Nelna Maintenance System - Centralized Error Handler Middleware
// ============================================================================
const logger = require('../config/logger');
const { AppError } = require('../utils/errors');
const config = require('../config');

// Sentry is optionally available — only capture if initialised
let Sentry = null;
try {
  if (config.sentry.dsn) {
    Sentry = require('@sentry/node');
  }
} catch (_) { /* Sentry not installed */ }

const errorHandler = (err, req, res, next) => {
  // ── Forward to Sentry (non-operational errors only) ────────────────────
  // Skip 4xx client errors — those are expected and not actionable noise.
  const status = err.statusCode || 500;
  if (Sentry && status >= 500) {
    Sentry.captureException(err, {
      user: req.user ? { id: req.user.id, email: req.user.email } : undefined,
      extra: {
        correlationId: req.correlationId,
        path: req.path,
        method: req.method,
        body: config.app.env !== 'production' ? req.body : undefined,
      },
    });
  }

  // Log error
  logger.error('Error occurred', {
    message: err.message,
    stack: err.stack,
    statusCode: err.statusCode,
    path: req.path,
    method: req.method,
    ip: req.ip,
    userId: req.user?.id,
    correlationId: req.correlationId,
  });

  // Prisma-specific errors
  if (err.code === 'P2002') {
    return res.status(409).json({
      success: false,
      message: 'A record with this value already exists',
      errorCode: 'DUPLICATE_ENTRY',
      field: err.meta?.target,
    });
  }

  if (err.code === 'P2025') {
    return res.status(404).json({
      success: false,
      message: 'Record not found',
      errorCode: 'NOT_FOUND',
    });
  }

  if (err.code === 'P2003') {
    return res.status(400).json({
      success: false,
      message: 'Related record not found (foreign key constraint)',
      errorCode: 'FOREIGN_KEY_ERROR',
    });
  }

  // Multer file upload errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({
      success: false,
      message: 'File size exceeds the allowed limit',
      errorCode: 'FILE_TOO_LARGE',
    });
  }

  // Express validation errors
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      success: false,
      message: 'Invalid JSON in request body',
      errorCode: 'INVALID_JSON',
    });
  }

  // Application-specific errors
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errorCode: err.errorCode,
      ...(err.errors && { errors: err.errors }),
    });
  }

  // Unhandled errors
  const statusCode = err.statusCode || 500;
  const message = config.app.env === 'production'
    ? 'Internal server error'
    : err.message || 'Internal server error';

  return res.status(statusCode).json({
    success: false,
    message,
    errorCode: 'INTERNAL_ERROR',
    ...(config.app.env !== 'production' && { stack: err.stack }),
  });
};

module.exports = errorHandler;
