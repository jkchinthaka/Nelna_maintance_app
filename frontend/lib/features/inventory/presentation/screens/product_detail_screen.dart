import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/inventory_entity.dart';
import '../providers/inventory_provider.dart';
import '../widgets/stock_level_indicator.dart';

/// Displays full product details, a stock gauge, recent stock movements,
/// and an adjust‑stock dialog.
class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final movementsAsync = ref.watch(
      stockMovementsProvider(StockMovementParams(productId: productId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Adjust Stock',
            onPressed: () {
              final product = productAsync.valueOrNull;
              if (product != null) {
                _showAdjustStockDialog(context, ref, product);
              }
            },
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productDetailProvider(productId));
            ref.invalidate(
              stockMovementsProvider(
                StockMovementParams(productId: productId),
              ),
            );
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProductInfoCard(context, product),
              const SizedBox(height: 16),
              _buildStockGaugeCard(context, product),
              const SizedBox(height: 16),
              _buildStockMovementsSection(context, ref, movementsAsync),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Product Info Card
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildProductInfoCard(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);
    final currFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: product.imageUrl != null &&
                          product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!product.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),

            // Detail rows
            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              Text(
                product.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _infoRow(context, 'Category', product.categoryName ?? '—'),
            _infoRow(context, 'Branch', product.branchName ?? '—'),
            _infoRow(context, 'Unit', product.unit),
            _infoRow(context, 'Unit Price', currFmt.format(product.unitPrice)),
            _infoRow(context, 'Location', product.location ?? '—'),
            _infoRow(context, 'Barcode', product.barcode ?? '—'),
            _infoRow(
              context,
              'Created',
              DateFormat.yMMMd().format(product.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Stock Gauge Card
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStockGaugeCard(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Level',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StockLevelGauge(
              current: product.currentStock.toDouble(),
              min: product.minStockLevel.toDouble(),
              max: product.maxStockLevel > 0
                  ? product.maxStockLevel.toDouble()
                  : (product.reorderPoint * 3).toDouble(),
              reorderPoint: product.reorderPoint.toDouble(),
              height: 14,
            ),
            const SizedBox(height: 20),
            _stockMetricRow(
              context,
              'Current Stock',
              product.currentStock.toString(),
              product.unit,
            ),
            _stockMetricRow(
              context,
              'Min Stock Level',
              product.minStockLevel.toString(),
              product.unit,
            ),
            _stockMetricRow(
              context,
              'Max Stock Level',
              product.maxStockLevel.toString(),
              product.unit,
            ),
            _stockMetricRow(
              context,
              'Reorder Point',
              product.reorderPoint.toString(),
              product.unit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockMetricRow(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '$value $unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Stock Movements Section
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStockMovementsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<StockMovementEntity>> movementsAsync,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Recent Stock Movements',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        movementsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (movements) {
            if (movements.isEmpty) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No stock movements yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movements.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildMovementTile(context, movements[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMovementTile(
    BuildContext context,
    StockMovementEntity movement,
  ) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.success : AppColors.error;
    final icon = isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final sign = isIn ? '+' : '-';
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        '${movement.type} — $sign${movement.quantity}',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (movement.notes != null && movement.notes!.isNotEmpty)
            Text(
              movement.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            dateFmt.format(movement.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      isThreeLine: movement.notes != null && movement.notes!.isNotEmpty,
      dense: true,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  Adjust Stock Dialog
  // ═════════════════════════════════════════════════════════════════════════

  void _showAdjustStockDialog(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
  ) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    String adjustType = 'In';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Adjust Stock'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      product.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Current stock: ${product.currentStock} ${product.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Type selection
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'In', label: Text('Stock In')),
                        ButtonSegment(value: 'Out', label: Text('Stock Out')),
                        ButtonSegment(
                          value: 'Adjustment',
                          label: Text('Adjustment'),
                        ),
                      ],
                      selected: {adjustType},
                      onSelectionChanged: (val) {
                        setDialogState(() => adjustType = val.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        suffixText: product.unit,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                Consumer(
                  builder: (ctx, innerRef, _) {
                    final formState = innerRef.watch(productFormProvider);
                    return FilledButton(
                      onPressed: formState.isLoading
                          ? null
                          : () async {
                              final qty =
                                  int.tryParse(qtyController.text) ?? 0;
                              if (qty <= 0) return;

                              final notifier =
                                  innerRef.read(productFormProvider.notifier);
                              final success = await notifier.adjustStock({
                                'productId': product.id,
                                'type': adjustType,
                                'quantity': qty,
                                'notes': notesController.text.isNotEmpty
                                    ? notesController.text
                                    : null,
                              });

                              if (success && dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                                innerRef.invalidate(
                                  productDetailProvider(productId),
                                );
                                innerRef.invalidate(
                                  stockMovementsProvider(
                                    StockMovementParams(
                                      productId: productId,
                                    ),
                                  ),
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Stock adjusted successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }
                            },
                      child: formState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
