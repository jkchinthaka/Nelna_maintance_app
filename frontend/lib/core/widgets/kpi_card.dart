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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: color.withOpacity(0.05),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Header Row ─────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                  ],
                ),
                
                const Spacer(),

                // ── Value ─────────────────────────────────────────────────
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                // ── Subtitle + Trend ──────────────────────────────────────
                if (subtitle != null || trendLabel != null) ...[
                  const SizedBox(height: 10),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
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
        trendIcon = Icons.trending_up_rounded;
        break;
      case KpiTrend.down:
        trendColor = AppColors.error;
        trendIcon = Icons.trending_down_rounded;
        break;
      case KpiTrend.neutral:
        trendColor = AppColors.textSecondary;
        trendIcon = Icons.trending_flat_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(trendIcon, size: 14, color: trendColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: trendColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
