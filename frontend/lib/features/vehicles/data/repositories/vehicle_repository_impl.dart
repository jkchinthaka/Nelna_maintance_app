import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_datasource.dart';
import '../models/vehicle_model.dart';

/// Concrete implementation of [VehicleRepository].
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDatasource _remoteDatasource;

  VehicleRepositoryImpl(this._remoteDatasource);

  // ── CRUD ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<VehicleEntity>>> getVehicles({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? vehicleType,
    int? branchId,
  }) async {
    try {
      final response = await _remoteDatasource.getVehicles(
        page: page,
        limit: limit,
        search: search,
        status: status,
        vehicleType: vehicleType,
        branchId: branchId,
      );

      final dataList = response['data'] is List ? response['data'] as List : [];
      final vehicles = dataList
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(vehicles);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> getVehicleById(int id) async {
    try {
      final response = await _remoteDatasource.getVehicleById(id);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(VehicleModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> createVehicle(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createVehicle(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(VehicleModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> updateVehicle(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateVehicle(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(VehicleModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVehicle(int id) async {
    try {
      await _remoteDatasource.deleteVehicle(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Fuel Logs ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, FuelLogEntity>> addFuelLog(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.addFuelLog(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(FuelLogModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FuelLogEntity>>> getFuelLogs(
    int vehicleId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDatasource.getFuelLogs(
        vehicleId,
        page: page,
        limit: limit,
      );

      final dataList = response['data'] is List ? response['data'] as List : [];
      final logs = dataList
          .map((e) => FuelLogModel.fromJson(e as Map<String, dynamic>))
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

  // ── Documents ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, VehicleDocumentEntity>> addDocument(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.addDocument(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(VehicleDocumentModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Driver Assignment ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, VehicleDriverEntity>> assignDriver(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.assignDriver(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(VehicleDriverModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Service Reminders ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceReminder>>> getServiceReminders() async {
    try {
      final response = await _remoteDatasource.getServiceReminders();
      final dataList = response['data'] is List ? response['data'] as List : [];
      final reminders = dataList
          .map((e) => ServiceReminderModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(reminders);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Cost Analytics ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, VehicleCostAnalytics>> getCostAnalytics(
    int vehicleId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _remoteDatasource.getCostAnalytics(
        vehicleId,
        startDate: startDate,
        endDate: endDate,
      );
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(VehicleCostAnalyticsModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
