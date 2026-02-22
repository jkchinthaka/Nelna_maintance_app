import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vehicle_entity.dart';
import '../repositories/vehicle_repository.dart';

/// Creates a new vehicle record.
class CreateVehicleUseCase {
  final VehicleRepository _repository;

  const CreateVehicleUseCase(this._repository);

  Future<Either<Failure, VehicleEntity>> call(Map<String, dynamic> data) {
    return _repository.createVehicle(data);
  }
}
