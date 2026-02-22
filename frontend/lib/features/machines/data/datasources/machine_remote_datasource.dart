import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for machine‑related API calls.
class MachineRemoteDatasource {
  final ApiClient _client;

  MachineRemoteDatasource(this._client);

  // ── Machines CRUD ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMachines({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? type,
    int? branchId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
      if (branchId != null) 'branchId': branchId,
    };

    final response = await _client.get(
      ApiConstants.machines,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMachineById(int id) async {
    final response = await _client.get('${ApiConstants.machines}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createMachine(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.machines, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMachine(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.machines}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteMachine(int id) async {
    await _client.delete('${ApiConstants.machines}/$id');
  }

  // ── Maintenance Schedules ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getMaintenanceSchedules(int machineId) async {
    final response = await _client.get(
      '${ApiConstants.machines}/$machineId/schedules',
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createMaintenanceSchedule(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      ApiConstants.machineSchedules,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMaintenanceSchedule(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.machineSchedules}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Breakdown Logs ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBreakdownLogs(
    int machineId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '${ApiConstants.machines}/$machineId/breakdowns',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBreakdownLog(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      ApiConstants.machineBreakdowns,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBreakdownLog(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.machineBreakdowns}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── AMC Contracts ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAMCContracts(int machineId) async {
    final response = await _client.get(
      '${ApiConstants.machines}/$machineId/amc',
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAMCContract(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(ApiConstants.machineAMC, data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Service History ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getServiceHistory(
    int machineId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '${ApiConstants.machines}/$machineId/service-history',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Upcoming Maintenance ───────────────────────────────────────────────

  Future<Map<String, dynamic>> getUpcomingMaintenance() async {
    final response = await _client.get(
      '${ApiConstants.machineSchedules}/upcoming',
    );
    return response.data as Map<String, dynamic>;
  }
}
