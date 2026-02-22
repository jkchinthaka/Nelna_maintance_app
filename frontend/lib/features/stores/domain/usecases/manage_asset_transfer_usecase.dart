import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/asset_entity.dart';
import '../repositories/asset_repository.dart';

/// Handles creation and approval of asset transfers between branches.
class ManageAssetTransferUseCase {
  final AssetRepository _repository;

  const ManageAssetTransferUseCase(this._repository);

  /// Create a new transfer request.
  Future<Either<Failure, AssetTransferEntity>> createTransfer(
    Map<String, dynamic> data,
  ) {
    return _repository.createTransfer(data);
  }

  /// Approve or reject a pending transfer.
  Future<Either<Failure, AssetTransferEntity>> approveTransfer(
    int id, {
    required bool approved,
    String? notes,
  }) {
    return _repository.approveTransfer(id, approved: approved, notes: notes);
  }

  /// Get transfers with optional status filter.
  Future<Either<Failure, List<AssetTransferEntity>>> getTransfers({
    int page = 1,
    int limit = 20,
    String? status,
  }) {
    return _repository.getTransfers(
      page: page,
      limit: limit,
      status: status,
    );
  }
}
