import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Creates a new service request.
class CreateServiceRequestUseCase {
  final ServiceRepository _repository;

  const CreateServiceRequestUseCase(this._repository);

  Future<Either<Failure, ServiceRequestEntity>> call(
    Map<String, dynamic> data,
  ) {
    return _repository.createServiceRequest(data);
  }
}
