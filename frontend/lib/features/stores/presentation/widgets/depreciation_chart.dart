import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/asset_entity.dart';

/// A visual depreciation comparison widget showing purchase price vs current
/// value as horizontal bars with a depreciation rate and years in service.
class DepreciationChart extends StatelessWidget {
  final AssetEntity asset;

  const DepreciationChart({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    final purchasePrice = asset.purchasePrice ?? 0;
    final currentValue = asset.currentValue ?? 0;
    final depreciation = purchasePrice - currentValue;
    final depPercent = purchasePrice > 0 ? (depreciation / purchasePrice) : 0.0;
    final valueFraction = purchasePrice > 0
        ? (currentValue / purchasePrice)
        : 1.0;
    final years = asset.yearsInService;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_down,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Depreciation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Purchase Price Bar ──────────────────────────────────────
            _BarRow(
              label: 'Purchase Price',
              value: currencyFmt.format(purchasePrice),
              fraction: 1.0,
              color: AppColors.primary,
            ),

            const SizedBox(height: 14),

            // ── Current Value Bar ───────────────────────────────────────
            _BarRow(
              label: 'Current Value',
              value: currencyFmt.format(currentValue),
              fraction: valueFraction.clamp(0.0, 1.0),
              color: AppColors.success,
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── Summary Metrics ─────────────────────────────────────────
            Row(
              children: [
                _SummaryTile(
                  icon: Icons.arrow_downward,
                  label: 'Depreciation',
                  value: currencyFmt.format(depreciation),
                  color: AppColors.error,
                ),
                const SizedBox(width: 16),
                _SummaryTile(
                  icon: Icons.percent,
                  label: 'Dep. Rate',
                  value: '${(depPercent * 100).toStringAsFixed(1)}%',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 16),
                _SummaryTile(
                  icon: Icons.calendar_today,
                  label: 'Years',
                  value: years.toStringAsFixed(1),
                  color: AppColors.info,
                ),
              ],
            ),

            if (asset.depreciationRate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Annual depreciation rate: ${asset.depreciationRate!.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Bar Row (horizontal bar with label / value)
// ═══════════════════════════════════════════════════════════════════════════

class _BarRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Color color;

  const _BarRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Summary Tile
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
