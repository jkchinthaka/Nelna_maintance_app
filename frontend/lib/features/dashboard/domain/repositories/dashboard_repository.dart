import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_entity.dart';

/// Contract for dashboard data operations.
abstract class DashboardRepository {
  /// Fetch aggregated KPI counts for the dashboard.
  ///
  /// When [branchId] is provided, results are scoped to that branch.
  Future<Either<Failure, DashboardKPIs>> getDashboardKPIs({int? branchId});

  /// Fetch monthly trend data for charts.
  ///
  /// [year] defaults to the current year on the server when omitted.
  Future<Either<Failure, MonthlyTrendsResponse>> getMonthlyTrends({
    int? branchId,
    int? year,
  });

  /// Fetch service request distribution statistics.
  Future<Either<Failure, ServiceRequestStats>> getServiceRequestStats({
    int? branchId,
  });
}
