import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

/// Fetches monthly cost/request trend data for charts.
class GetMonthlyTrendsUseCase {
  final DashboardRepository _repository;

  const GetMonthlyTrendsUseCase(this._repository);

  Future<Either<Failure, MonthlyTrendsResponse>> call({
    int? branchId,
    int? year,
  }) {
    return _repository.getMonthlyTrends(branchId: branchId, year: year);
  }
}
