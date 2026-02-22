import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/machine_entity.dart';

/// Contract for the machine data layer.
abstract class MachineRepository {
  // ── Machines CRUD ───────────────────────────────────────────────────────
  Future<Either<Failure, List<MachineEntity>>> getMachines({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? type,
    int? branchId,
  });

  Future<Either<Failure, MachineEntity>> getMachineById(int id);

  Future<Either<Failure, MachineEntity>> createMachine(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, MachineEntity>> updateMachine(
    int id,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, void>> deleteMachine(int id);

  // ── Maintenance Schedules ──────────────────────────────────────────────
  Future<Either<Failure, List<MaintenanceScheduleEntity>>>
  getMaintenanceSchedules(int machineId);

  Future<Either<Failure, MaintenanceScheduleEntity>> createMaintenanceSchedule(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, MaintenanceScheduleEntity>> updateMaintenanceSchedule(
    int id,
    Map<String, dynamic> data,
  );

  // ── Breakdown Logs ─────────────────────────────────────────────────────
  Future<Either<Failure, List<BreakdownLogEntity>>> getBreakdownLogs(
    int machineId, {
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, BreakdownLogEntity>> createBreakdownLog(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, BreakdownLogEntity>> updateBreakdownLog(
    int id,
    Map<String, dynamic> data,
  );

  // ── AMC Contracts ──────────────────────────────────────────────────────
  Future<Either<Failure, List<AMCContractEntity>>> getAMCContracts(
    int machineId,
  );

  Future<Either<Failure, AMCContractEntity>> createAMCContract(
    Map<String, dynamic> data,
  );

  // ── Service History ────────────────────────────────────────────────────
  Future<Either<Failure, List<MachineServiceHistoryEntity>>> getServiceHistory(
    int machineId, {
    int page = 1,
    int limit = 20,
  });

  // ── Upcoming Maintenance ───────────────────────────────────────────────
  Future<Either<Failure, List<MaintenanceScheduleEntity>>>
  getUpcomingMaintenance();
}
