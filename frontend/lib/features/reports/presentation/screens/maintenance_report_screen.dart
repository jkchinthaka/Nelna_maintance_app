import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';
import '../providers/report_provider.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/export_button.dart';
import '../widgets/report_chart_card.dart';
import '../widgets/report_kpi_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Maintenance Report Screen – detailed analytics
// ═══════════════════════════════════════════════════════════════════════════

class MaintenanceReportScreen extends ConsumerWidget {
  const MaintenanceReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);
    final branch = ref.watch(reportBranchProvider);
    final reportAsync = ref.watch(
      maintenanceReportProvider(
        ReportParams(
          startDate: range.start,
          endDate: range.end,
          branchId: branch,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Report'),
        actions: const [
          ExportButton(reportType: 'maintenance'),
          SizedBox(width: 8),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load report',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '$err',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(maintenanceReportProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (report) => _Body(report: report, ref: ref),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final MaintenanceReportEntity report;
  final WidgetRef ref;

  const _Body({required this.report, required this.ref});

  static final _currFmt = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  static final _numFmt = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(reportDateRangeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Date Range ────────────────────────────────────────────────
        DateRangeSelector(
          initialRange: range,
          onChanged: (r) => ref.read(reportDateRangeProvider.notifier).set(r),
        ),
        const SizedBox(height: 20),

        // ── KPI Cards ─────────────────────────────────────────────────
        _buildKpiGrid(context),
        const SizedBox(height: 20),

        // ── Type Distribution (Pie Chart) ─────────────────────────────
        if (report.byType.isNotEmpty)
          ReportChartCard(
            title: 'By Service Type',
            subtitle: 'Distribution of maintenance requests',
            chart: _buildPieChart(report.byType),
          ),
        const SizedBox(height: 16),

        // ── Priority Breakdown (Bar Chart) ────────────────────────────
        if (report.byPriority.isNotEmpty)
          ReportChartCard(
            title: 'Priority Breakdown',
            subtitle: 'Requests by priority level',
            chart: _buildPriorityBarChart(context),
          ),
        const SizedBox(height: 16),

        // ── Monthly Trend (Line Chart) ────────────────────────────────
        if (report.monthlyTrend.isNotEmpty)
          ReportChartCard(
            title: 'Monthly Trend',
            subtitle: 'Requests and costs over time',
            chartHeight: 260,
            chart: _buildLineChart(context),
          ),
        const SizedBox(height: 16),

        // ── Cost Summary Card ─────────────────────────────────────────
        _buildCostSummary(context),
      ],
    );
  }

  // ── KPI Grid ────────────────────────────────────────────────────────
  Widget _buildKpiGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        ReportKpiCard(
          title: 'Total Requests',
          value: _numFmt.format(report.totalRequests),
          icon: Icons.assignment_outlined,
          color: AppColors.primary,
        ),
        ReportKpiCard(
          title: 'Completed',
          value: _numFmt.format(report.completedRequests),
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          subtitle: '${report.completionRate.toStringAsFixed(1)}%',
          trend: report.completionRate > 80
              ? ReportKpiTrend.up
              : ReportKpiTrend.down,
        ),
        ReportKpiCard(
          title: 'Pending',
          value: _numFmt.format(report.pendingRequests),
          icon: Icons.pending_outlined,
          color: AppColors.warning,
        ),
        ReportKpiCard(
          title: 'Avg Resolution',
          value: '${report.avgResolutionTime.toStringAsFixed(1)}h',
          icon: Icons.timer_outlined,
          color: AppColors.info,
        ),
      ],
    );
  }

  // ── Pie Chart ───────────────────────────────────────────────────────
  Widget _buildPieChart(Map<String, int> data) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
      AppColors.accent,
    ];
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: List.generate(entries.length, (i) {
                final pct = total > 0 ? (entries[i].value / total) * 100 : 0.0;
                return PieChartSectionData(
                  value: entries[i].value.toDouble(),
                  color: colors[i % colors.length],
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: 50,
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(entries.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entries[i].key} (${entries[i].value})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Priority Bar Chart ──────────────────────────────────────────────
  Widget _buildPriorityBarChart(BuildContext context) {
    final entries = report.byPriority.entries.toList();
    final maxVal =
        entries.fold<int>(0, (m, e) => e.value > m ? e.value : m).toDouble();
    final colors = {
      'critical': AppColors.error,
      'high': const Color(0xFFE67E22),
      'medium': AppColors.warning,
      'low': AppColors.success,
    };

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${entries[groupIndex].key}: ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[value.toInt()].key,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          final key = entries[i].key.toLowerCase();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                width: 28,
                color: colors[key] ?? AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Monthly Trend Line Chart ────────────────────────────────────────
  Widget _buildLineChart(BuildContext context) {
    final data = report.monthlyTrend;
    final maxCount = data.fold<int>(0, (m, e) => e.count > m ? e.count : m);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxCount * 1.3).ceilToDouble(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((s) {
                final point = data[s.spotIndex];
                return LineTooltipItem(
                  '${point.month}\nCount: ${point.count}\nCost: ${_currFmt.format(point.cost)}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppColors.border, strokeWidth: 0.8),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[idx].month.length > 3
                        ? data[idx].month.substring(0, 3)
                        : data[idx].month,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].count.toDouble()),
            ),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cost Summary ────────────────────────────────────────────────────
  Widget _buildCostSummary(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _costRow(context, 'Total Maintenance Cost', report.totalCost),
            const Divider(height: 20),
            _costRow(
              context,
              'Avg Cost per Request',
              report.totalRequests > 0
                  ? report.totalCost / report.totalRequests
                  : 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _costRow(BuildContext context, String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          _currFmt.format(value),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
