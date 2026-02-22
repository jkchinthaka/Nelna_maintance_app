import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Get Maintenance Report Use-Case
// ═══════════════════════════════════════════════════════════════════════════

class GetMaintenanceReportUseCase {
  final ReportRepository _repository;

  const GetMaintenanceReportUseCase(this._repository);

  Future<Either<Failure, MaintenanceReportEntity>> call(
    MaintenanceReportParams params,
  ) {
    return _repository.getMaintenanceReport(
      startDate: params.startDate,
      endDate: params.endDate,
      branchId: params.branchId,
    );
  }
}

class MaintenanceReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int? branchId;

  const MaintenanceReportParams({
    required this.startDate,
    required this.endDate,
    this.branchId,
  });

  @override
  List<Object?> get props => [startDate, endDate, branchId];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Get Vehicle Report Use-Case
// ═══════════════════════════════════════════════════════════════════════════

class GetVehicleReportUseCase {
  final ReportRepository _repository;

  const GetVehicleReportUseCase(this._repository);

  Future<Either<Failure, VehicleReportEntity>> call(
    VehicleReportParams params,
  ) {
    return _repository.getVehicleReport(
      startDate: params.startDate,
      endDate: params.endDate,
      branchId: params.branchId,
    );
  }
}

class VehicleReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int? branchId;

  const VehicleReportParams({
    required this.startDate,
    required this.endDate,
    this.branchId,
  });

  @override
  List<Object?> get props => [startDate, endDate, branchId];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Get Inventory Report Use-Case
// ═══════════════════════════════════════════════════════════════════════════

class GetInventoryReportUseCase {
  final ReportRepository _repository;

  const GetInventoryReportUseCase(this._repository);

  Future<Either<Failure, InventoryReportEntity>> call({int? branchId}) {
    return _repository.getInventoryReport(branchId: branchId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Get Expense Report Use-Case
// ═══════════════════════════════════════════════════════════════════════════

class GetExpenseReportUseCase {
  final ReportRepository _repository;

  const GetExpenseReportUseCase(this._repository);

  Future<Either<Failure, ExpenseReportEntity>> call(
    ExpenseReportParams params,
  ) {
    return _repository.getExpenseReport(
      startDate: params.startDate,
      endDate: params.endDate,
      branchId: params.branchId,
      category: params.category,
    );
  }
}

class ExpenseReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int? branchId;
  final String? category;

  const ExpenseReportParams({
    required this.startDate,
    required this.endDate,
    this.branchId,
    this.category,
  });

  @override
  List<Object?> get props => [startDate, endDate, branchId, category];
}
