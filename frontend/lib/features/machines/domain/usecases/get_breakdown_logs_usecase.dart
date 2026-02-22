import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/machine_entity.dart';
import '../repositories/machine_repository.dart';

/// Retrieves breakdown logs for a specific machine.
class GetBreakdownLogsUseCase {
  final MachineRepository _repository;

  const GetBreakdownLogsUseCase(this._repository);

  Future<Either<Failure, List<BreakdownLogEntity>>> call({
    required int machineId,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.getBreakdownLogs(machineId, page: page, limit: limit);
  }
}
