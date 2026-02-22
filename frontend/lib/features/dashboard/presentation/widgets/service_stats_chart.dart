import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_entity.dart';

/// A donut/pie chart showing service request distribution by status.
class ServiceStatsChart extends StatefulWidget {
  final ServiceRequestStats stats;

  const ServiceStatsChart({super.key, required this.stats});

  @override
  State<ServiceStatsChart> createState() => _ServiceStatsChartState();
}

class _ServiceStatsChartState extends State<ServiceStatsChart> {
  int _touchedIndex = -1;

  // ── Status → Color mapping ──────────────────────────────────────────
  static const Map<String, Color> _statusColors = {
    'PENDING': AppColors.warning,
    'APPROVED': AppColors.info,
    'IN_PROGRESS': AppColors.primaryLight,
    'COMPLETED': AppColors.success,
    'CLOSED': Color(0xFF8E8E93),
    'REJECTED': AppColors.error,
    'CANCELLED': Color(0xFFBDBDBD),
  };

  Color _colorForStatus(String status) {
    return _statusColors[status.toUpperCase()] ?? AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final statusData = widget.stats.byStatus;
    final total = widget.stats.totalRequests;

    if (statusData.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('No service request data')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ────────────────────────────────────────────────
            Text(
              'Service Requests by Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total total requests',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // ── Chart + Legend Row ────────────────────────────────────
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Donut chart
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = response
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 44,
                            sections: _buildSections(statusData, total),
                          ),
                        ),
                        // Center text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: statusData
                          .map(
                            (s) => _LegendItem(
                              color: _colorForStatus(s.status),
                              label: _formatStatus(s.status),
                              count: s.count,
                              percentage: total > 0
                                  ? (s.count / total * 100).toStringAsFixed(1)
                                  : '0',
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<StatusCount> statusData,
    int total,
  ) {
    return statusData.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      final isTouched = idx == _touchedIndex;
      final radius = isTouched ? 28.0 : 22.0;
      final color = _colorForStatus(s.status);
      final pct = total > 0 ? s.count / total * 100 : 0.0;

      return PieChartSectionData(
        color: color,
        value: s.count.toDouble(),
        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}

// ── Legend Item ────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
