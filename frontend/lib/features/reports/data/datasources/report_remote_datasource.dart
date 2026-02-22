import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDatasource {
  Future<MaintenanceReportModel> getMaintenanceReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  });

  Future<VehicleReportModel> getVehicleReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  });

  Future<InventoryReportModel> getInventoryReport({int? branchId});

  Future<ExpenseReportModel> getExpenseReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
    String? category,
  });

  Future<Uint8List> exportReport({
    required String type,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  });
}

class ReportRemoteDatasourceImpl implements ReportRemoteDatasource {
  final ApiClient _apiClient;

  ReportRemoteDatasourceImpl(this._apiClient);

  // ── Helper to format dates as ISO strings ───────────────────────────
  String _iso(DateTime dt) => dt.toIso8601String().split('T').first;

  // ── Maintenance Report ──────────────────────────────────────────────
  @override
  Future<MaintenanceReportModel> getMaintenanceReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': _iso(startDate),
        'endDate': _iso(endDate),
        if (branchId != null) 'branchId': branchId,
      };

      final response = await _apiClient.get(
        ApiConstants.reportMonthlyTrends,
        queryParameters: queryParams,
      );

      final data = response.data;
      final payload = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;

      return MaintenanceReportModel.fromJson(payload);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to load maintenance report: $e');
    }
  }

  // ── Vehicle Report ──────────────────────────────────────────────────
  @override
  Future<VehicleReportModel> getVehicleReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': _iso(startDate),
        'endDate': _iso(endDate),
        if (branchId != null) 'branchId': branchId,
      };

      final response = await _apiClient.get(
        ApiConstants.reportVehicleCosts,
        queryParameters: queryParams,
      );

      final data = response.data;
      final payload = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;

      return VehicleReportModel.fromJson(payload);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to load vehicle report: $e');
    }
  }

  // ── Inventory Report ────────────────────────────────────────────────
  @override
  Future<InventoryReportModel> getInventoryReport({int? branchId}) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null) 'branchId': branchId,
      };

      final response = await _apiClient.get(
        ApiConstants.reportInventoryUsage,
        queryParameters: queryParams,
      );

      final data = response.data;
      final payload = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;

      return InventoryReportModel.fromJson(payload);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to load inventory report: $e');
    }
  }

  // ── Expense Report ──────────────────────────────────────────────────
  @override
  Future<ExpenseReportModel> getExpenseReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': _iso(startDate),
        'endDate': _iso(endDate),
        if (branchId != null) 'branchId': branchId,
        if (category != null && category.isNotEmpty) 'category': category,
      };

      final response = await _apiClient.get(
        ApiConstants.reportExpenses,
        queryParameters: queryParams,
      );

      final data = response.data;
      final payload = data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;

      return ExpenseReportModel.fromJson(payload);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to load expense report: $e');
    }
  }

  // ── Export Report (returns raw bytes) ───────────────────────────────
  @override
  Future<Uint8List> exportReport({
    required String type,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': type,
        'format': format,
        'startDate': _iso(startDate),
        'endDate': _iso(endDate),
        if (branchId != null) 'branchId': branchId,
      };

      final response = await _apiClient.get(
        '${ApiConstants.dashboard}/export',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data as List<int>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to export report: $e');
    }
  }
}
