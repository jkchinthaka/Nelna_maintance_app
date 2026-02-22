import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Handles creation and updating of service tasks.
class ManageServiceTaskUseCase {
  final ServiceRepository _repository;

  const ManageServiceTaskUseCase(this._repository);

  /// Creates a new task under a service request.
  Future<Either<Failure, ServiceTaskEntity>> createTask(
    Map<String, dynamic> data,
  ) {
    return _repository.createServiceTask(data);
  }

  /// Updates an existing task (status, hours, notes, etc.).
  Future<Either<Failure, ServiceTaskEntity>> updateTask(
    int id,
    Map<String, dynamic> data,
  ) {
    return _repository.updateServiceTask(id, data);
  }

  /// Convenience: mark a task as completed.
  Future<Either<Failure, ServiceTaskEntity>> completeTask(int id) {
    return _repository.updateServiceTask(id, {
      'status': 'Completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Convenience: mark a task as in progress.
  Future<Either<Failure, ServiceTaskEntity>> startTask(int id) {
    return _repository.updateServiceTask(id, {
      'status': 'InProgress',
      'startedAt': DateTime.now().toIso8601String(),
    });
  }
}
