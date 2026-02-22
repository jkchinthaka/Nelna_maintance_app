import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/asset_entity.dart';
import '../repositories/asset_repository.dart';

/// Retrieves a paginated, filterable list of assets.
class GetAssetsUseCase {
  final AssetRepository _repository;

  const GetAssetsUseCase(this._repository);

  Future<Either<Failure, List<AssetEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? condition,
    String? category,
    int? branchId,
  }) {
    return _repository.getAssets(
      page: page,
      limit: limit,
      search: search,
      status: status,
      condition: condition,
      category: category,
      branchId: branchId,
    );
  }
}
