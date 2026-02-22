import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Concrete implementation of [DashboardRepository].
///
/// Delegates to the remote data source and maps exceptions to
/// domain [Failure]s via `Either`.
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl({required DashboardRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  // ── KPIs ────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, DashboardKPIs>> getDashboardKPIs({
    int? branchId,
  }) async {
    try {
      final result = await _remoteDataSource.getDashboardKPIs(
        branchId: branchId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Monthly Trends ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, MonthlyTrendsResponse>> getMonthlyTrends({
    int? branchId,
    int? year,
  }) async {
    try {
      final result = await _remoteDataSource.getMonthlyTrends(
        branchId: branchId,
        year: year,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Service Request Stats ───────────────────────────────────────────
  @override
  Future<Either<Failure, ServiceRequestStats>> getServiceRequestStats({
    int? branchId,
  }) async {
    try {
      final result = await _remoteDataSource.getServiceRequestStats(
        branchId: branchId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
