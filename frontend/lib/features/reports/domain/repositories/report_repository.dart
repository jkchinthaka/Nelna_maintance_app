import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';

abstract class ReportRepository {
  /// Fetch maintenance analytics for the given date range and optional branch.
  Future<Either<Failure, MaintenanceReportEntity>> getMaintenanceReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  });

  /// Fetch vehicle fleet analytics for the given date range and optional branch.
  Future<Either<Failure, VehicleReportEntity>> getVehicleReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  });

  /// Fetch inventory snapshot report for an optional branch.
  Future<Either<Failure, InventoryReportEntity>> getInventoryReport({
    int? branchId,
  });

  /// Fetch expense analytics for the given date range, optional branch/category.
  Future<Either<Failure, ExpenseReportEntity>> getExpenseReport({
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
    String? category,
  });

  /// Export a report as a file (PDF or Excel).
  /// Returns raw bytes suitable for saving / sharing.
  Future<Either<Failure, Uint8List>> exportReport({
    required String type,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    int? branchId,
  });
}
