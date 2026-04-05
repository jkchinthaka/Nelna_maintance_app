import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final variant = theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.28),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.06,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const Spacer(),
                    if (trend != KpiTrend.neutral)
                      _TrendChip(trend: trend, label: trendLabel),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: variant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: variant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 240.ms).scale(begin: const Offset(0.98, 0.98));
  }
}

class _TrendChip extends StatelessWidget {
  final KpiTrend trend;
  final String? label;

  const _TrendChip({required this.trend, this.label});

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
        children: [
          Icon(trendIcon, size: 14, color: trendColor),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                color: trendColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}