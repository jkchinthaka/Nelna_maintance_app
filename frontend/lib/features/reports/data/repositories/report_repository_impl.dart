import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDatasource _remoteDatasource;

  ReportRepositoryImpl(this._remoteDatasource);

  // ── Maintenance Report ──────────────────────────────────────────────
  @override
  Future<Either<Failure, MaintenanceReportEntity>> getMaintenanceReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  }) async {
    try {
      final result = await _remoteDatasource.getMaintenanceReport(
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // ── Vehicle Report ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, VehicleReportEntity>> getVehicleReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  }) async {
    try {
      final result = await _remoteDatasource.getVehicleReport(
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // ── Inventory Report ────────────────────────────────────────────────
  @override
  Future<Either<Failure, InventoryReportEntity>> getInventoryReport({
    int? branchId,
  }) async {
    try {
      final result = await _remoteDatasource.getInventoryReport(
        branchId: branchId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // ── Expense Report ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, ExpenseReportEntity>> getExpenseReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
    String? category,
  }) async {
    try {
      final result = await _remoteDatasource.getExpenseReport(
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
        category: category,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // ── Export Report ───────────────────────────────────────────────────
  @override
  Future<Either<Failure, Uint8List>> exportReport({
    required String type,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  }) async {
    try {
      final result = await _remoteDatasource.exportReport(
        type: type,
        format: format,
        startDate: startDate,
        endDate: endDate,
        branchId: branchId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to export report: $e'));
    }
  }
}
