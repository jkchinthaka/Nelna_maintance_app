import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_kpis_usecase.dart';
import '../../domain/usecases/get_monthly_trends_usecase.dart';
import '../../domain/usecases/get_service_request_stats_usecase.dart';

// ── Infrastructure Providers ──────────────────────────────────────────

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (_) => DashboardRemoteDataSource(ApiClient()),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(
    remoteDataSource: ref.read(dashboardRemoteDataSourceProvider),
  ),
);

// ── Use-case Providers ────────────────────────────────────────────────

final getDashboardKPIsUseCaseProvider = Provider<GetDashboardKPIsUseCase>(
  (ref) => GetDashboardKPIsUseCase(ref.read(dashboardRepositoryProvider)),
);

final getMonthlyTrendsUseCaseProvider = Provider<GetMonthlyTrendsUseCase>(
  (ref) => GetMonthlyTrendsUseCase(ref.read(dashboardRepositoryProvider)),
);

final getServiceRequestStatsUseCaseProvider =
    Provider<GetServiceRequestStatsUseCase>(
      (ref) =>
          GetServiceRequestStatsUseCase(ref.read(dashboardRepositoryProvider)),
    );

// ── Selected Branch (for admin filtering) ─────────────────────────────

/// The currently selected branch ID for dashboard filtering.
/// `null` means all branches (admin view).
final selectedBranchIdProvider = StateProvider<int?>((ref) => null);

// ── Data Providers ────────────────────────────────────────────────────

/// Fetches dashboard KPIs. Automatically refreshes when the selected
/// branch changes.
final dashboardKPIsProvider = FutureProvider.autoDispose<DashboardKPIs>((
  ref,
) async {
  final branchId = ref.watch(selectedBranchIdProvider);
  final useCase = ref.read(getDashboardKPIsUseCaseProvider);

  final result = await useCase(branchId: branchId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (kpis) => kpis,
  );
});

/// Fetches monthly trend data for the selected branch/year.
final monthlyTrendsProvider = FutureProvider.autoDispose<MonthlyTrendsResponse>(
  (ref) async {
    final branchId = ref.watch(selectedBranchIdProvider);
    final useCase = ref.read(getMonthlyTrendsUseCaseProvider);

    final result = await useCase(branchId: branchId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (trends) => trends,
    );
  },
);

/// Fetches service request statistics for the selected branch.
final serviceRequestStatsProvider =
    FutureProvider.autoDispose<ServiceRequestStats>((ref) async {
      final branchId = ref.watch(selectedBranchIdProvider);
      final useCase = ref.read(getServiceRequestStatsUseCaseProvider);

      final result = await useCase(branchId: branchId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (stats) => stats,
      );
    });
