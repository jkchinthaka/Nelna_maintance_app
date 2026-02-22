import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Infrastructure Providers
// ═══════════════════════════════════════════════════════════════════════════

final inventoryRemoteDatasourceProvider = Provider<InventoryRemoteDatasource>(
  (ref) => InventoryRemoteDatasource(ApiClient()),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepositoryImpl(ref.read(inventoryRemoteDatasourceProvider)),
);

// ═══════════════════════════════════════════════════════════════════════════
//  Filter / Param Classes
// ═══════════════════════════════════════════════════════════════════════════

class ProductListParams extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final int? categoryId;
  final int? branchId;
  final bool? lowStock;

  const ProductListParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.categoryId,
    this.branchId,
    this.lowStock,
  });

  ProductListParams copyWith({
    int? page,
    int? limit,
    String? search,
    int? categoryId,
    int? branchId,
    bool? lowStock,
  }) {
    return ProductListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      branchId: branchId ?? this.branchId,
      lowStock: lowStock ?? this.lowStock,
    );
  }

  @override
  List<Object?> get props => [
    page,
    limit,
    search,
    categoryId,
    branchId,
    lowStock,
  ];
}

class SupplierListParams extends Equatable {
  final int page;
  final int limit;
  final String? search;

  const SupplierListParams({this.page = 1, this.limit = 20, this.search});

  SupplierListParams copyWith({int? page, int? limit, String? search}) {
    return SupplierListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [page, limit, search];
}

class PurchaseOrderListParams extends Equatable {
  final int page;
  final int limit;
  final String? status;
  final int? supplierId;

  const PurchaseOrderListParams({
    this.page = 1,
    this.limit = 20,
    this.status,
    this.supplierId,
  });

  PurchaseOrderListParams copyWith({
    int? page,
    int? limit,
    String? status,
    int? supplierId,
  }) {
    return PurchaseOrderListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: status ?? this.status,
      supplierId: supplierId ?? this.supplierId,
    );
  }

  @override
  List<Object?> get props => [page, limit, status, supplierId];
}

class StockMovementParams extends Equatable {
  final int productId;
  final int page;
  final int limit;

  const StockMovementParams({
    required this.productId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [productId, page, limit];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Data Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Paginated + filtered product list.
final productListProvider =
    FutureProvider.family<List<ProductEntity>, ProductListParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(inventoryRepositoryProvider);
      final result = await repo.getProducts(
        page: params.page,
        limit: params.limit,
        search: params.search,
        categoryId: params.categoryId,
        branchId: params.branchId,
        lowStock: params.lowStock,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (products) => products,
      );
    });

/// Single product detail.
final productDetailProvider = FutureProvider.family<ProductEntity, int>((
  ref,
  id,
) async {
  final repo = ref.read(inventoryRepositoryProvider);
  final result = await repo.getProductById(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (product) => product,
  );
});

/// All categories.
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repo = ref.read(inventoryRepositoryProvider);
  final result = await repo.getCategories();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

/// Paginated + filtered supplier list.
final suppliersProvider =
    FutureProvider.family<List<SupplierEntity>, SupplierListParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(inventoryRepositoryProvider);
      final result = await repo.getSuppliers(
        page: params.page,
        limit: params.limit,
        search: params.search,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (suppliers) => suppliers,
      );
    });

/// Paginated + filtered purchase order list.
final purchaseOrderListProvider =
    FutureProvider.family<List<PurchaseOrderEntity>, PurchaseOrderListParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(inventoryRepositoryProvider);
      final result = await repo.getPurchaseOrders(
        page: params.page,
        limit: params.limit,
        status: params.status,
        supplierId: params.supplierId,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (orders) => orders,
      );
    });

/// Single purchase order detail.
final purchaseOrderDetailProvider =
    FutureProvider.family<PurchaseOrderEntity, int>((ref, id) async {
      final repo = ref.read(inventoryRepositoryProvider);
      final result = await repo.getPurchaseOrderById(id);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (order) => order,
      );
    });

/// Stock movements for a product.
final stockMovementsProvider =
    FutureProvider.family<List<StockMovementEntity>, StockMovementParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(inventoryRepositoryProvider);
      final result = await repo.getStockMovements(
        params.productId,
        page: params.page,
        limit: params.limit,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (movements) => movements,
      );
    });

