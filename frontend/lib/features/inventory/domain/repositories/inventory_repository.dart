import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inventory_entity.dart';

/// Contract for the inventory data layer.
abstract class InventoryRepository {
  // ── Products ──────────────────────────────────────────────────────────

  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    int? branchId,
    bool? lowStock,
  });

  Future<Either<Failure, ProductEntity>> getProductById(int id);

  Future<Either<Failure, ProductEntity>> createProduct(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ProductEntity>> updateProduct(
    int id,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, void>> deleteProduct(int id);

  // ── Categories ────────────────────────────────────────────────────────

  Future<Either<Failure, List<CategoryEntity>>> getCategories();

  // ── Suppliers ─────────────────────────────────────────────────────────

  Future<Either<Failure, List<SupplierEntity>>> getSuppliers({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Either<Failure, SupplierEntity>> getSupplierById(int id);

  Future<Either<Failure, SupplierEntity>> createSupplier(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, SupplierEntity>> updateSupplier(
    int id,
    Map<String, dynamic> data,
  );

  // ── Purchase Orders ───────────────────────────────────────────────────

  Future<Either<Failure, List<PurchaseOrderEntity>>> getPurchaseOrders({
    int page = 1,
    int limit = 20,
    String? status,
    int? supplierId,
  });

  Future<Either<Failure, PurchaseOrderEntity>> getPurchaseOrderById(int id);

  Future<Either<Failure, PurchaseOrderEntity>> createPurchaseOrder(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, PurchaseOrderEntity>> updatePurchaseOrder(
    int id,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, PurchaseOrderEntity>> approvePurchaseOrder(int id);

  // ── GRNs ──────────────────────────────────────────────────────────────

  Future<Either<Failure, GRNEntity>> createGRN(Map<String, dynamic> data);

  Future<Either<Failure, List<GRNEntity>>> getGRNs(int purchaseOrderId);

  // ── Stock ─────────────────────────────────────────────────────────────

  Future<Either<Failure, List<StockMovementEntity>>> getStockMovements(
    int productId, {
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, void>> adjustStock(Map<String, dynamic> data);

  Future<Either<Failure, List<StockAlert>>> getStockAlerts({int? branchId});
}
