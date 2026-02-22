// ============================================================================
// Nelna Maintenance System - Standardized API Response
// ============================================================================

class ApiResponse {
  /**
   * Success response
   */
  static success(res, data = null, message = 'Success', statusCode = 200, meta = null) {
    const response = {
      success: true,
      message,
      data,
    };
    if (meta) response.meta = meta;
    return res.status(statusCode).json(response);
  }

  /**
   * Created response
   */
  static created(res, data = null, message = 'Created successfully') {
    return ApiResponse.success(res, data, message, 201);
  }

  /**
   * Paginated list response
   */
  static paginated(res, data, pagination, message = 'Success') {
    return res.status(200).json({
      success: true,
      message,
      data,
      meta: {
        pagination: {
          page: pagination.page,
          limit: pagination.limit,
          total: pagination.total,
          totalPages: Math.ceil(pagination.total / pagination.limit),
          hasNextPage: pagination.page < Math.ceil(pagination.total / pagination.limit),
          hasPrevPage: pagination.page > 1,
        },
      },
    });
  }

  /**
   * Error response
   */
  static error(res, message = 'Error', statusCode = 500, errorCode = null, errors = null) {
    const response = {
      success: false,
      message,
      errorCode,
    };
    if (errors) response.errors = errors;
    return res.status(statusCode).json(response);
  }

  /**
   * No content response
   */
  static noContent(res) {
    return res.status(204).send();
  }
}

module.exports = ApiResponse;
