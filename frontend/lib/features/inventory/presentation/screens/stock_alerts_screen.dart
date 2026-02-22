import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../domain/entities/inventory_entity.dart';
import '../providers/inventory_provider.dart';

/// Displays all low‑stock alerts sorted by severity.
class StockAlertsScreen extends ConsumerWidget {
  const StockAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(stockAlertsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Alerts')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(stockAlertsProvider(null)),
        child: alertsAsync.when(
          loading: () => _buildLoadingSkeleton(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(stockAlertsProvider(null)),
          ),
          data: (alerts) {
            if (alerts.isEmpty) return _buildEmptyState();

            // Sort with most severe first
            final sorted = [...alerts]
              ..sort((a, b) => b.severity.compareTo(a.severity));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: sorted.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StockAlertCard(alert: sorted[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'All stock levels are healthy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No products are below their reorder point.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Stock Alert Card
// ═════════════════════════════════════════════════════════════════════════════

class _StockAlertCard extends StatelessWidget {
  final StockAlert alert;

  const _StockAlertCard({required this.alert});

  Color get _severityColor {
    final s = alert.severity;
    if (s >= 0.8) return AppColors.error;
    if (s >= 0.5) return const Color(0xFFE67E22);
    return AppColors.warning;
  }

  IconData get _severityIcon {
    final s = alert.severity;
    if (s >= 0.8) return Icons.error_outline;
    if (s >= 0.5) return Icons.warning_amber_rounded;
    return Icons.info_outline;
  }

  String get _severityLabel {
    final s = alert.severity;
    if (s >= 0.8) return 'CRITICAL';
    if (s >= 0.5) return 'WARNING';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Severity icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_severityIcon, color: color, size: 24),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _severityLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.productCode,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Metric row
                  Row(
                    children: [
                      _metric(context, 'Current', '${alert.currentStock}'),
                      const SizedBox(width: 16),
                      _metric(context, 'Min', '${alert.minStockLevel}'),
                      const SizedBox(width: 16),
                      _metric(context, 'Reorder', '${alert.reorderPoint}'),
                      const SizedBox(width: 16),
                      _metric(
                        context,
                        'Deficit',
                        '${alert.deficit}',
                        valueColor: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
