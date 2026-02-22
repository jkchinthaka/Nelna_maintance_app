import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/machine_entity.dart';
import '../repositories/machine_repository.dart';

/// Retrieves a paginated, filterable list of machines.
class GetMachinesUseCase {
  final MachineRepository _repository;

  const GetMachinesUseCase(this._repository);

  Future<Either<Failure, List<MachineEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? type,
    int? branchId,
  }) {
    return _repository.getMachines(
      page: page,
      limit: limit,
      search: search,
      status: status,
      type: type,
      branchId: branchId,
    );
  }
}
