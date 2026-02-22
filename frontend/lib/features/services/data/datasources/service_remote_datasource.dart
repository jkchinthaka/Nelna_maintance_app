import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for service request–related API calls.
class ServiceRemoteDatasource {
  final ApiClient _client;

  ServiceRemoteDatasource(this._client);

  // ── Service Requests ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getServiceRequests({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? priority,
    String? type,
    int? branchId,
    int? assignedToId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (type != null && type.isNotEmpty) 'type': type,
      if (branchId != null) 'branchId': branchId,
      if (assignedToId != null) 'assignedToId': assignedToId,
    };

    final response = await _client.get(
      ApiConstants.services,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getServiceRequestById(int id) async {
    final response = await _client.get('${ApiConstants.services}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createServiceRequest(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(ApiConstants.services, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateServiceRequest(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.services}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approveServiceRequest(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.patch(
      '${ApiConstants.services}/$id/approve',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectServiceRequest(
    int id,
    String reason,
  ) async {
    final response = await _client.patch(
      '${ApiConstants.services}/$id/reject',
      data: {'rejectionReason': reason},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeServiceRequest(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.patch(
      '${ApiConstants.services}/$id/complete',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Tasks ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getServiceTasks(int serviceRequestId) async {
    final response = await _client.get(
      '${ApiConstants.services}/$serviceRequestId/tasks',
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createServiceTask(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(ApiConstants.serviceTasks, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateServiceTask(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.serviceTasks}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Spare Parts ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSpareParts(int serviceRequestId) async {
    final response = await _client.get(
      '${ApiConstants.services}/$serviceRequestId/spare-parts',
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addSparePart(Map<String, dynamic> data) async {
    final response = await _client.post(
      ApiConstants.serviceSpareParts,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSparePart(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.serviceSpareParts}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── SLA Metrics ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSLAMetrics({
    int? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      if (branchId != null) 'branchId': branchId,
      if (startDate != null)
        'startDate': startDate.toIso8601String().split('T').first,
      if (endDate != null)
        'endDate': endDate.toIso8601String().split('T').first,
    };

    final response = await _client.get(
      '${ApiConstants.services}/sla-metrics',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── My Requests ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyServiceRequests({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '${ApiConstants.services}/my-requests',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }
}
