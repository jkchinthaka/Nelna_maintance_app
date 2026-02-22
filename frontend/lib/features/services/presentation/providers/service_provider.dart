import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/service_remote_datasource.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Infrastructure Providers
// ═══════════════════════════════════════════════════════════════════════════

final serviceRemoteDatasourceProvider = Provider<ServiceRemoteDatasource>(
  (ref) => ServiceRemoteDatasource(ApiClient()),
);

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepositoryImpl(ref.read(serviceRemoteDatasourceProvider)),
);

// ═══════════════════════════════════════════════════════════════════════════
//  Filter / Param classes
// ═══════════════════════════════════════════════════════════════════════════

class ServiceListParams extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? priority;
  final String? type;
  final int? branchId;
  final int? assignedToId;

  const ServiceListParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.priority,
    this.type,
    this.branchId,
    this.assignedToId,
  });

  ServiceListParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? priority,
    String? type,
    int? branchId,
    int? assignedToId,
  }) {
    return ServiceListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      branchId: branchId ?? this.branchId,
      assignedToId: assignedToId ?? this.assignedToId,
    );
  }

  @override
  List<Object?> get props => [
    page,
    limit,
    search,
    status,
    priority,
    type,
    branchId,
    assignedToId,
  ];
}

class SLAMetricsParams extends Equatable {
  final int? branchId;
  final DateTime? startDate;
  final DateTime? endDate;

  const SLAMetricsParams({this.branchId, this.startDate, this.endDate});

  @override
  List<Object?> get props => [branchId, startDate, endDate];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Data Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Paginated + filtered service request list.
final serviceListProvider =
    FutureProvider.family<List<ServiceRequestEntity>, ServiceListParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(serviceRepositoryProvider);
      final result = await repo.getServiceRequests(
        page: params.page,
        limit: params.limit,
        search: params.search,
        status: params.status,
        priority: params.priority,
        type: params.type,
        branchId: params.branchId,
        assignedToId: params.assignedToId,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (v) => v,
      );
    });

/// Single service request detail.
final serviceDetailProvider = FutureProvider.family<ServiceRequestEntity, int>((
  ref,
  id,
) async {
  final repo = ref.read(serviceRepositoryProvider);
  final result = await repo.getServiceRequestById(id);
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});

/// Tasks for a service request.
final serviceTasksProvider =
    FutureProvider.family<List<ServiceTaskEntity>, int>((
      ref,
      serviceRequestId,
    ) async {
      final repo = ref.read(serviceRepositoryProvider);
      final result = await repo.getServiceTasks(serviceRequestId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (v) => v,
      );
    });

/// Spare parts for a service request.
final serviceSparePartsProvider =
    FutureProvider.family<List<ServiceSparePartEntity>, int>((
      ref,
      serviceRequestId,
    ) async {
      final repo = ref.read(serviceRepositoryProvider);
      final result = await repo.getSpareParts(serviceRequestId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (v) => v,
      );
    });

/// SLA Metrics.
final slaMetricsProvider =
    FutureProvider.family<ServiceSLAMetrics, SLAMetricsParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(serviceRepositoryProvider);
      final result = await repo.getSLAMetrics(
        branchId: params.branchId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (v) => v,
      );
    });

/// My service requests.
final myServiceRequestsProvider = FutureProvider<List<ServiceRequestEntity>>((
  ref,
) async {
  final repo = ref.read(serviceRepositoryProvider);
  final result = await repo.getMyServiceRequests();
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});

// ═══════════════════════════════════════════════════════════════════════════
//  Form State Provider (Create / Edit / Actions)
// ═══════════════════════════════════════════════════════════════════════════

class ServiceFormState {
  final bool isLoading;
  final String? errorMessage;
  final ServiceRequestEntity? savedRequest;

  const ServiceFormState({
    this.isLoading = false,
    this.errorMessage,
    this.savedRequest,
  });

  ServiceFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    ServiceRequestEntity? savedRequest,
  }) {
    return ServiceFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      savedRequest: savedRequest,
    );
  }
}

class ServiceFormNotifier extends StateNotifier<ServiceFormState> {
  final ServiceRepository _repository;

  ServiceFormNotifier(this._repository) : super(const ServiceFormState());

  Future<bool> createServiceRequest(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createServiceRequest(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (request) {
        state = state.copyWith(isLoading: false, savedRequest: request);
        return true;
      },
    );
  }

  Future<bool> updateServiceRequest(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateServiceRequest(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (request) {
        state = state.copyWith(isLoading: false, savedRequest: request);
        return true;
      },
    );
  }

  Future<bool> approveServiceRequest(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.approveServiceRequest(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (request) {
        state = state.copyWith(isLoading: false, savedRequest: request);
        return true;
      },
    );
  }

  Future<bool> rejectServiceRequest(int id, String reason) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.rejectServiceRequest(id, reason);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (request) {
        state = state.copyWith(isLoading: false, savedRequest: request);
        return true;
      },
    );
  }

  Future<bool> completeServiceRequest(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.completeServiceRequest(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (request) {
        state = state.copyWith(isLoading: false, savedRequest: request);
        return true;
      },
    );
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createServiceTask(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateServiceTask(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> addSparePart(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.addSparePart(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  Future<bool> updateSparePart(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateSparePart(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  void reset() => state = const ServiceFormState();
}

final serviceFormProvider =
    StateNotifierProvider<ServiceFormNotifier, ServiceFormState>(
      (ref) => ServiceFormNotifier(ref.read(serviceRepositoryProvider)),
    );
