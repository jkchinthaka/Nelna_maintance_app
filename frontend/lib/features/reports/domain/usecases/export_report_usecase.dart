import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/report_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Export Report Use-Case
// ═══════════════════════════════════════════════════════════════════════════

class ExportReportUseCase {
  final ReportRepository _repository;

  const ExportReportUseCase(this._repository);

  Future<Either<Failure, Uint8List>> call(ExportReportParams params) {
    return _repository.exportReport(
      type: params.type,
      format: params.format,
      startDate: params.startDate,
      endDate: params.endDate,
      branchId: params.branchId,
    );
  }
}

/// Parameters for exporting a report.
///
/// [type] – one of: maintenance, vehicle, inventory, expense
/// [format] – one of: pdf, excel
class ExportReportParams extends Equatable {
  final String type;
  final String format;
  final DateTime startDate;
  final DateTime endDate;
  final int? branchId;

  const ExportReportParams({
    required this.type,
    required this.format,
    required this.startDate,
    required this.endDate,
    this.branchId,
  });

  @override
  List<Object?> get props => [type, format, startDate, endDate, branchId];
}
