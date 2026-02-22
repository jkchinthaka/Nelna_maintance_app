import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/service_entity.dart';

/// Contract for the service request data layer.
abstract class ServiceRepository {
  // ── Service Requests ──────────────────────────────────────────────────

  Future<Either<Failure, List<ServiceRequestEntity>>> getServiceRequests({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? priority,
    String? type,
    int? branchId,
    int? assignedToId,
  });

  Future<Either<Failure, ServiceRequestEntity>> getServiceRequestById(int id);

  Future<Either<Failure, ServiceRequestEntity>> createServiceRequest(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ServiceRequestEntity>> updateServiceRequest(
    int id,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ServiceRequestEntity>> approveServiceRequest(
    int id,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ServiceRequestEntity>> rejectServiceRequest(
    int id,
    String reason,
  );

  Future<Either<Failure, ServiceRequestEntity>> completeServiceRequest(
    int id,
    Map<String, dynamic> data,
  );

  // ── Tasks ─────────────────────────────────────────────────────────────

  Future<Either<Failure, List<ServiceTaskEntity>>> getServiceTasks(
    int serviceRequestId,
  );

  Future<Either<Failure, ServiceTaskEntity>> createServiceTask(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ServiceTaskEntity>> updateServiceTask(
    int id,
    Map<String, dynamic> data,
  );

  // ── Spare Parts ───────────────────────────────────────────────────────

  Future<Either<Failure, List<ServiceSparePartEntity>>> getSpareParts(
    int serviceRequestId,
  );

  Future<Either<Failure, ServiceSparePartEntity>> addSparePart(
    Map<String, dynamic> data,
  );

  Future<Either<Failure, ServiceSparePartEntity>> updateSparePart(
    int id,
    Map<String, dynamic> data,
  );

  // ── SLA Metrics ───────────────────────────────────────────────────────

  Future<Either<Failure, ServiceSLAMetrics>> getSLAMetrics({
    int? branchId,
    DateTime? startDate,
    DateTime? endDate,
  });

  // ── My Requests ───────────────────────────────────────────────────────

  Future<Either<Failure, List<ServiceRequestEntity>>> getMyServiceRequests({
    int page = 1,
    int limit = 20,
  });
}
