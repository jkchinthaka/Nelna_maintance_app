// ============================================================================
// Nelna Maintenance System - Custom Error Classes
// ============================================================================

class AppError extends Error {
  constructor(message, statusCode, errorCode = null) {
    super(message);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

class BadRequestError extends AppError {
  constructor(message = 'Bad request', errorCode = 'BAD_REQUEST') {
    super(message, 400, errorCode);
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized', errorCode = 'UNAUTHORIZED') {
    super(message, 401, errorCode);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden', errorCode = 'FORBIDDEN') {
    super(message, 403, errorCode);
  }
}

class NotFoundError extends AppError {
  constructor(message = 'Resource not found', errorCode = 'NOT_FOUND') {
    super(message, 404, errorCode);
  }
}

class ConflictError extends AppError {
  constructor(message = 'Conflict', errorCode = 'CONFLICT') {
    super(message, 409, errorCode);
  }
}

class ValidationError extends AppError {
  constructor(message = 'Validation failed', errors = []) {
    super(message, 422, 'VALIDATION_ERROR');
    this.errors = errors;
  }
}

class InternalError extends AppError {
  constructor(message = 'Internal server error') {
    super(message, 500, 'INTERNAL_ERROR');
  }
}

module.exports = {
  AppError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  ValidationError,
  InternalError,
};
