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
//  Vehicle Report Screen – fleet analytics
// ═══════════════════════════════════════════════════════════════════════════

class VehicleReportScreen extends ConsumerWidget {
  const VehicleReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);
    final branch = ref.watch(reportBranchProvider);
    final reportAsync = ref.watch(
      vehicleReportProvider(
        ReportParams(
          startDate: range.start,
          endDate: range.end,
          branchId: branch,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Report'),
        actions: const [
          ExportButton(reportType: 'vehicle'),
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
                onPressed: () => ref.invalidate(vehicleReportProvider),
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
  final VehicleReportEntity report;
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
          onChanged: (r) =>
              ref.read(reportDateRangeProvider.notifier).state = r,
        ),
        const SizedBox(height: 20),

        // ── KPI Cards ─────────────────────────────────────────────────
        _buildKpiGrid(context),
        const SizedBox(height: 20),

        // ── Fuel Cost Trend (Line Chart) ──────────────────────────────
        if (report.fuelTrend.isNotEmpty)
          ReportChartCard(
            title: 'Fuel Cost Trends',
            subtitle: 'Monthly fuel expenditure',
            chartHeight: 240,
            chart: _buildFuelTrendChart(),
          ),
        const SizedBox(height: 16),

        // ── Vehicle-wise Cost Comparison (Bar Chart) ──────────────────
        if (report.vehicleCosts.isNotEmpty)
          ReportChartCard(
            title: 'Vehicle Cost Comparison',
            subtitle: 'Fuel vs maintenance per vehicle',
            chartHeight: report.vehicleCosts.length * 50.0 + 40,
            chart: _buildVehicleCostBarChart(),
          ),
        const SizedBox(height: 16),

        // ── Fuel Efficiency Card ──────────────────────────────────────
        _buildEfficiencyCard(context),
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
          title: 'Total Vehicles',
          value: _numFmt.format(report.totalVehicles),
          icon: Icons.directions_car_outlined,
          color: AppColors.primary,
        ),
        ReportKpiCard(
          title: 'Active Vehicles',
          value: _numFmt.format(report.activeVehicles),
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          subtitle: '${report.utilizationRate.toStringAsFixed(1)}% utilization',
        ),
        ReportKpiCard(
          title: 'Total Fuel Cost',
          value: _currFmt.format(report.totalFuelCost),
          icon: Icons.local_gas_station_outlined,
          color: AppColors.warning,
        ),
        ReportKpiCard(
          title: 'Maintenance Cost',
          value: _currFmt.format(report.totalMaintenanceCost),
          icon: Icons.build_outlined,
          color: AppColors.info,
        ),
      ],
    );
  }

  // ── Fuel Trend Line Chart ───────────────────────────────────────────
  Widget _buildFuelTrendChart() {
    final data = report.fuelTrend;
    final maxCost = data.fold<double>(0, (m, e) => e.cost > m ? e.cost : m);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxCost * 1.3,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((s) {
                final point = data[s.spotIndex];
                return LineTooltipItem(
                  '${point.month}\n${_currFmt.format(point.cost)}',
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
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                final compact = NumberFormat.compact().format(value);
                return Text(
                  compact,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                );
              },
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
              (i) => FlSpot(i.toDouble(), data[i].cost),
            ),
            isCurved: true,
            color: AppColors.warning,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.warning,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.warning.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vehicle Cost Horizontal Bar Chart ───────────────────────────────
  Widget _buildVehicleCostBarChart() {
    final vehicles = report.vehicleCosts;
    final maxCost = vehicles.fold<double>(
      0,
      (m, e) => e.totalCost > m ? e.totalCost : m,
    );

    return BarChart(
      BarChartData(
        maxY: maxCost * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final v = vehicles[groupIndex];
              final label = rodIndex == 0
                  ? 'Fuel: ${_currFmt.format(v.fuelCost)}'
                  : 'Maint: ${_currFmt.format(v.maintenanceCost)}';
              return BarTooltipItem(
                '${v.registrationNo}\n$label',
                const TextStyle(color: Colors.white, fontSize: 11),
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
                final idx = value.toInt();
                if (idx < 0 || idx >= vehicles.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    vehicles[idx].registrationNo.length > 8
                        ? '${vehicles[idx].registrationNo.substring(0, 8)}…'
                        : vehicles[idx].registrationNo,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(vehicles.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: vehicles[i].fuelCost,
                width: 12,
                color: AppColors.warning,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: vehicles[i].maintenanceCost,
                width: 12,
                color: AppColors.info,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Fuel Efficiency Card ────────────────────────────────────────────
  Widget _buildEfficiencyCard(BuildContext context) {
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
              'Fuel Efficiency',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.speed_outlined,
                  color: AppColors.secondary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.avgFuelEfficiency.toStringAsFixed(1)} km/l',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Average Fleet Fuel Efficiency',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _metricRow(
              context,
              'Total Fleet Cost',
              _currFmt.format(report.totalFleetCost),
            ),
            const SizedBox(height: 8),
            _metricRow(
              context,
              'Cost per Vehicle',
              report.totalVehicles > 0
                  ? _currFmt.format(
                      report.totalFleetCost / report.totalVehicles,
                    )
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
