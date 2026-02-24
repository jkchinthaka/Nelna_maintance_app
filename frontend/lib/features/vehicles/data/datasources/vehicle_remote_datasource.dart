import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for vehicle‑related API calls.
class VehicleRemoteDatasource {
  final ApiClient _client;

  VehicleRemoteDatasource(this._client);

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVehicles({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? vehicleType,
    int? branchId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (vehicleType != null && vehicleType.isNotEmpty)
        'vehicleType': vehicleType,
      if (branchId != null) 'branchId': branchId,
    };

    final response = await _client.get(
      ApiConstants.vehicles,
      queryParameters: queryParameters,
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVehicleById(int id) async {
    final response = await _client.get('${ApiConstants.vehicles}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.vehicles, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVehicle(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.vehicles}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteVehicle(int id) async {
    await _client.delete('${ApiConstants.vehicles}/$id');
  }

  // ── Fuel Logs ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addFuelLog(Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiConstants.vehicleFuelLogs,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFuelLogs(
    int vehicleId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '${ApiConstants.vehicles}/$vehicleId/fuel-logs',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Documents ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addDocument(Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiConstants.vehicleDocuments,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Driver Assignment ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> assignDriver(Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiConstants.vehicleAssignDriver,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Service Reminders ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getServiceReminders() async {
    final response = await _client.get(ApiConstants.vehicleReminders);
    return response.data as Map<String, dynamic>;
  }

  // ── Cost Analytics ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCostAnalytics(
    int vehicleId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null)
        'startDate': startDate.toIso8601String().split('T').first,
      if (endDate != null)
        'endDate': endDate.toIso8601String().split('T').first,
    };

    final response = await _client.get(
      '${ApiConstants.vehicles}/$vehicleId/cost-analytics',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}
