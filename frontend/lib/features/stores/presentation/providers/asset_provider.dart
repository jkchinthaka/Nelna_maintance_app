import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/asset_remote_datasource.dart';
import '../../data/repositories/asset_repository_impl.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/repositories/asset_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Infrastructure Providers
// ═══════════════════════════════════════════════════════════════════════════

final assetRemoteDatasourceProvider = Provider<AssetRemoteDatasource>(
  (ref) => AssetRemoteDatasource(ApiClient()),
);

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) => AssetRepositoryImpl(ref.read(assetRemoteDatasourceProvider)),
);

// ═══════════════════════════════════════════════════════════════════════════
//  Filter / Param Classes
// ═══════════════════════════════════════════════════════════════════════════

class AssetListParams extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? condition;
  final String? category;
  final int? branchId;

  const AssetListParams({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
    this.condition,
    this.category,
    this.branchId,
  });

  AssetListParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? condition,
    String? category,
    int? branchId,
  }) {
    return AssetListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  List<Object?> get props => [
        page,
        limit,
        search,
        status,
        condition,
        category,
        branchId,
      ];
}

class TransferListParams extends Equatable {
  final int page;
  final int limit;
  final String? status;

  const TransferListParams({
    this.page = 1,
    this.limit = 20,
    this.status,
  });

  TransferListParams copyWith({
    int? page,
    int? limit,
    String? status,
  }) {
    return TransferListParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [page, limit, status];
}

// ═══════════════════════════════════════════════════════════════════════════
//  Data Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Paginated + filtered asset list.
final assetListProvider =
    FutureProvider.family<List<AssetEntity>, AssetListParams>((
  ref,
  params,
) async {
  final repo = ref.read(assetRepositoryProvider);
  final result = await repo.getAssets(
    page: params.page,
    limit: params.limit,
    search: params.search,
    status: params.status,
    condition: params.condition,
    category: params.category,
    branchId: params.branchId,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (assets) => assets,
  );
});

/// Single asset detail.
final assetDetailProvider = FutureProvider.family<AssetEntity, int>((
  ref,
  id,
) async {
  final repo = ref.read(assetRepositoryProvider);
  final result = await repo.getAssetById(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (asset) => asset,
  );
});

/// Repair logs for a specific asset.
final repairLogsProvider =
    FutureProvider.family<List<AssetRepairLogEntity>, int>((
  ref,
  assetId,
) async {
  final repo = ref.read(assetRepositoryProvider);
  final result = await repo.getRepairLogs(assetId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (logs) => logs,
  );
});

/// Transfers list with optional status filter.
final transfersProvider =
    FutureProvider.family<List<AssetTransferEntity>, TransferListParams>((
  ref,
  params,
) async {
  final repo = ref.read(assetRepositoryProvider);
  final result = await repo.getTransfers(
    page: params.page,
    limit: params.limit,
    status: params.status,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (transfers) => transfers,
  );
});

/// Depreciation summary optionally by branch.
final depreciationSummaryProvider =
    FutureProvider.family<AssetDepreciationSummary, int?>((
  ref,
  branchId,
) async {
  final repo = ref.read(assetRepositoryProvider);
  final result = await repo.getDepreciationSummary(branchId: branchId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (summary) => summary,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
//  Form State Provider (Create / Edit Asset)
// ═══════════════════════════════════════════════════════════════════════════

class AssetFormState {
  final bool isLoading;
  final String? errorMessage;
  final AssetEntity? savedAsset;

  const AssetFormState({
    this.isLoading = false,
    this.errorMessage,
    this.savedAsset,
  });

  AssetFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    AssetEntity? savedAsset,
  }) {
    return AssetFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      savedAsset: savedAsset,
    );
  }
}

class AssetFormNotifier extends StateNotifier<AssetFormState> {
  final AssetRepository _repository;

  AssetFormNotifier(this._repository) : super(const AssetFormState());

  Future<bool> createAsset(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createAsset(data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (asset) {
        state = state.copyWith(isLoading: false, savedAsset: asset);
        return true;
      },
    );
  }

  Future<bool> updateAsset(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateAsset(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (asset) {
        state = state.copyWith(isLoading: false, savedAsset: asset);
        return true;
      },
    );
  }

  Future<bool> disposeAsset(int id, {String? reason}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.disposeAsset(id, reason: reason);
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

  Future<bool> createRepairLog(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createRepairLog(data);
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

  Future<bool> createTransfer(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createTransfer(data);
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

  Future<bool> approveTransfer(int id,
      {required bool approved, String? notes}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.approveTransfer(id,
        approved: approved, notes: notes);
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

  void reset() => state = const AssetFormState();
}

final assetFormProvider =
    StateNotifierProvider.autoDispose<AssetFormNotifier, AssetFormState>((ref) {
  return AssetFormNotifier(ref.read(assetRepositoryProvider));
});
