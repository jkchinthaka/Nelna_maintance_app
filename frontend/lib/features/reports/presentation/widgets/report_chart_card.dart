import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A wrapper card that holds a chart (from fl_chart or any widget) with a
/// consistent title, optional subtitle, and optional trailing action.
class ReportChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final double chartHeight;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const ReportChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.chartHeight = 220,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),

            // ── Chart ─────────────────────────────────────────────────
            SizedBox(height: chartHeight, width: double.infinity, child: chart),
          ],
        ),
      ),
    );
  }
}
