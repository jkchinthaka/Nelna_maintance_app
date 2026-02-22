import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Trend direction for the KPI indicator arrow.
enum KpiTrend { up, down, neutral }

/// A professional KPI dashboard card displaying a metric title, value, icon,
/// colour, and optional trend indicator.
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final KpiTrend trend;
  final String? subtitle;
  final String? trendLabel;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.trend = KpiTrend.neutral,
    this.subtitle,
    this.trendLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row: icon + title ──────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Value ─────────────────────────────────────────────────
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              // ── Subtitle + Trend ──────────────────────────────────────
              if (subtitle != null || trendLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (trendLabel != null) ...[
                      _TrendIndicator(trend: trend, label: trendLabel!),
                      const SizedBox(width: 8),
                    ],
                    if (subtitle != null)
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trend Indicator ───────────────────────────────────────────────────
class _TrendIndicator extends StatelessWidget {
  final KpiTrend trend;
  final String label;

  const _TrendIndicator({required this.trend, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color trendColor;
    final IconData trendIcon;

    switch (trend) {
      case KpiTrend.up:
        trendColor = AppColors.success;
        trendIcon = Icons.trending_up;
        break;
      case KpiTrend.down:
        trendColor = AppColors.error;
        trendIcon = Icons.trending_down;
        break;
      case KpiTrend.neutral:
        trendColor = AppColors.textSecondary;
        trendIcon = Icons.trending_flat;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 14, color: trendColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: trendColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
