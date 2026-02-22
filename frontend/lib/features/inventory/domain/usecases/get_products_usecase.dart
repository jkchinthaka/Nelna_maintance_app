import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inventory_entity.dart';
import '../repositories/inventory_repository.dart';

/// Retrieves a paginated, filterable list of products.
class GetProductsUseCase {
  final InventoryRepository _repository;

  const GetProductsUseCase(this._repository);

  Future<Either<Failure, List<ProductEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    int? branchId,
    bool? lowStock,
  }) {
    return _repository.getProducts(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      branchId: branchId,
      lowStock: lowStock,
    );
  }
}
