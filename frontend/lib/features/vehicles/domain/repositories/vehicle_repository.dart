import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vehicle_entity.dart';

/// Contract for the vehicle data layer.
abstract class VehicleRepository {
  // ── CRUD ────────────────────────────────────────────────────────────────
  Future<Either<Failure, List<VehicleEntity>>> getVehicles({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    int? branchId,
  });

  Future<Either<Failure, VehicleEntity>> getVehicleById(int id);

  Future<Either<Failure, VehicleEntity>> createVehicle(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, VehicleEntity>> updateVehicle(
    int id,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, void>> deleteVehicle(int id);

  // ── Fuel Logs ──────────────────────────────────────────────────────────
  Future<Either<Failure, FuelLogEntity>> addFuelLog(Map<String, dynamic> data);

  Future<Either<Failure, List<FuelLogEntity>>> getFuelLogs(
    int vehicleId, {
    int page = 1,
    int limit = 20,
  });

  // ── Documents ──────────────────────────────────────────────────────────
  Future<Either<Failure, VehicleDocumentEntity>> addDocument(
    Map<String, dynamic> data,
  );

  // ── Driver Assignment ──────────────────────────────────────────────────
  Future<Either<Failure, VehicleDriverEntity>> assignDriver(
    Map<String, dynamic> data,
  );

  // ── Service Reminders ──────────────────────────────────────────────────
  Future<Either<Failure, List<ServiceReminder>>> getServiceReminders();

  // ── Cost Analytics ─────────────────────────────────────────────────────
  Future<Either<Failure, VehicleCostAnalytics>> getCostAnalytics(
    int vehicleId, {
    DateTime? startDate,
    DateTime? endDate,
  });
}
