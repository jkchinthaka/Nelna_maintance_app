import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// Remote data source for inventory‑related API calls.
class InventoryRemoteDatasource {
  final ApiClient _client;

  InventoryRemoteDatasource(this._client);

  // ── Products ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    int? branchId,
    bool? lowStock,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categoryId': categoryId,
      if (branchId != null) 'branchId': branchId,
      if (lowStock != null) 'lowStock': lowStock,
    };

    final response = await _client.get(
      ApiConstants.products,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProductById(int id) async {
    final response = await _client.get('${ApiConstants.products}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.products, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.products}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteProduct(int id) async {
    await _client.delete('${ApiConstants.products}/$id');
  }

  // ── Categories ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCategories() async {
    final response = await _client.get(ApiConstants.categories);
    return response.data as Map<String, dynamic>;
  }

  // ── Suppliers ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSuppliers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _client.get(
      ApiConstants.suppliers,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSupplierById(int id) async {
    final response = await _client.get('${ApiConstants.suppliers}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.suppliers, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSupplier(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.suppliers}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Purchase Orders ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPurchaseOrders({
    int page = 1,
    int limit = 20,
    String? status,
    int? supplierId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (supplierId != null) 'supplierId': supplierId,
    };

    final response = await _client.get(
      ApiConstants.purchaseOrders,
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPurchaseOrderById(int id) async {
    final response = await _client.get('${ApiConstants.purchaseOrders}/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPurchaseOrder(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      ApiConstants.purchaseOrders,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePurchaseOrder(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      '${ApiConstants.purchaseOrders}/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approvePurchaseOrder(int id) async {
    final response = await _client.post(
      '${ApiConstants.purchaseOrders}/$id/approve',
    );
    return response.data as Map<String, dynamic>;
  }

  // ── GRNs ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createGRN(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.grns, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGRNs(int purchaseOrderId) async {
    final response = await _client.get(
      ApiConstants.grns,
      queryParameters: {'purchaseOrderId': purchaseOrderId},
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Stock ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStockMovements(
    int productId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '${ApiConstants.products}/$productId/stock-movements',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> adjustStock(Map<String, dynamic> data) async {
    final response = await _client.post(
      '${ApiConstants.products}/adjust-stock',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStockAlerts({int? branchId}) async {
    final queryParameters = <String, dynamic>{
      if (branchId != null) 'branchId': branchId,
    };

    final response = await _client.get(
      '${ApiConstants.products}/stock-alerts',
      queryParameters: queryParameters,
    );
    return response.data as Map<String, dynamic>;
  }
}
