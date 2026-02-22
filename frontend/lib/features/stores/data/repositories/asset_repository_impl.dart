import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_remote_datasource.dart';
import '../models/asset_model.dart';

/// Concrete implementation of [AssetRepository].
class AssetRepositoryImpl implements AssetRepository {
  final AssetRemoteDatasource _remoteDatasource;

  AssetRepositoryImpl(this._remoteDatasource);

  // ── Assets CRUD ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<AssetEntity>>> getAssets({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? condition,
    String? category,
    int? branchId,
  }) async {
    try {
      final response = await _remoteDatasource.getAssets(
        page: page,
        limit: limit,
        search: search,
        status: status,
        condition: condition,
        category: category,
        branchId: branchId,
      );

      final dataList = response['data'] is List ? response['data'] as List : [];
      final assets = dataList
          .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(assets);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssetEntity>> getAssetById(int id) async {
    try {
      final response = await _remoteDatasource.getAssetById(id);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssetEntity>> createAsset(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createAsset(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssetEntity>> updateAsset(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateAsset(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disposeAsset(int id, {String? reason}) async {
    try {
      await _remoteDatasource.disposeAsset(id, reason: reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Repair Logs ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<AssetRepairLogEntity>>> getRepairLogs(
    int assetId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDatasource.getRepairLogs(
        assetId,
        page: page,
        limit: limit,
      );

      final dataList = response['data'] is List ? response['data'] as List : [];
      final logs = dataList
          .map((e) => AssetRepairLogModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(logs);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssetRepairLogEntity>> createRepairLog(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createRepairLog(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetRepairLogModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssetRepairLogEntity>> updateRepairLog(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateRepairLog(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetRepairLogModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Transfers ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<AssetTransferEntity>>> getTransfers({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _remoteDatasource.getTransfers(
        page: page,
        limit: limit,
        status: status,
      );

      final dataList = response['data'] is List ? response['data'] as List : [];
      final transfers = dataList
          .map((e) => AssetTransferModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(transfers);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssetTransferEntity>> createTransfer(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createTransfer(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetTransferModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssetTransferEntity>> approveTransfer(
    int id, {
    required bool approved,
    String? notes,
  }) async {
    try {
      final response = await _remoteDatasource.approveTransfer(
        id,
        approved: approved,
        notes: notes,
      );
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetTransferModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Depreciation Summary ────────────────────────────────────────────────

  @override
  Future<Either<Failure, AssetDepreciationSummary>> getDepreciationSummary({
    int? branchId,
  }) async {
    try {
      final response = await _remoteDatasource.getDepreciationSummary(
        branchId: branchId,
      );
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AssetDepreciationSummaryModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
