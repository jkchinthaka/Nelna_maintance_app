import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

/// Retrieves stock alerts for products below their reorder point.
class GetStockAlertsUseCase {
  final InventoryRepository _repository;

  const GetStockAlertsUseCase(this._repository);

  Future<Either<Failure, List<StockAlert>>> call({int? branchId}) {
    return _repository.getStockAlerts(branchId: branchId);
  }
}
