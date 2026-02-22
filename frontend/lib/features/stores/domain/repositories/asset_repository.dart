import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/asset_entity.dart';

/// Contract for the asset / store management data layer.
abstract class AssetRepository {
  // ── Assets CRUD ─────────────────────────────────────────────────────────

  Future<Either<Failure, List<AssetEntity>>> getAssets({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? condition,
    String? category,
    int? branchId,
  });

  Future<Either<Failure, AssetEntity>> getAssetById(int id);

  Future<Either<Failure, AssetEntity>> createAsset(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, AssetEntity>> updateAsset(
    int id,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, void>> disposeAsset(
    int id, {
    String? reason,
  });

  // ── Repair Logs ─────────────────────────────────────────────────────────

  Future<Either<Failure, List<AssetRepairLogEntity>>> getRepairLogs(
    int assetId, {
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, AssetRepairLogEntity>> createRepairLog(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, AssetRepairLogEntity>> updateRepairLog(
    int id,
    Map<String, dynamic> data,
  );

  // ── Transfers ───────────────────────────────────────────────────────────

  Future<Either<Failure, List<AssetTransferEntity>>> getTransfers({
    int page = 1,
    int limit = 20,
    String? status,
  });

  Future<Either<Failure, AssetTransferEntity>> createTransfer(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, AssetTransferEntity>> approveTransfer(
    int id, {
    required bool approved,
    String? notes,
  });

  // ── Depreciation Summary ────────────────────────────────────────────────

  Future<Either<Failure, AssetDepreciationSummary>> getDepreciationSummary({
    int? branchId,
  });
}
