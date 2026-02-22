import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_entity.dart';

/// A professional line chart showing monthly expense & service cost trends.
class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyTrend> trends;

  const MonthlyTrendChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('No trend data available')),
      );
    }

    final maxY = _calculateMaxY();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────
            Text(
              'Monthly Cost Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Expense vs Service costs over the year',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // ── Legend ──────────────────────────────────────────────
            Row(
              children: [
                _LegendDot(color: AppColors.primary, label: 'Expenses'),
                const SizedBox(width: 20),
                _LegendDot(color: AppColors.secondary, label: 'Service Costs'),
                const SizedBox(width: 20),
                _LegendDot(color: AppColors.accent, label: 'Total'),
              ],
            ),
            const SizedBox(height: 16),

            // ── Chart ──────────────────────────────────────────────
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.border.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              _formatAmount(value),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= trends.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              trends[idx].monthLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (trends.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorder: BorderSide(color: AppColors.border),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final labels = ['Expenses', 'Service', 'Total'];
                          final colors = [
                            AppColors.primary,
                            AppColors.secondary,
                            AppColors.accent,
                          ];
                          return LineTooltipItem(
                            '${labels[spot.barIndex]}: ${_formatAmount(spot.y)}',
                            TextStyle(
                              color: colors[spot.barIndex],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Expense line
                    _buildLine(
                      spots: trends
                          .asMap()
                          .entries
                          .map(
                            (e) =>
                                FlSpot(e.key.toDouble(), e.value.expenseAmount),
                          )
                          .toList(),
                      color: AppColors.primary,
                    ),
                    // Service cost line
                    _buildLine(
                      spots: trends
                          .asMap()
                          .entries
                          .map(
                            (e) =>
                                FlSpot(e.key.toDouble(), e.value.serviceCost),
                          )
                          .toList(),
                      color: AppColors.secondary,
                    ),
                    // Total line
                    _buildLine(
                      spots: trends
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(e.key.toDouble(), e.value.totalCosts),
                          )
                          .toList(),
                      color: AppColors.accent,
                      isDashed: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  double _calculateMaxY() {
    double max = 0;
    for (final t in trends) {
      if (t.totalCosts > max) max = t.totalCosts;
      if (t.expenseAmount > max) max = t.expenseAmount;
      if (t.serviceCost > max) max = t.serviceCost;
    }
    // Add 20% headroom and round up
    return max == 0 ? 100 : (max * 1.2).ceilToDouble();
  }

  LineChartBarData _buildLine({
    required List<FlSpot> spots,
    required Color color,
    bool isDashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      dashArray: isDashed ? [6, 4] : null,
      belowBarData: BarAreaData(
        show: !isDashed,
        color: color.withOpacity(0.08),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

// ── Legend Dot ─────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
