import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for asset / store management API calls.
class AssetRemoteDatasource {
  final ApiClient _client;

  AssetRemoteDatasource(this._client);

  // ── Assets CRUD ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAssets({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? condition,
    String? category,
    int? branchId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (category != null && category.isNotEmpty) 'category': category,
      if (branchId != null) 'branchId': branchId,
    };

    final response = await _client.get(
      ApiConstants.assets,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAssetById(int id) async {
    final response = await _client.get('${ApiConstants.assets}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAsset(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.assets, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAsset(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.assets}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> disposeAsset(int id, {String? reason}) async {
    await _client.patch(
      '${ApiConstants.assets}/$id/dispose',
      data: {if (reason != null) 'reason': reason},
    );
  }

  // ── Repair Logs ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getRepairLogs(
    int assetId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '${ApiConstants.assets}/$assetId/repairs',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRepairLog(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      ApiConstants.assetRepairs,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRepairLog(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.assetRepairs}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Transfers ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTransfers({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _client.get(
      ApiConstants.assetTransfers,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTransfer(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      ApiConstants.assetTransfers,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approveTransfer(
    int id, {
    required bool approved,
    String? notes,
  }) async {
    final response = await _client.patch(
      '${ApiConstants.assetTransfers}/$id/approve',
      data: {
        'approved': approved,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Depreciation Summary ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDepreciationSummary({
    int? branchId,
  }) async {
    final queryParameters = <String, dynamic>{
      if (branchId != null) 'branchId': branchId,
    };

    final response = await _client.get(
      '${ApiConstants.assets}/depreciation-summary',
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }
}
