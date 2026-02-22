import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/report_provider.dart';
import '../widgets/date_range_selector.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Reports Home Screen – hub with cards for each report type
// ═══════════════════════════════════════════════════════════════════════════

class ReportsHomeScreen extends ConsumerWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(autoMaintenanceReportProvider);
          ref.invalidate(autoVehicleReportProvider);
          ref.invalidate(autoInventoryReportProvider);
          ref.invalidate(autoExpenseReportProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Date Range Picker ─────────────────────────────────────
            DateRangeSelector(
              initialRange: range,
              onChanged: (newRange) {
                ref.read(reportDateRangeProvider.notifier).set(newRange);
              },
            ),
            const SizedBox(height: 8),

            // ── Branch Selector ───────────────────────────────────────
            _BranchSelector(),
            const SizedBox(height: 20),

            // ── Report Cards ──────────────────────────────────────────
            _ReportTypeCard(
              title: 'Maintenance Report',
              subtitle: 'Service requests, resolution times & costs',
              icon: Icons.build_circle_outlined,
              color: AppColors.primary,
              kpiBuilder: () => _maintenanceKpis(ref),
              onTap: () => context.push('/reports/maintenance'),
            ),
            const SizedBox(height: 12),
            _ReportTypeCard(
              title: 'Vehicle Report',
              subtitle: 'Fleet costs, fuel trends & efficiency',
              icon: Icons.directions_car_outlined,
              color: AppColors.info,
              kpiBuilder: () => _vehicleKpis(ref),
              onTap: () => context.push('/reports/vehicle'),
            ),
            const SizedBox(height: 12),
            _ReportTypeCard(
              title: 'Inventory Report',
              subtitle: 'Stock levels, movements & valuations',
              icon: Icons.inventory_2_outlined,
              color: AppColors.secondary,
              kpiBuilder: () => _inventoryKpis(ref),
              onTap: () => context.push('/reports/inventory'),
            ),
            const SizedBox(height: 12),
            _ReportTypeCard(
              title: 'Expense Report',
              subtitle: 'Spending breakdown & monthly trends',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.warning,
              kpiBuilder: () => _expenseKpis(ref),
              onTap: () => context.push('/reports/expense'),
            ),
          ],
        ),
      ),
    );
  }

  // ── KPI builders ────────────────────────────────────────────────────
  Widget _maintenanceKpis(WidgetRef ref) {
    final async = ref.watch(autoMaintenanceReportProvider);
    return async.when(
      loading: () => const _KpiLoading(),
      error: (_, __) => const _KpiError(),
      data: (r) => Row(
        children: [
          _MiniKpi(label: 'Total', value: '${r.totalRequests}'),
          _MiniKpi(label: 'Completed', value: '${r.completedRequests}'),
          _MiniKpi(label: 'Cost', value: _currency(r.totalCost)),
        ],
      ),
    );
  }

  Widget _vehicleKpis(WidgetRef ref) {
    final async = ref.watch(autoVehicleReportProvider);
    return async.when(
      loading: () => const _KpiLoading(),
      error: (_, __) => const _KpiError(),
      data: (r) => Row(
        children: [
          _MiniKpi(label: 'Fleet', value: '${r.totalVehicles}'),
          _MiniKpi(label: 'Fuel Cost', value: _currency(r.totalFuelCost)),
          _MiniKpi(
            label: 'Maint Cost',
            value: _currency(r.totalMaintenanceCost),
          ),
        ],
      ),
    );
  }

  Widget _inventoryKpis(WidgetRef ref) {
    final async = ref.watch(autoInventoryReportProvider);
    return async.when(
      loading: () => const _KpiLoading(),
      error: (_, __) => const _KpiError(),
      data: (r) => Row(
        children: [
          _MiniKpi(label: 'Products', value: '${r.totalProducts}'),
          _MiniKpi(label: 'Low Stock', value: '${r.lowStockProducts}'),
          _MiniKpi(label: 'Value', value: _currency(r.totalInventoryValue)),
        ],
      ),
    );
  }

  Widget _expenseKpis(WidgetRef ref) {
    final async = ref.watch(autoExpenseReportProvider);
    return async.when(
      loading: () => const _KpiLoading(),
      error: (_, __) => const _KpiError(),
      data: (r) => Row(
        children: [
          _MiniKpi(label: 'Total', value: _currency(r.totalExpenses)),
          _MiniKpi(label: 'Categories', value: '${r.byCategory.length}'),
          _MiniKpi(label: 'Top', value: r.highestCategory),
        ],
      ),
    );
  }

  static String _currency(double v) {
    final fmt = NumberFormat.compactCurrency(symbol: 'Rs.', decimalDigits: 0);
    return fmt.format(v);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Branch Selector Dropdown
// ═══════════════════════════════════════════════════════════════════════════

class _BranchSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBranch = ref.watch(reportBranchProvider);

    // In production this would come from a branches provider.
    final branches = <int?, String>{
      null: 'All Branches',
      1: 'Head Office',
      2: 'Branch A',
      3: 'Branch B',
    };

    return DropdownButtonFormField<int?>(
      value: selectedBranch,
      decoration: InputDecoration(
        labelText: 'Branch',
        prefixIcon: const Icon(Icons.business_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: branches.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => ref.read(reportBranchProvider.notifier).set(v),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Report Type Card
// ═══════════════════════════════════════════════════════════════════════════

class _ReportTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() kpiBuilder;
  final VoidCallback onTap;

  const _ReportTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.kpiBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              kpiBuilder(),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Mini KPI Helpers
// ═══════════════════════════════════════════════════════════════════════════

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;

  const _MiniKpi({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _KpiLoading extends StatelessWidget {
  const _KpiLoading();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 30,
      child: Center(child: LinearProgressIndicator()),
    );
  }
}

class _KpiError extends StatelessWidget {
  const _KpiError();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: AppColors.error),
        SizedBox(width: 6),
        Text(
          'Failed to load',
          style: TextStyle(color: AppColors.error, fontSize: 12),
        ),
      ],
    );
  }
}
