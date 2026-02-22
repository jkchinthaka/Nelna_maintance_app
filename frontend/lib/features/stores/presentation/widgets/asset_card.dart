import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/asset_entity.dart';

/// A professional, reusable card for displaying an asset in a list / grid.
class AssetCard extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback? onTap;

  const AssetCard({super.key, required this.asset, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Icon + Name/Code + Condition Badge ───────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _conditionColor(asset.condition).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: asset.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              asset.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                _categoryIcon(asset.category),
                                color: _conditionColor(asset.condition),
                              ),
                            ),
                          )
                        : Icon(
                            _categoryIcon(asset.category),
                            color: _conditionColor(asset.condition),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          asset.code,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ConditionBadge(condition: asset.condition),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Row 2: Key metrics ──────────────────────────────────
              Row(
                children: [
                  if (asset.currentValue != null) ...[
                    _metricChip(
                      Icons.monetization_on_outlined,
                      currencyFmt.format(asset.currentValue),
                      AppColors.success,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (asset.location != null)
                    Expanded(
                      child: _metricChip(
                        Icons.location_on_outlined,
                        asset.location!,
                        AppColors.info,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Row 3: Status + Category ────────────────────────────
              Row(
                children: [
                  StatusBadge(status: asset.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _metricChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('computer') || lower.contains('laptop')) {
      return Icons.computer;
    }
    if (lower.contains('furniture')) return Icons.chair;
    if (lower.contains('vehicle')) return Icons.directions_car;
    if (lower.contains('electronic')) return Icons.devices;
    if (lower.contains('tool')) return Icons.build;
    if (lower.contains('machinery') || lower.contains('machine')) {
      return Icons.precision_manufacturing;
    }
    return Icons.inventory_2_outlined;
  }

  static Color _conditionColor(String condition) {
    switch (condition) {
      case 'New':
        return AppColors.success;
      case 'Good':
        return AppColors.info;
      case 'Fair':
        return AppColors.warning;
      case 'Poor':
        return const Color(0xFFE67E22);
      case 'Damaged':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Condition Badge (colour-coded chip)
// ═══════════════════════════════════════════════════════════════════════════

class _ConditionBadge extends StatelessWidget {
  final String condition;

  const _ConditionBadge({required this.condition});

  @override
  Widget build(BuildContext context) {
    final color = AssetCard._conditionColor(condition);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
