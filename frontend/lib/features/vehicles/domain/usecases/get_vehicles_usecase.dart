import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vehicle_entity.dart';
import '../repositories/vehicle_repository.dart';

/// Retrieves a paginated, filterable list of vehicles.
class GetVehiclesUseCase {
  final VehicleRepository _repository;

  const GetVehiclesUseCase(this._repository);

  Future<Either<Failure, List<VehicleEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? vehicleType,
    int? branchId,
  }) {
    return _repository.getVehicles(
      page: page,
      limit: limit,
      search: search,
      status: status,
      vehicleType: vehicleType,
      branchId: branchId,
    );
  }
}
