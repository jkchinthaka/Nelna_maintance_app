import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/export_report_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Infrastructure Providers
// ═══════════════════════════════════════════════════════════════════════════

final reportRemoteDatasourceProvider = Provider<ReportRemoteDatasource>(
  (ref) => ReportRemoteDatasourceImpl(ApiClient()),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepositoryImpl(ref.read(reportRemoteDatasourceProvider)),
);

final exportReportUseCaseProvider = Provider<ExportReportUseCase>(
  (ref) => ExportReportUseCase(ref.read(reportRepositoryProvider)),
);

// ═══════════════════════════════════════════════════════════════════════════
//  Filter State Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Selected date range for reports. Defaults to the current month.
final reportDateRangeProvider =
    NotifierProvider<_ReportDateRangeNotifier, DateTimeRange>(
  _ReportDateRangeNotifier.new,
);

class _ReportDateRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  void set(DateTimeRange value) => state = value;
}

/// Selected branch id (null = all branches).
final reportBranchProvider = NotifierProvider<_ReportBranchNotifier, int?>(
  _ReportBranchNotifier.new,
);

class _ReportBranchNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? value) => state = value;
}

/// Selected expense category filter (null = all categories).
final reportExpenseCategoryProvider =
    NotifierProvider<_ReportExpenseCategoryNotifier, String?>(
  _ReportExpenseCategoryNotifier.new,
);

class _ReportExpenseCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Param Classes
// ═══════════════════════════════════════════════════════════════════════════

class ReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int? branchId;

  const ReportParams({
    required this.startDate,
    required this.endDate,
    this.branchId,
  });

  @override
  List<Object?> get props => [startDate, endDate, branchId];
}

class ExpenseReportProviderParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int? branchId;
  final String? category;

  const ExpenseReportProviderParams({
    required this.startDate,
    required this.endDate,
    this.branchId,
    this.category,
  });

  @override
  List<Object?> get props => [startDate, endDate, branchId, category];
}

class ExportParams extends Equatable {
  final String type;
  final String format;
  final DateTime startDate;
  final DateTime endDate;
  final int? branchId;

  const ExportParams({
    required this.type,
    required this.format,
    required this.startDate,
    required this.endDate,
    this.branchId,
  });

  @override
  List<Object?> get props => [type, format, startDate, endDate, branchId];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Data Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Maintenance report – keyed by date range + branch.
final maintenanceReportProvider =
    FutureProvider.family<MaintenanceReportEntity, ReportParams>((
  ref,
  params,
) async {
  final repo = ref.read(reportRepositoryProvider);
  final result = await repo.getMaintenanceReport(
    startDate: params.startDate,
    endDate: params.endDate,
    branchId: params.branchId,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (report) => report,
  );
});

/// Vehicle report – keyed by date range + branch.
final vehicleReportProvider =
    FutureProvider.family<VehicleReportEntity, ReportParams>((
  ref,
  params,
) async {
  final repo = ref.read(reportRepositoryProvider);
  final result = await repo.getVehicleReport(
    startDate: params.startDate,
    endDate: params.endDate,
    branchId: params.branchId,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (report) => report,
  );
});

/// Inventory report – keyed by optional branch.
final inventoryReportProvider =
    FutureProvider.family<InventoryReportEntity, int?>((ref, branchId) async {
  final repo = ref.read(reportRepositoryProvider);
  final result = await repo.getInventoryReport(branchId: branchId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (report) => report,
  );
});

/// Expense report – keyed by date range + branch + category.
final expenseReportProvider =
    FutureProvider.family<ExpenseReportEntity, ExpenseReportProviderParams>((
  ref,
  params,
) async {
  final repo = ref.read(reportRepositoryProvider);
  final result = await repo.getExpenseReport(
    startDate: params.startDate,
    endDate: params.endDate,
    branchId: params.branchId,
    category: params.category,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (report) => report,
  );
});

/// Export report – keyed by export params. Returns raw bytes (PDF / Excel).
final exportReportProvider = FutureProvider.family<Uint8List, ExportParams>((
  ref,
  params,
) async {
  final useCase = ref.read(exportReportUseCaseProvider);
  final result = await useCase(
    ExportReportParams(
      type: params.type,
      format: params.format,
      startDate: params.startDate,
      endDate: params.endDate,
      branchId: params.branchId,
    ),
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (bytes) => bytes,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
//  Convenience – auto-wired providers that read global filters
// ═══════════════════════════════════════════════════════════════════════════

/// Auto-parameterized maintenance report using the global date range + branch.
final autoMaintenanceReportProvider = FutureProvider<MaintenanceReportEntity>((
  ref,
) async {
  final range = ref.watch(reportDateRangeProvider);
  final branch = ref.watch(reportBranchProvider);
  return ref.watch(
    maintenanceReportProvider(
      ReportParams(
        startDate: range.start,
        endDate: range.end,
        branchId: branch,
      ),
    ).future,
  );
});

/// Auto-parameterized vehicle report.
final autoVehicleReportProvider = FutureProvider<VehicleReportEntity>((
  ref,
) async {
  final range = ref.watch(reportDateRangeProvider);
  final branch = ref.watch(reportBranchProvider);
  return ref.watch(
    vehicleReportProvider(
      ReportParams(
        startDate: range.start,
        endDate: range.end,
        branchId: branch,
      ),
    ).future,
  );
});

/// Auto-parameterized inventory report.
final autoInventoryReportProvider = FutureProvider<InventoryReportEntity>((
  ref,
) async {
  final branch = ref.watch(reportBranchProvider);
  return ref.watch(inventoryReportProvider(branch).future);
});

/// Auto-parameterized expense report.
final autoExpenseReportProvider = FutureProvider<ExpenseReportEntity>((
  ref,
) async {
  final range = ref.watch(reportDateRangeProvider);
  final branch = ref.watch(reportBranchProvider);
  final category = ref.watch(reportExpenseCategoryProvider);
  return ref.watch(
    expenseReportProvider(
      ExpenseReportProviderParams(
        startDate: range.start,
        endDate: range.end,
        branchId: branch,
        category: category,
      ),
    ).future,
  );
});
