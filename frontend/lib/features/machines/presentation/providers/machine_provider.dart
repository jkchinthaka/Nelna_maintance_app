import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/machine_remote_datasource.dart';
import '../../data/repositories/machine_repository_impl.dart';
import '../../domain/entities/machine_entity.dart';
import '../../domain/repositories/machine_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Infrastructure Providers
// ═══════════════════════════════════════════════════════════════════════════

final machineRemoteDatasourceProvider = Provider<MachineRemoteDatasource>(
  (ref) => MachineRemoteDatasource(ApiClient()),
);

final machineRepositoryProvider = Provider<MachineRepository>(
  (ref) => MachineRepositoryImpl(ref.read(machineRemoteDatasourceProvider)),
);

// ═══════════════════════════════════════════════════════════════════════════
//  Filter / Param Classes
// ═══════════════════════════════════════════════════════════════════════════

class MachineListParams extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? type;
  final int? branchId;

  const MachineListParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.type,
    this.branchId,
  });

  MachineListParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? type,
    int? branchId,
  }) {
    return MachineListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      type: type ?? this.type,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  List<Object?> get props => [page, limit, search, status, type, branchId];
}

class BreakdownLogParams extends Equatable {
  final int machineId;
  final int page;
  final int limit;

  const BreakdownLogParams({
    required this.machineId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [machineId, page, limit];
}

class ServiceHistoryParams extends Equatable {
  final int machineId;
  final int page;
  final int limit;

  const ServiceHistoryParams({
    required this.machineId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [machineId, page, limit];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Data Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Paginated + filtered machine list.
final machineListProvider =
    FutureProvider.family<List<MachineEntity>, MachineListParams>((
  ref,
  params,
) async {
  final repo = ref.read(machineRepositoryProvider);
  final result = await repo.getMachines(
    page: params.page,
    limit: params.limit,
    search: params.search,
    status: params.status,
    type: params.type,
    branchId: params.branchId,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (machines) => machines,
  );
});

/// Single machine detail.
final machineDetailProvider = FutureProvider.family<MachineEntity, int>((
  ref,
  id,
) async {
  final repo = ref.read(machineRepositoryProvider);
  final result = await repo.getMachineById(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (machine) => machine,
  );
});

/// Maintenance schedules for a machine.
final maintenanceSchedulesProvider =
    FutureProvider.family<List<MaintenanceScheduleEntity>, int>((
  ref,
  machineId,
) async {
  final repo = ref.read(machineRepositoryProvider);
  final result = await repo.getMaintenanceSchedules(machineId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (schedules) => schedules,
  );
});

/// Breakdown logs for a machine.
final breakdownLogsProvider =
    FutureProvider.family<List<BreakdownLogEntity>, BreakdownLogParams>((
  ref,
  params,
) async {
  final repo = ref.read(machineRepositoryProvider);
  final result = await repo.getBreakdownLogs(
    params.machineId,
    page: params.page,
    limit: params.limit,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (logs) => logs,
  );
});

/// AMC contracts for a machine.
final amcContractsProvider =
    FutureProvider.family<List<AMCContractEntity>, int>((ref, machineId) async {
  final repo = ref.read(machineRepositoryProvider);
  final result = await repo.getAMCContracts(machineId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (contracts) => contracts,
  );
});

/// Service history for a machine.
final serviceHistoryProvider = FutureProvider.family<
    List<MachineServiceHistoryEntity>,
    ServiceHistoryParams>((ref, params) async {
  final repo = ref.read(machineRepositoryProvider);
  final result = await repo.getServiceHistory(
    params.machineId,
    page: params.page,
    limit: params.limit,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (history) => history,
  );
});

/// Upcoming maintenance across all machines.
final upcomingMaintenanceProvider =
    FutureProvider<List<MaintenanceScheduleEntity>>((ref) async {
  final repo = ref.read(machineRepositoryProvider);
  final result = await repo.getUpcomingMaintenance();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (schedules) => schedules,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
//  Form State Provider (Create / Edit)
// ═══════════════════════════════════════════════════════════════════════════

class MachineFormState {
  final bool isLoading;
  final String? errorMessage;
  final MachineEntity? savedMachine;

  const MachineFormState({
    this.isLoading = false,
    this.errorMessage,
    this.savedMachine,
  });

  MachineFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    MachineEntity? savedMachine,
  }) {
    return MachineFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      savedMachine: savedMachine,
    );
  }
}

class MachineFormNotifier extends Notifier<MachineFormState> {
  late final MachineRepository _repository;

  @override
  MachineFormState build() {
    _repository = ref.read(machineRepositoryProvider);
    return const MachineFormState();
  }

  Future<bool> createMachine(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createMachine(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (machine) {
        state = state.copyWith(isLoading: false, savedMachine: machine);
        return true;
      },
    );
  }

  Future<bool> updateMachine(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateMachine(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (machine) {
        state = state.copyWith(isLoading: false, savedMachine: machine);
        return true;
      },
    );
  }

  Future<bool> createBreakdownLog(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createBreakdownLog(data);
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

  Future<bool> createMaintenanceSchedule(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createMaintenanceSchedule(data);
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

  Future<bool> createAMCContract(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createAMCContract(data);
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

  void reset() => state = const MachineFormState();
}

final machineFormProvider =
    NotifierProvider<MachineFormNotifier, MachineFormState>(
  MachineFormNotifier.new,
);
