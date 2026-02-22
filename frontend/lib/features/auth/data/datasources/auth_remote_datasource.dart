import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Handles all authentication-related HTTP calls.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// POST /auth/login
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return AuthResponseModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /auth/register
  Future<AuthResponseModel> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: data,
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return AuthResponseModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /auth/logout
  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /auth/profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.profile);
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return UserModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Failed to fetch profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT /auth/change-password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw ServerException(
          message: body['message'] as String? ?? 'Password change failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /auth/refresh-token
  Future<Map<String, String>> refreshToken(String token) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': token},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        return {
          'accessToken': data['accessToken'] as String? ?? '',
          'refreshToken': data['refreshToken'] as String? ?? token,
        };
      }
      throw ServerException(
        message: body['message'] as String? ?? 'Token refresh failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────
  ServerException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ServerException(
        message: 'Connection timed out. Please try again.',
        statusCode: statusCode,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return ServerException(
        message:
            'Unable to connect to the server. Check your internet connection.',
        statusCode: statusCode,
      );
    }

    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      return ServerException(
        message:
            responseData['message'] as String? ??
            'An unexpected error occurred',
        statusCode: statusCode,
        errorCode: responseData['errorCode'] as String?,
      );
    }

    return ServerException(
      message: e.message ?? 'An unexpected error occurred',
      statusCode: statusCode,
    );
  }
}
