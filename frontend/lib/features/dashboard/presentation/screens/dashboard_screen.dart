import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/service_stats_chart.dart';

/// Main dashboard screen showing KPIs, charts, and recent activity.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _currencyFormat = NumberFormat.compactCurrency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final kpisAsync = ref.watch(dashboardKPIsProvider);
    final trendsAsync = ref.watch(monthlyTrendsProvider);
    final statsAsync = ref.watch(serviceRequestStatsProvider);
    final authState = ref.watch(authStateProvider);

    final userName =
        authState is AuthAuthenticated ? authState.user.firstName : 'User';
    final isAdmin = authState is AuthAuthenticated &&
        (authState.user.roleName == 'super_admin' ||
            authState.user.roleName == 'admin');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    _buildHeroSection(context, userName, isAdmin, kpisAsync),
                    const SizedBox(height: 24),
                    _buildKPIsSection(kpisAsync),
                    const SizedBox(height: 24),
                    _buildAnalyticsSection(trendsAsync, statsAsync),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(kpisAsync),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    String userName,
    bool isAdmin,
    AsyncValue<DashboardKPIs> kpisAsync,
  ) {
    final theme = Theme.of(context);
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: _HeroOrb(size: 180, color: Colors.white.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: _HeroOrb(size: 220, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.14)),
                          ),
                          child: Text(
                            today,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome back, $userName',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Monitor work orders, inventory pressure, and equipment health from a single responsive workspace.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.88),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin) _buildBranchSelector(context),
                ],
              ),
              const SizedBox(height: 20),
              kpisAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (kpis) {
                  final quickStats = [
                    _HeroStat(
                        label: 'Open requests',
                        value: '${kpis.openServiceRequests}'),
                    _HeroStat(
                        label: 'Low stock', value: '${kpis.lowStockItems}'),
                    _HeroStat(
                        label: 'POs pending', value: '${kpis.pendingPOs}'),
                    _HeroStat(
                        label: 'Monthly expenses',
                        value: _currencyFormat.format(kpis.expensesThisMonth)),
                  ];

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: quickStats
                        .map((stat) => _HeroMetricChip(stat: stat))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(dashboardKPIsProvider);
    ref.invalidate(monthlyTrendsProvider);
    ref.invalidate(serviceRequestStatsProvider);

    await Future.wait<dynamic>([
      ref
          .read(dashboardKPIsProvider.future)
          .catchError((_) => const DashboardKPIs()),
      ref.read(monthlyTrendsProvider.future).catchError(
            (_) => const MonthlyTrendsResponse(
              year: 0,
              months: [],
              yearlyTotals: YearlyTotals(),
            ),
          ),
      ref
          .read(serviceRequestStatsProvider.future)
          .catchError((_) => const ServiceRequestStats()),
    ]);
  }

  Widget _buildBranchSelector(BuildContext context) {
    final selectedBranch = ref.watch(selectedBranchIdProvider);
    final theme = Theme.of(context);

    return PopupMenuButton<int?>(
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              selectedBranch == null
                  ? 'All branches'
                  : 'Branch $selectedBranch',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, color: Colors.white),
          ],
        ),
      ),
      onSelected: (value) {
        ref.read(selectedBranchIdProvider.notifier).set(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(value: null, child: Text('All branches')),
        ...List.generate(5, (index) {
          final branchId = index + 1;
          return PopupMenuItem<int?>(
            value: branchId,
            child: Text('Branch $branchId'),
          );
        }),
      ],
    );
  }

  Widget _buildKPIsSection(AsyncValue<DashboardKPIs> kpisAsync) {
    return kpisAsync.when(
      loading: () => _buildKPIsShimmer(),
      error: (error, _) => ErrorView(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(dashboardKPIsProvider),
      ),
      data: (kpis) => _buildKPIsGrid(kpis),
    );
  }

  Widget _buildKPIsGrid(DashboardKPIs kpis) {
    final items = [
      _KpiItem(
        title: 'Active Vehicles',
        value: '${kpis.activeVehicles}',
        icon: Icons.local_shipping_outlined,
        color: AppColors.primary,
      ),
      _KpiItem(
        title: 'Operational Machines',
        value: '${kpis.operationalMachines}',
        icon: Icons.precision_manufacturing_outlined,
        color: AppColors.secondary,
      ),
      _KpiItem(
        title: 'Open Requests',
        value: '${kpis.openServiceRequests}',
        icon: Icons.assignment_outlined,
        color: AppColors.warning,
        trend: kpis.openServiceRequests > 10 ? KpiTrend.up : KpiTrend.neutral,
        trendLabel: kpis.openServiceRequests > 10 ? 'High' : null,
      ),
      _KpiItem(
        title: 'Low Stock Items',
        value: '${kpis.lowStockItems}',
        icon: Icons.inventory_2_outlined,
        color: kpis.lowStockItems > 0 ? AppColors.error : AppColors.success,
        trend: kpis.lowStockItems > 0 ? KpiTrend.up : KpiTrend.neutral,
        trendLabel: kpis.lowStockItems > 0 ? 'Alert' : null,
      ),
      _KpiItem(
        title: 'Pending POs',
        value: '${kpis.pendingPOs}',
        icon: Icons.shopping_cart_outlined,
        color: AppColors.info,
      ),
      _KpiItem(
        title: 'Monthly Expenses',
        value: _currencyFormat.format(kpis.expensesThisMonth),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.accent,
      ),
      _KpiItem(
        title: 'Total Assets',
        value: '${kpis.totalAssets}',
        icon: Icons.category_outlined,
        color: AppColors.primaryLight,
      ),
      _KpiItem(
        title: 'Under Repair',
        value: '${kpis.assetsUnderRepair}',
        icon: Icons.build_outlined,
        color:
            kpis.assetsUnderRepair > 0 ? AppColors.warning : AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 800 ? 1.65 : 1.45,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return KpiCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              color: item.color,
              trend: item.trend,
              trendLabel: item.trendLabel,
            );
          },
        );
      },
    );
  }

  Widget _buildKPIsShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 800 ? 1.65 : 1.45,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => const ShimmerLoading(height: 140),
        );
      },
    );
  }

  Widget _buildAnalyticsSection(
    AsyncValue<MonthlyTrendsResponse> trendsAsync,
    AsyncValue<ServiceRequestStats> statsAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;

        final trendsCard = trendsAsync.when(
          loading: () => const ShimmerLoading(height: 320),
          error: (error, _) => ErrorView(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(monthlyTrendsProvider),
          ),
          data: (response) => MonthlyTrendChart(trends: response.months),
        );

        final statsCard = statsAsync.when(
          loading: () => const ShimmerLoading(height: 320),
          error: (error, _) => ErrorView(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(serviceRequestStatsProvider),
          ),
          data: (stats) => ServiceStatsChart(stats: stats),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: trendsCard),
              const SizedBox(width: 16),
              Expanded(child: statsCard),
            ],
          );
        }

        return Column(
          children: [
            trendsCard,
            const SizedBox(height: 16),
            statsCard,
          ],
        );
      },
    );
  }

  Widget _buildRecentActivitySection(AsyncValue<DashboardKPIs> kpisAsync) {
    final activities = <ActivityItem>[];

    kpisAsync.whenData((kpis) {
      if (kpis.openServiceRequests > 0) {
        activities.add(
          ActivityItem(
            title: 'Open service requests',
            subtitle: ' requests awaiting action',
            icon: Icons.assignment_late_outlined,
            color: AppColors.warning,
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            tag: 'PENDING',
          ),
        );
      }

      if (kpis.lowStockItems > 0) {
        activities.add(
          ActivityItem(
            title: 'Low stock alert',
            subtitle: ' items below reorder level',
            icon: Icons.warning_amber_outlined,
            color: AppColors.error,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            tag: 'ALERT',
          ),
        );
      }

      if (kpis.assetsUnderRepair > 0) {
        activities.add(
          ActivityItem(
            title: 'Assets under repair',
            subtitle: ' assets currently being repaired',
            icon: Icons.build_circle_outlined,
            color: AppColors.info,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            tag: 'REPAIR',
          ),
        );
      }

      if (kpis.pendingPOs > 0) {
        activities.add(
          ActivityItem(
            title: 'Pending purchase orders',
            subtitle: ' POs awaiting approval',
            icon: Icons.shopping_cart_checkout,
            color: AppColors.primary,
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            tag: 'APPROVAL',
          ),
        );
      }
    });

    if (activities.isEmpty) {
      activities.add(
        ActivityItem(
          title: 'System online',
          subtitle: 'All systems are operating normally',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          timestamp: DateTime.now(),
          tag: 'SYSTEM',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View all'),
              ),
            ],
          ),
        ),
        RecentActivityCard(
          activities: activities,
          onViewAll: () {},
        ),
      ],
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final KpiTrend trend;
  final String? trendLabel;

  _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = KpiTrend.neutral,
    this.trendLabel,
  });
}

class _HeroStat {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});
}

class _HeroMetricChip extends StatelessWidget {
  final _HeroStat stat;

  const _HeroMetricChip({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _HeroOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.02)],
        ),
      ),
    );
  }
}
