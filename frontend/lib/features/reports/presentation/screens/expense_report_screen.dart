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
//  Expense Report Screen – spending analytics
// ═══════════════════════════════════════════════════════════════════════════

class ExpenseReportScreen extends ConsumerWidget {
  const ExpenseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);
    final branch = ref.watch(reportBranchProvider);
    final category = ref.watch(reportExpenseCategoryProvider);

    final reportAsync = ref.watch(
      expenseReportProvider(
        ExpenseReportProviderParams(
          startDate: range.start,
          endDate: range.end,
          branchId: branch,
          category: category,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Report'),
        actions: const [
          ExportButton(reportType: 'expense'),
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
                onPressed: () => ref.invalidate(expenseReportProvider),
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
  final ExpenseReportEntity report;
  final WidgetRef ref;

  const _Body({required this.report, required this.ref});

  static final _currFmt = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  static final _dateFmt = DateFormat('dd MMM yyyy');

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
        _buildKpiRow(context),
        const SizedBox(height: 20),

        // ── Category Breakdown (Pie Chart) ────────────────────────────
        if (report.byCategory.isNotEmpty)
          ReportChartCard(
            title: 'Category Breakdown',
            subtitle: 'Expenses by category',
            chart: _buildCategoryPieChart(),
          ),
        const SizedBox(height: 16),

        // ── Monthly Trend (Line Chart) ────────────────────────────────
        if (report.monthlyTrend.isNotEmpty)
          ReportChartCard(
            title: 'Monthly Spending Trend',
            subtitle: 'Expenses over time',
            chartHeight: 240,
            chart: _buildMonthlyTrendChart(),
          ),
        const SizedBox(height: 16),

        // ── Top Expenses Table ────────────────────────────────────────
        if (report.topExpenses.isNotEmpty) _buildTopExpensesTable(context),
      ],
    );
  }

  // ── KPI Row ─────────────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        ReportKpiCard(
          title: 'Total Expenses',
          value: _currFmt.format(report.totalExpenses),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.error,
        ),
        ReportKpiCard(
          title: 'Categories',
          value: '${report.byCategory.length}',
          icon: Icons.category_outlined,
          color: AppColors.info,
        ),
        ReportKpiCard(
          title: 'Highest Category',
          value: report.highestCategory,
          icon: Icons.trending_up_rounded,
          color: AppColors.warning,
          subtitle: report.byCategory.isNotEmpty
              ? _currFmt.format(
                  report.byCategory.values.reduce((a, b) => a > b ? a : b),
                )
              : null,
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
    final entries = report.byCategory.entries.toList();
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

  // ── Monthly Trend Line Chart ────────────────────────────────────────
  Widget _buildMonthlyTrendChart() {
    final data = report.monthlyTrend;
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
            color: AppColors.error,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.error,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.error.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Expenses Table ──────────────────────────────────────────────
  Widget _buildTopExpensesTable(BuildContext context) {
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
              'Top Expenses',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
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
            ...report.topExpenses.map((expense) {
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
                        expense.description,
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
                          expense.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.info,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _dateFmt.format(expense.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _currFmt.format(expense.amount),
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
