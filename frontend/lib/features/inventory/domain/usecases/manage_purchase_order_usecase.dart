import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

/// Manages purchase order creation and approval workflows.
class ManagePurchaseOrderUseCase {
  final InventoryRepository _repository;

  const ManagePurchaseOrderUseCase(this._repository);

  /// Creates a new purchase order (Draft or Submitted).
  Future<Either<Failure, PurchaseOrderEntity>> create(
    Map<String, dynamic> data,
  ) {
    return _repository.createPurchaseOrder(data);
  }

  /// Approves a submitted purchase order.
  Future<Either<Failure, PurchaseOrderEntity>> approve(int id) {
    return _repository.approvePurchaseOrder(id);
  }

  /// Updates an existing draft purchase order.
  Future<Either<Failure, PurchaseOrderEntity>> update(
    int id,
    Map<String, dynamic> data,
  ) {
    return _repository.updatePurchaseOrder(id, data);
  }
}
