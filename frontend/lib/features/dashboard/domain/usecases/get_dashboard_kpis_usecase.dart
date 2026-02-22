import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

/// Fetches aggregated dashboard KPIs.
class GetDashboardKPIsUseCase {
  final DashboardRepository _repository;

  const GetDashboardKPIsUseCase(this._repository);

  Future<Either<Failure, DashboardKPIs>> call({int? branchId}) {
    return _repository.getDashboardKPIs(branchId: branchId);
  }
}
