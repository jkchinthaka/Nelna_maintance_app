import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

/// Handles all dashboard-related HTTP calls.
class DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSource(this._apiClient);

  // ── GET /reports/dashboard-kpis ────────────────────────────────────
  Future<DashboardKPIsModel> getDashboardKPIs({int? branchId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (branchId != null) queryParams['branchId'] = branchId;

      final response = await _apiClient.get(
        ApiConstants.dashboard,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return DashboardKPIsModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Failed to fetch dashboard KPIs',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── GET /reports/monthly-trends ────────────────────────────────────
  Future<MonthlyTrendsResponseModel> getMonthlyTrends({
    int? branchId,
    int? year,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (branchId != null) queryParams['branchId'] = branchId;
      if (year != null) queryParams['year'] = year;

      final response = await _apiClient.get(
        ApiConstants.reportMonthlyTrends,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return MonthlyTrendsResponseModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Failed to fetch monthly trends',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── GET /reports/service-request-stats ─────────────────────────────
  Future<ServiceRequestStatsModel> getServiceRequestStats({
    int? branchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (branchId != null) queryParams['branchId'] = branchId;

      final response = await _apiClient.get(
        '/reports/service-request-stats',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return ServiceRequestStatsModel.fromJson(
          body['data'] as Map<String, dynamic>,
        );
      }
      throw ServerException(
        message:
            body['message'] as String? ??
            'Failed to fetch service request stats',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Error helper ───────────────────────────────────────────────────
  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'Connection error. Check your internet.',
      );
    }

    final data = e.response?.data;
    final message = data is Map<String, dynamic>
        ? (data['message'] as String? ?? 'Something went wrong')
        : 'Something went wrong';

    return ServerException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}
