import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Trend direction for the report KPI indicator.
enum ReportKpiTrend { up, down, neutral }

/// A KPI card tailored for the reports feature, showing a metric value with
/// an icon, optional trend indicator (up/down arrow), and a subtitle.
class ReportKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final ReportKpiTrend trend;
  final String? trendLabel;
  final String? subtitle;
  final VoidCallback? onTap;

  const ReportKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.trend = ReportKpiTrend.neutral,
    this.trendLabel,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;

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
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon + Title Row ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: cardColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Value ─────────────────────────────────────────────────
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null || trend != ReportKpiTrend.neutral) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (trend != ReportKpiTrend.neutral) ...[
                      Icon(
                        trend == ReportKpiTrend.up
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 18,
                        color: trend == ReportKpiTrend.up
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (trendLabel != null)
                      Text(
                        trendLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: trend == ReportKpiTrend.up
                              ? AppColors.success
                              : trend == ReportKpiTrend.down
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (subtitle != null) ...[
                      if (trendLabel != null) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
