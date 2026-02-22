import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Retrieves a paginated, filterable list of service requests.
class GetServiceRequestsUseCase {
  final ServiceRepository _repository;

  const GetServiceRequestsUseCase(this._repository);

  Future<Either<Failure, List<ServiceRequestEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? priority,
    String? type,
    int? branchId,
    int? assignedToId,
  }) {
    return _repository.getServiceRequests(
      page: page,
      limit: limit,
      search: search,
      status: status,
      priority: priority,
      type: type,
      branchId: branchId,
      assignedToId: assignedToId,
    );
  }
}
