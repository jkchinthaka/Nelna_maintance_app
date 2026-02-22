import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/machine_entity.dart';
import '../../domain/repositories/machine_repository.dart';
import '../datasources/machine_remote_datasource.dart';
import '../models/machine_model.dart';

/// Concrete implementation of [MachineRepository].
class MachineRepositoryImpl implements MachineRepository {
  final MachineRemoteDatasource _remoteDatasource;

  MachineRepositoryImpl(this._remoteDatasource);

  // ── Machines CRUD ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MachineEntity>>> getMachines({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? type,
    int? branchId,
  }) async {
    try {
      final response = await _remoteDatasource.getMachines(
        page: page,
        limit: limit,
        search: search,
        status: status,
        type: type,
        branchId: branchId,
      );

      final dataList = response['data'] is List ? response['data'] as List : [];
      final machines = dataList
          .map((e) => MachineModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(machines);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MachineEntity>> getMachineById(int id) async {
    try {
      final response = await _remoteDatasource.getMachineById(id);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(MachineModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MachineEntity>> createMachine(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createMachine(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(MachineModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MachineEntity>> updateMachine(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateMachine(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(MachineModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMachine(int id) async {
    try {
      await _remoteDatasource.deleteMachine(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Maintenance Schedules ──────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MaintenanceScheduleEntity>>>
  getMaintenanceSchedules(int machineId) async {
    try {
      final response = await _remoteDatasource.getMaintenanceSchedules(
        machineId,
      );
      final dataList = response['data'] is List ? response['data'] as List : [];
      final schedules = dataList
          .map(
            (e) => MaintenanceScheduleModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return Right(schedules);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MaintenanceScheduleEntity>> createMaintenanceSchedule(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createMaintenanceSchedule(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(MaintenanceScheduleModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MaintenanceScheduleEntity>> updateMaintenanceSchedule(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateMaintenanceSchedule(
        id,
        data,
      );
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(MaintenanceScheduleModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Breakdown Logs ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<BreakdownLogEntity>>> getBreakdownLogs(
    int machineId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDatasource.getBreakdownLogs(
        machineId,
        page: page,
        limit: limit,
      );
      final dataList = response['data'] is List ? response['data'] as List : [];
      final logs = dataList
          .map((e) => BreakdownLogModel.fromJson(e as Map<String, dynamic>))
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
  Future<Either<Failure, BreakdownLogEntity>> createBreakdownLog(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createBreakdownLog(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(BreakdownLogModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BreakdownLogEntity>> updateBreakdownLog(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateBreakdownLog(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(BreakdownLogModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── AMC Contracts ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<AMCContractEntity>>> getAMCContracts(
    int machineId,
  ) async {
    try {
      final response = await _remoteDatasource.getAMCContracts(machineId);
      final dataList = response['data'] is List ? response['data'] as List : [];
      final contracts = dataList
          .map((e) => AMCContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(contracts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AMCContractEntity>> createAMCContract(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createAMCContract(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(AMCContractModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Service History ────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MachineServiceHistoryEntity>>> getServiceHistory(
    int machineId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDatasource.getServiceHistory(
        machineId,
        page: page,
        limit: limit,
      );
      final dataList = response['data'] is List ? response['data'] as List : [];
      final history = dataList
          .map(
            (e) =>
                MachineServiceHistoryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Upcoming Maintenance ───────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MaintenanceScheduleEntity>>>
  getUpcomingMaintenance() async {
    try {
      final response = await _remoteDatasource.getUpcomingMaintenance();
      final dataList = response['data'] is List ? response['data'] as List : [];
      final schedules = dataList
          .map(
            (e) => MaintenanceScheduleModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return Right(schedules);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
