import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _errorInterceptor(),
      if (kDebugMode) _loggingInterceptor(),
    ]);
  }

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  // ── Auth Interceptor ──────────────────────────────────────────────────
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _attemptTokenRefresh();
          if (refreshed) {
            try {
              final retryResponse = await _retryRequest(error.requestOptions);
              return handler.resolve(retryResponse);
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        handler.next(error);
      },
    );
  }

  // ── Token Refresh ─────────────────────────────────────────────────────
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _storage.read(
        key: AppConstants.refreshTokenKey,
      );
      if (refreshToken == null || refreshToken.isEmpty) return false;

      // Use a separate Dio instance to avoid interceptor loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['data']['accessToken'] as String;
        final newRefreshToken =
            response.data['data']['refreshToken'] as String?;

        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: newAccessToken,
        );
        if (newRefreshToken != null) {
          await _storage.write(
            key: AppConstants.refreshTokenKey,
            value: newRefreshToken,
          );
        }
        return true;
      }
      return false;
    } catch (_) {
      // Refresh failed – clear tokens so the user is forced to re-login
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      return false;
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // ── Error Interceptor ─────────────────────────────────────────────────
  // Uses handler.reject() (NOT throw) so the error stays in Dio's
  // pipeline as a proper DioException that datasource catch-blocks can
  // process via _handleDioError.
  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // For badResponse, enrich the message from the JSON body and
        // reject with the same type so the datasource can inspect it.
        if (error.type == DioExceptionType.badResponse) {
          final data = error.response?.data;
          final message = data is Map<String, dynamic>
              ? (data['message'] as String? ?? 'Something went wrong')
              : 'Something went wrong';

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              message: message,
              error: error.error,
            ),
          );
          return;
        }

        // All other error types: pass through unchanged so the
        // datasource's _handleDioError can map by DioExceptionType.
        handler.next(error);
      },
    );
  }

  // ── Logging Interceptor (debug only) ──────────────────────────────────
  LogInterceptor _loggingInterceptor() {
    return LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    );
  }

  // ── Convenience HTTP Methods ──────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  Future<Response> upload(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
    Options? options,
  }) =>
      _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options,
      );
}
