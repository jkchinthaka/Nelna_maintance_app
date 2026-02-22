import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';
import '../models/service_model.dart';

/// Concrete implementation of [ServiceRepository].
class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDatasource _remoteDatasource;

  ServiceRepositoryImpl(this._remoteDatasource);

  // ── Service Requests ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceRequestEntity>>> getServiceRequests({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? priority,
    String? type,
    int? branchId,
    int? assignedToId,
  }) async {
    try {
      final response = await _remoteDatasource.getServiceRequests(
        page: page,
        limit: limit,
        search: search,
        status: status,
        priority: priority,
        type: type,
        branchId: branchId,
        assignedToId: assignedToId,
      );

      final dataList =
          response['data'] is List ? response['data'] as List : [];
      final requests = dataList
          .map((e) =>
              ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestEntity>> getServiceRequestById(
    int id,
  ) async {
    try {
      final response = await _remoteDatasource.getServiceRequestById(id);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceRequestModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestEntity>> createServiceRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createServiceRequest(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceRequestModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestEntity>> updateServiceRequest(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateServiceRequest(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceRequestModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestEntity>> approveServiceRequest(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.approveServiceRequest(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceRequestModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestEntity>> rejectServiceRequest(
    int id,
    String reason,
  ) async {
    try {
      final response =
          await _remoteDatasource.rejectServiceRequest(id, reason);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceRequestModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestEntity>> completeServiceRequest(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await _remoteDatasource.completeServiceRequest(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceRequestModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Tasks ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceTaskEntity>>> getServiceTasks(
    int serviceRequestId,
  ) async {
    try {
      final response =
          await _remoteDatasource.getServiceTasks(serviceRequestId);
      final dataList =
          response['data'] is List ? response['data'] as List : [];
      final tasks = dataList
          .map((e) => ServiceTaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceTaskEntity>> createServiceTask(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.createServiceTask(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceTaskModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceTaskEntity>> updateServiceTask(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateServiceTask(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceTaskModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Spare Parts ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceSparePartEntity>>> getSpareParts(
    int serviceRequestId,
  ) async {
    try {
      final response =
          await _remoteDatasource.getSpareParts(serviceRequestId);
      final dataList =
          response['data'] is List ? response['data'] as List : [];
      final parts = dataList
          .map((e) =>
              ServiceSparePartModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(parts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceSparePartEntity>> addSparePart(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.addSparePart(data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceSparePartModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceSparePartEntity>> updateSparePart(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _remoteDatasource.updateSparePart(id, data);
      final resData = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceSparePartModel.fromJson(resData));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── SLA Metrics ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ServiceSLAMetrics>> getSLAMetrics({
    int? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _remoteDatasource.getSLAMetrics(
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
      );
      final data = response['data'] as Map<String, dynamic>? ?? response;
      return Right(ServiceSLAMetricsModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── My Requests ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceRequestEntity>>> getMyServiceRequests({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDatasource.getMyServiceRequests(
        page: page,
        limit: limit,
      );

      final dataList =
          response['data'] is List ? response['data'] as List : [];
      final requests = dataList
          .map((e) =>
              ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
