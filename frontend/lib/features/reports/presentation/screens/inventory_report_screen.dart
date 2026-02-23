import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_entity.dart';
import '../providers/report_provider.dart';
import '../widgets/export_button.dart';
import '../widgets/report_chart_card.dart';
import '../widgets/report_kpi_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Inventory Report Screen – stock & product analytics
// ═══════════════════════════════════════════════════════════════════════════

class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(reportBranchProvider);
    final reportAsync = ref.watch(inventoryReportProvider(branch));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        actions: const [
          ExportButton(reportType: 'inventory'),
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
                onPressed: () => ref.invalidate(inventoryReportProvider),
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

// ═══════════════════════════════════════════════════════════════════════════
//  Body
// ═══════════════════════════════════════════════════════════════════════════

class _Body extends StatelessWidget {
  final InventoryReportEntity report;
  final WidgetRef ref;

  const _Body({required this.report, required this.ref});

  static final _currFmt = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── KPI Cards ─────────────────────────────────────────────────
        _buildKpiRow(context),
        const SizedBox(height: 20),

        // ── Stock Value by Category (Pie Chart) ───────────────────────
        if (report.stockValueByCategory.isNotEmpty)
          ReportChartCard(
            title: 'Stock Value by Category',
            subtitle: 'Inventory value breakdown',
            chart: _buildCategoryPieChart(),
          ),
        const SizedBox(height: 16),

        // ── Top Moving Products (Bar Chart) ───────────────────────────
        if (report.topMovingProducts.isNotEmpty)
          ReportChartCard(
            title: 'Top Moving Products',
            subtitle: 'Most active inventory items',
            chartHeight: 240,
            chart: _buildTopMovingBarChart(),
          ),
        const SizedBox(height: 16),

        // ── Top Moving Products Table ─────────────────────────────────
        if (report.topMovingProducts.isNotEmpty) _buildTopMovingTable(context),
      ],
    );
  }

  // ── KPI Row ─────────────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        ReportKpiCard(
          title: 'Total Products',
          value: '${report.totalProducts}',
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
        ),
        ReportKpiCard(
          title: 'Low Stock',
          value: '${report.lowStockProducts}',
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          subtitle: '${report.lowStockPercentage.toStringAsFixed(1)}% of total',
        ),
        ReportKpiCard(
          title: 'Inventory Value',
          value: _currFmt.format(report.totalInventoryValue),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.info,
        ),
        ReportKpiCard(
          title: 'Low Stock %',
          value: '${report.lowStockPercentage.toStringAsFixed(1)}%',
          icon: Icons.pie_chart_outline,
          color: report.lowStockPercentage > 20
              ? AppColors.error
              : AppColors.success,
        ),
      ],
    );
  }

  // ── Category Pie Chart ──────────────────────────────────────────────
  Widget _buildCategoryPieChart() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
      AppColors.accent,
      const Color(0xFF8E44AD),
      const Color(0xFF1ABC9C),
    ];
    final entries = report.stockValueByCategory.entries.toList();
    final total = entries.fold<double>(0, (s, e) => s + e.value);

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
                  value: entries[i].value,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(entries.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
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
                    Expanded(
                      child: Text(
                        entries[i].key,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _currFmt.format(entries[i].value),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Top Moving Bar Chart ────────────────────────────────────────────
  Widget _buildTopMovingBarChart() {
    final data = report.topMovingProducts;
    final maxQty = data.fold<double>(
        0, (m, e) => e.totalQuantity > m ? e.totalQuantity.toDouble() : m);

    return BarChart(
      BarChartData(
        maxY: maxQty * 1.3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final product = data[group.x.toInt()];
              return BarTooltipItem(
                '${product.productName}\n${product.totalQuantity} units',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compact().format(value),
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final name = data[idx].productName;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    name.length > 8 ? '${name.substring(0, 8)}…' : name,
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
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].totalQuantity.toDouble(),
                color: AppColors.primary,
                width: 18,
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

  // ── Top Moving Products Table ───────────────────────────────────────
  Widget _buildTopMovingTable(BuildContext context) {
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
              'Top Moving Products',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // ── Table Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Movements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Quantity',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ── Rows ──────────────────────────────────────────────────
            ...report.topMovingProducts.map((product) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        product.productName,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product.totalMovements}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${product.totalQuantity}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
