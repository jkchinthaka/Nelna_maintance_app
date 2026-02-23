import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';
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
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App Bar ─────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              toolbarHeight: 72,
              actions: [
                // Branch filter for admins
                if (isAdmin) _buildBranchSelector(context),
                Consumer(
                  builder: (context, ref, _) {
                    final unread =
                        ref.watch(notificationProvider).unreadCount;
                    return IconButton(
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      onPressed: () => NotificationPanel.show(context),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ── Content ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // KPIs Section
                  _buildKPIsSection(kpisAsync),
                  const SizedBox(height: 20),

                  // Monthly Trends Chart
                  _buildTrendsSection(trendsAsync),
                  const SizedBox(height: 20),

                  // Service Request Stats Chart
                  _buildStatsSection(statsAsync),
                  const SizedBox(height: 20),

                  // Recent Activity
                  _buildRecentActivitySection(kpisAsync),

                  // Bottom padding
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pull to Refresh ─────────────────────────────────────────────────

  Future<void> _onRefresh() async {
    ref.invalidate(dashboardKPIsProvider);
    ref.invalidate(monthlyTrendsProvider);
    ref.invalidate(serviceRequestStatsProvider);
    // Wait for the providers to re-fetch
    await Future.wait([
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

  // ── Branch Selector (Admin only) ────────────────────────────────────

  Widget _buildBranchSelector(BuildContext context) {
    final selectedBranch = ref.watch(selectedBranchIdProvider);

    return PopupMenuButton<int?>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
          const SizedBox(width: 4),
          Text(
            selectedBranch == null ? 'All' : 'Branch $selectedBranch',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onSelected: (value) {
        ref.read(selectedBranchIdProvider.notifier).set(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(value: null, child: Text('All Branches')),
        // In a real app, populate from a branches provider
        ...List.generate(5, (i) {
          final branchId = i + 1;
          return PopupMenuItem<int?>(
            value: branchId,
            child: Text('Branch $branchId'),
          );
        }),
      ],
    );
  }

  // ── KPIs Grid ───────────────────────────────────────────────────────

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
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 1.45,
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
              onTap: () {
                // Navigate to the relevant detail screen
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKPIsShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 1.45,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => const ShimmerLoading(height: 140),
        );
      },
    );
  }

  // ── Trends Chart ────────────────────────────────────────────────────

  Widget _buildTrendsSection(AsyncValue<MonthlyTrendsResponse> trendsAsync) {
    return trendsAsync.when(
      loading: () => const ShimmerLoading(height: 320),
      error: (error, _) => ErrorView(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(monthlyTrendsProvider),
      ),
      data: (response) => MonthlyTrendChart(trends: response.months),
    );
  }

  // ── Service Stats Chart ─────────────────────────────────────────────

  Widget _buildStatsSection(AsyncValue<ServiceRequestStats> statsAsync) {
    return statsAsync.when(
      loading: () => const ShimmerLoading(height: 300),
      error: (error, _) => ErrorView(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(serviceRequestStatsProvider),
      ),
      data: (stats) => ServiceStatsChart(stats: stats),
    );
  }

  // ── Recent Activity ─────────────────────────────────────────────────

  Widget _buildRecentActivitySection(AsyncValue<DashboardKPIs> kpisAsync) {
    // Build sample activity items based on KPI data for a realistic feed.
    // In production, this would be its own endpoint.
    final activities = <ActivityItem>[];

    kpisAsync.whenData((kpis) {
      if (kpis.openServiceRequests > 0) {
        activities.add(
          ActivityItem(
            title: 'Open Service Requests',
            subtitle: '${kpis.openServiceRequests} requests awaiting action',
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
            title: 'Low Stock Alert',
            subtitle: '${kpis.lowStockItems} items below reorder level',
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
            title: 'Assets Under Repair',
            subtitle:
                '${kpis.assetsUnderRepair} assets currently being repaired',
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
            title: 'Pending Purchase Orders',
            subtitle: '${kpis.pendingPOs} POs require attention',
            icon: Icons.receipt_long_outlined,
            color: AppColors.primaryLight,
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        );
      }

      activities.add(
        ActivityItem(
          title: 'System Status',
          subtitle:
              '${kpis.activeVehicles} vehicles and ${kpis.operationalMachines} machines operational',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          tag: 'OK',
        ),
      );
    });

    // Show a placeholder if we're still loading
    if (activities.isEmpty && kpisAsync.isLoading) {
      return const ShimmerLoading(height: 200);
    }

    return RecentActivityCard(
      activities: activities,
      onViewAll: () {
        // Navigate to full activity/audit log
      },
    );
  }
}

// ── Helper Model ──────────────────────────────────────────────────────

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final KpiTrend trend;
  final String? trendLabel;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = KpiTrend.neutral,
    this.trendLabel,
  });
}
