import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/machine_entity.dart';
import '../repositories/machine_repository.dart';

/// Creates a new machine record.
class CreateMachineUseCase {
  final MachineRepository _repository;

  const CreateMachineUseCase(this._repository);

  Future<Either<Failure, MachineEntity>> call(Map<String, dynamic> data) {
    return _repository.createMachine(data);
  }
}
