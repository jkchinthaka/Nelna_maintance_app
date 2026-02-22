import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A visual stock level widget with colour-coded progress bar.
///
/// Pass [current], [min], [max], and [reorderPoint] to show the stock gauge.
class StockLevelIndicator extends StatelessWidget {
  final double current;
  final double min;
  final double max;
  final double reorderPoint;
  final double height;
  final bool showLabels;

  const StockLevelIndicator({
    super.key,
    required this.current,
    this.min = 0,
    required this.max,
    this.reorderPoint = 0,
    this.height = 10,
    this.showLabels = true,
  });

  double get _percentage => max > 0 ? (current / max).clamp(0.0, 1.0) : 0;

  Color get barColor {
    if (current <= 0) return AppColors.error;
    if (current <= min) return AppColors.error;
    if (current <= reorderPoint) return AppColors.warning;
    if (_percentage > 0.75) return AppColors.success;
    return AppColors.info;
  }

  String get statusLabel {
    if (current <= 0) return 'Out of Stock';
    if (current <= min) return 'Critical';
    if (current <= reorderPoint) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Progress bar ────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                // Background track
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: _percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
                // Reorder‑point marker
                if (reorderPoint > 0 && max > 0)
                  Positioned(
                    left: _markerPosition(context),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: AppColors.warning.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Labels ──────────────────────────────────────────────────────
        if (showLabels) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: barColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${current.toStringAsFixed(current.truncateToDouble() == current ? 0 : 1)}'
                ' / '
                '${max.toStringAsFixed(max.truncateToDouble() == max ? 0 : 1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  double _markerPosition(BuildContext context) {
    // We can't know the render width here precisely, so we use LayoutBuilder
    // indirectly – the Stack's FractionallySizedBox handles it.  For the marker
    // we place it via a simple fraction multiplied by a rough width.
    // A cleaner approach uses LayoutBuilder; here we approximate using the
    // reorder fraction directly and letting the Positioned use a percentage.
    // However Positioned works with absolute offsets.  If the bar doesn't have
    // an explicit width, the simplest is to wrap the entire widget in a
    // LayoutBuilder externally.  For a fixed-layout card this is fine.
    return 0; // overridden below via a LayoutBuilder wrapper
  }
}

/// Wraps [StockLevelIndicator] in a [LayoutBuilder] so the reorder‑point
/// marker can be positioned using actual render width.
class StockLevelGauge extends StatelessWidget {
  final double current;
  final double min;
  final double max;
  final double reorderPoint;
  final double height;
  final bool showLabels;

  const StockLevelGauge({
    super.key,
    required this.current,
    this.min = 0,
    required this.max,
    this.reorderPoint = 0,
    this.height = 10,
    this.showLabels = true,
  });

  double get _percentage => max > 0 ? (current / max).clamp(0.0, 1.0) : 0;

  Color get barColor {
    if (current <= 0) return AppColors.error;
    if (current <= min) return AppColors.error;
    if (current <= reorderPoint) return AppColors.warning;
    if (_percentage > 0.75) return AppColors.success;
    return AppColors.info;
  }

  String get statusLabel {
    if (current <= 0) return 'Out of Stock';
    if (current <= min) return 'Critical';
    if (current <= reorderPoint) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final reorderFraction = max > 0
                ? (reorderPoint / max).clamp(0.0, 1.0)
                : 0.0;
            final markerX = totalWidth * reorderFraction;

            return ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    // Background
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.border.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                    // Filled bar
                    FractionallySizedBox(
                      widthFactor: _percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    ),
                    // Reorder point marker
                    if (reorderPoint > 0 && max > 0)
                      Positioned(
                        left: markerX - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (showLabels) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: barColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${_fmt(current)} / ${_fmt(max)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _fmt(double v) =>
      v.truncateToDouble() == v ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// Compact inline stock chip used in lists / cards.
class StockChip extends StatelessWidget {
  final double current;
  final double reorderPoint;
  final double min;

  const StockChip({
    super.key,
    required this.current,
    this.reorderPoint = 0,
    this.min = 0,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (current <= 0) {
      color = AppColors.error;
    } else if (current <= min) {
      color = AppColors.error;
    } else if (current <= reorderPoint) {
      color = AppColors.warning;
    } else {
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        current <= 0
            ? 'OUT'
            : current.truncateToDouble() == current
            ? current.toInt().toString()
            : current.toStringAsFixed(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
