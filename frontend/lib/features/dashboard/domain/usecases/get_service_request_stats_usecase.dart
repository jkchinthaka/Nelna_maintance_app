import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

/// Fetches service request distribution statistics.
class GetServiceRequestStatsUseCase {
  final DashboardRepository _repository;

  const GetServiceRequestStatsUseCase(this._repository);

  Future<Either<Failure, ServiceRequestStats>> call({int? branchId}) {
    return _repository.getServiceRequestStats(branchId: branchId);
  }
}
