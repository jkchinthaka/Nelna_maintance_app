import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../models/inventory_model.dart';

/// Concrete implementation of [InventoryRepository].
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDatasource _remoteDatasource;

  InventoryRepositoryImpl(this._remoteDatasource);

  // ── Products ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    int? branchId,
    bool? lowStock,
  }) async {
    try {
      final response = await _remoteDatasource.getProducts(
        page: page,
        limit: limit,
        search: search,
        categoryId: categoryId,
        branchId: branchId,
        lowStock: lowStock,
      );

      final dataList = response['data'] is List ? response['data'] as List : [];
      final products = dataList
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(products);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(int id) async {
    try {
      final response = await _remoteDatasource.getProductById(id);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ProductModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createProduct(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ProductModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateProduct(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ProductModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      await _remoteDatasource.deleteProduct(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Categories ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final response = await _remoteDatasource.getCategories();
      final dataList = response['data'] is List ? response['data'] as List : [];
      final categories = dataList
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Suppliers ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<SupplierEntity>>> getSuppliers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _remoteDatasource.getSuppliers(
        page: page,
        limit: limit,
        search: search,
      );
      final dataList = response['data'] is List ? response['data'] as List : [];
      final suppliers = dataList
          .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(suppliers);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupplierEntity>> getSupplierById(int id) async {
    try {
      final response = await _remoteDatasource.getSupplierById(id);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(SupplierModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupplierEntity>> createSupplier(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createSupplier(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(SupplierModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SupplierEntity>> updateSupplier(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateSupplier(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(SupplierModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Purchase Orders ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<PurchaseOrderEntity>>> getPurchaseOrders({
    int page = 1,
    int limit = 20,
    String? status,
    int? supplierId,
  }) async {
    try {
      final response = await _remoteDatasource.getPurchaseOrders(
        page: page,
        limit: limit,
        status: status,
        supplierId: supplierId,
      );
      final dataList = response['data'] is List ? response['data'] as List : [];
      final orders = dataList
          .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderEntity>> getPurchaseOrderById(
    int id,
  ) async {
    try {
      final response = await _remoteDatasource.getPurchaseOrderById(id);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(PurchaseOrderModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderEntity>> createPurchaseOrder(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createPurchaseOrder(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(PurchaseOrderModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderEntity>> updatePurchaseOrder(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updatePurchaseOrder(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(PurchaseOrderModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderEntity>> approvePurchaseOrder(
    int id,
  ) async {
    try {
      final response = await _remoteDatasource.approvePurchaseOrder(id);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(PurchaseOrderModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── GRNs ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, GRNEntity>> createGRN(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createGRN(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(GRNModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GRNEntity>>> getGRNs(int purchaseOrderId) async {
    try {
      final response = await _remoteDatasource.getGRNs(purchaseOrderId);
      final dataList = response['data'] is List ? response['data'] as List : [];
      final grns = dataList
          .map((e) => GRNModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(grns);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Stock ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<StockMovementEntity>>> getStockMovements(
    int productId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDatasource.getStockMovements(
        productId,
        page: page,
        limit: limit,
      );
      final dataList = response['data'] is List ? response['data'] as List : [];
      final movements = dataList
          .map((e) => StockMovementModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(movements);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adjustStock(Map<String, dynamic> data) async {
    try {
      await _remoteDatasource.adjustStock(data);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockAlert>>> getStockAlerts({
    int? branchId,
  }) async {
    try {
      final response = await _remoteDatasource.getStockAlerts(
        branchId: branchId,
      );
      final dataList = response['data'] is List ? response['data'] as List : [];
      final alerts = dataList
          .map((e) => StockAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(alerts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