/// Stock alerts (optionally filtered by branch).
final stockAlertsProvider = FutureProvider.family<List<StockAlert>, int?>((
  ref,
  branchId,
) async {
  final repo = ref.read(inventoryRepositoryProvider);
  final result = await repo.getStockAlerts(branchId: branchId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (alerts) => alerts,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
//  Product Form State Provider (Create / Edit)
// ═══════════════════════════════════════════════════════════════════════════

class ProductFormState {
  final bool isLoading;
  final String? errorMessage;
  final ProductEntity? savedProduct;

  const ProductFormState({
    this.isLoading = false,
    this.errorMessage,
    this.savedProduct,
  });

  ProductFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    ProductEntity? savedProduct,
  }) {
    return ProductFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      savedProduct: savedProduct,
    );
  }
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final InventoryRepository _repository;

  ProductFormNotifier(this._repository) : super(const ProductFormState());

  Future<bool> createProduct(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createProduct(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (product) {
        state = state.copyWith(isLoading: false, savedProduct: product);
        return true;
      },
    );
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateProduct(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (product) {
        state = state.copyWith(isLoading: false, savedProduct: product);
        return true;
      },
    );
  }

  Future<bool> adjustStock(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.adjustStock(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  void reset() => state = const ProductFormState();
}

final productFormProvider =
    StateNotifierProvider<ProductFormNotifier, ProductFormState>(
      (ref) => ProductFormNotifier(ref.read(inventoryRepositoryProvider)),
    );

// ═══════════════════════════════════════════════════════════════════════════
//  Purchase Order Form State Provider
// ═══════════════════════════════════════════════════════════════════════════

class POLineItem {
  final int? productId;
  final String? productName;
  final String? productCode;
  final int quantity;
  final double unitPrice;

  const POLineItem({
    this.productId,
    this.productName,
    this.productCode,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  double get totalPrice => quantity * unitPrice;

  POLineItem copyWith({
    int? productId,
    String? productName,
    String? productCode,
    int? quantity,
    double? unitPrice,
  }) {
    return POLineItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class PurchaseOrderFormState {
  final bool isLoading;
  final String? errorMessage;
  final PurchaseOrderEntity? savedOrder;
  final int? supplierId;
  final String? supplierName;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final List<POLineItem> lineItems;

  const PurchaseOrderFormState({
    this.isLoading = false,
    this.errorMessage,
    this.savedOrder,
    this.supplierId,
    this.supplierName,
    this.expectedDeliveryDate,
    this.notes,
    this.lineItems = const [],
  });

  double get grandTotal =>
      lineItems.fold(0, (sum, item) => sum + item.totalPrice);

  PurchaseOrderFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    PurchaseOrderEntity? savedOrder,
    int? supplierId,
    String? supplierName,
    DateTime? expectedDeliveryDate,
    String? notes,
    List<POLineItem>? lineItems,
  }) {
    return PurchaseOrderFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      savedOrder: savedOrder,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      notes: notes ?? this.notes,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}

class PurchaseOrderFormNotifier extends StateNotifier<PurchaseOrderFormState> {
  final InventoryRepository _repository;

  PurchaseOrderFormNotifier(this._repository)
    : super(const PurchaseOrderFormState());

  void setSupplier(int id, String name) {
    state = state.copyWith(supplierId: id, supplierName: name);
  }

  void setExpectedDeliveryDate(DateTime date) {
    state = state.copyWith(expectedDeliveryDate: date);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void addLineItem([POLineItem? item]) {
    final items = [...state.lineItems, item ?? const POLineItem()];
    state = state.copyWith(lineItems: items);
  }

  void updateLineItem(int index, POLineItem item) {
    final items = [...state.lineItems];
    if (index >= 0 && index < items.length) {
      items[index] = item;
      state = state.copyWith(lineItems: items);
    }
  }

  void removeLineItem(int index) {
    final items = [...state.lineItems];
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      state = state.copyWith(lineItems: items);
    }
  }

  /// Loads an existing PO into the form for editing.
  void loadOrder(PurchaseOrderEntity order) {
    state = PurchaseOrderFormState(
      supplierId: order.supplierId,
      supplierName: order.supplierName,
      expectedDeliveryDate: order.expectedDeliveryDate,
      notes: order.notes,
      lineItems: order.items
          .map(
            (e) => POLineItem(
              productId: e.productId,
              productName: e.productName,
              productCode: e.productCode,
              quantity: e.quantity,
              unitPrice: e.unitPrice,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> _buildPayload(String status) {
    return {
      'supplierId': state.supplierId,
      'status': status,
      if (state.expectedDeliveryDate != null)
        'expectedDeliveryDate': state.expectedDeliveryDate!.toIso8601String(),
      if (state.notes != null && state.notes!.isNotEmpty) 'notes': state.notes,
      'items': state.lineItems
          .where((e) => e.productId != null)
          .map(
            (e) => {
              'productId': e.productId,
              'quantity': e.quantity,
              'unitPrice': e.unitPrice,
            },
          )
          .toList(),
    };
  }

  Future<bool> saveDraft() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final payload = _buildPayload('Draft');
    final result = await _repository.createPurchaseOrder(payload);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (order) {
        state = state.copyWith(isLoading: false, savedOrder: order);
        return true;
      },
    );
  }

  Future<bool> submitForApproval() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final payload = _buildPayload('Submitted');
    final result = await _repository.createPurchaseOrder(payload);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (order) {
        state = state.copyWith(isLoading: false, savedOrder: order);
        return true;
      },
    );
  }

  Future<bool> updateOrder(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final payload = _buildPayload(state.savedOrder?.status ?? 'Draft');
    final result = await _repository.updatePurchaseOrder(id, payload);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (order) {
        state = state.copyWith(isLoading: false, savedOrder: order);
        return true;
      },
    );
  }

  Future<bool> approveOrder(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.approvePurchaseOrder(id);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (order) {
        state = state.copyWith(isLoading: false, savedOrder: order);
        return true;
      },
    );
  }

  void reset() => state = const PurchaseOrderFormState();
}

final purchaseOrderFormProvider =
    StateNotifierProvider<PurchaseOrderFormNotifier, PurchaseOrderFormState>(
      (ref) => PurchaseOrderFormNotifier(ref.read(inventoryRepositoryProvider)),
    );
