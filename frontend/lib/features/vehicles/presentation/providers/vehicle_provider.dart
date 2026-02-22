import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/vehicle_remote_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/vehicle_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Infrastructure Providers
// ═══════════════════════════════════════════════════════════════════════════

final vehicleRemoteDatasourceProvider = Provider<VehicleRemoteDatasource>(
  (ref) => VehicleRemoteDatasource(ApiClient()),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepositoryImpl(ref.read(vehicleRemoteDatasourceProvider)),
);

// ═══════════════════════════════════════════════════════════════════════════
//  Filter / Param classes
// ═══════════════════════════════════════════════════════════════════════════

class VehicleListParams extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final int? branchId;

  const VehicleListParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.branchId,
  });

  VehicleListParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    int? branchId,
  }) {
    return VehicleListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  List<Object?> get props => [page, limit, search, status, branchId];
}

class CostAnalyticsParams extends Equatable {
  final int vehicleId;
  final DateTime? startDate;
  final DateTime? endDate;

  const CostAnalyticsParams({
    required this.vehicleId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [vehicleId, startDate, endDate];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Data Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Paginated + filtered vehicle list.
final vehicleListProvider =
    FutureProvider.family<List<VehicleEntity>, VehicleListParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(vehicleRepositoryProvider);
      final result = await repo.getVehicles(
        page: params.page,
        limit: params.limit,
        search: params.search,
        status: params.status,
        branchId: params.branchId,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (v) => v,
      );
    });

/// Single vehicle detail.
final vehicleDetailProvider = FutureProvider.family<VehicleEntity, int>((
  ref,
  id,
) async {
  final repo = ref.read(vehicleRepositoryProvider);
  final result = await repo.getVehicleById(id);
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});

/// Service reminders.
final serviceRemindersProvider = FutureProvider<List<ServiceReminder>>((
  ref,
) async {
  final repo = ref.read(vehicleRepositoryProvider);
  final result = await repo.getServiceReminders();
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});

/// Cost analytics.
final vehicleCostAnalyticsProvider =
    FutureProvider.family<VehicleCostAnalytics, CostAnalyticsParams>((
      ref,
      params,
    ) async {
      final repo = ref.read(vehicleRepositoryProvider);
      final result = await repo.getCostAnalytics(
        params.vehicleId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (v) => v,
      );
    });

/// Fuel logs for a vehicle.
final vehicleFuelLogsProvider = FutureProvider.family<List<FuelLogEntity>, int>(
  (ref, vehicleId) async {
    final repo = ref.read(vehicleRepositoryProvider);
    final result = await repo.getFuelLogs(vehicleId);
    return result.fold((failure) => throw Exception(failure.message), (v) => v);
  },
);

// ═══════════════════════════════════════════════════════════════════════════
//  Form State Provider (Create / Edit)
// ═══════════════════════════════════════════════════════════════════════════

class VehicleFormState {
  final bool isLoading;
  final String? errorMessage;
  final VehicleEntity? savedVehicle;

  const VehicleFormState({
    this.isLoading = false,
    this.errorMessage,
    this.savedVehicle,
  });

  VehicleFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    VehicleEntity? savedVehicle,
  }) {
    return VehicleFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      savedVehicle: savedVehicle,
    );
  }
}

class VehicleFormNotifier extends StateNotifier<VehicleFormState> {
  final VehicleRepository _repository;

  VehicleFormNotifier(this._repository) : super(const VehicleFormState());

  Future<bool> createVehicle(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createVehicle(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (vehicle) {
        state = state.copyWith(isLoading: false, savedVehicle: vehicle);
        return true;
      },
    );
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateVehicle(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (vehicle) {
        state = state.copyWith(isLoading: false, savedVehicle: vehicle);
        return true;
      },
    );
  }

  Future<bool> addFuelLog(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.addFuelLog(data);
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

  Future<bool> addDocument(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.addDocument(data);
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

  Future<bool> assignDriver(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.assignDriver(data);
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

  void reset() => state = const VehicleFormState();
}

final vehicleFormProvider =
    StateNotifierProvider<VehicleFormNotifier, VehicleFormState>(
      (ref) => VehicleFormNotifier(ref.read(vehicleRepositoryProvider)),
    );
