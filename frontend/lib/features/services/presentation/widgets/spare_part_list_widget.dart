import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/service_provider.dart';

/// Widget displaying spare parts linked to a service request.
///
/// Features:
/// - Table-like layout (product, qty, price, total, status)
/// - Add spare part button (opens search dialog)
/// - Total cost summary
class SparePartListWidget extends ConsumerStatefulWidget {
  final int serviceRequestId;
  final List<ServiceSparePartEntity> spareParts;

  const SparePartListWidget({
    super.key,
    required this.serviceRequestId,
    required this.spareParts,
  });

  @override
  ConsumerState<SparePartListWidget> createState() =>
      _SparePartListWidgetState();
}

class _SparePartListWidgetState extends ConsumerState<SparePartListWidget> {
  late List<ServiceSparePartEntity> _parts;

  @override
  void initState() {
    super.initState();
    _parts = List.from(widget.spareParts);
  }

  @override
  void didUpdateWidget(covariant SparePartListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spareParts != widget.spareParts) {
      _parts = List.from(widget.spareParts);
    }
  }

  double get _totalCost =>
      _parts.fold(0.0, (sum, p) => sum + (p.totalPrice ?? 0));

  final _currFmt = NumberFormat.currency(
    locale: 'en_LK',
    symbol: 'Rs ',
    decimalDigits: 2,
  );

  Future<void> _showAddSparePartDialog() async {
    final productIdCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '1');
    final unitPriceCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Spare Part'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Product ID *',
                  hintText: 'Enter product ID or search',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitPriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Unit Price',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Rs ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final productId = int.tryParse(productIdCtrl.text);
      final quantity = int.tryParse(quantityCtrl.text);

      if (productId == null || quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product ID and valid quantity are required'),
          ),
        );
        return;
      }

      final data = <String, dynamic>{
        'serviceRequestId': widget.serviceRequestId,
        'productId': productId,
        'quantity': quantity,
        if (unitPriceCtrl.text.isNotEmpty)
          'unitPrice': double.tryParse(unitPriceCtrl.text),
      };

      final notifier = ref.read(serviceFormProvider.notifier);
      final success = await notifier.addSparePart(data);
      if (success && mounted) {
        ref.invalidate(serviceDetailProvider(widget.serviceRequestId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spare part added'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    productIdCtrl.dispose();
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Spare Parts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: ${_currFmt.format(_totalCost)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Parts List ──────────────────────────────────────────────────
        if (_parts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No spare parts added yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          // Table header
          Card(
            elevation: 0.3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Product',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Price',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: 70),
                    ],
                  ),
                ),

                // Data rows
                ..._parts.map((part) => _buildPartRow(part)),

                // Total row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      const Expanded(flex: 2, child: SizedBox()),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _currFmt.format(_totalCost),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 70),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // ── Add Spare Part Button ───────────────────────────────────────
        OutlinedButton.icon(
          onPressed: _showAddSparePartDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Spare Part'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPartRow(ServiceSparePartEntity part) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.productName ?? 'Product #${part.productId}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (part.productCode != null)
                  Text(
                    part.productCode!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${part.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              part.unitPrice != null ? _currFmt.format(part.unitPrice) : '–',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              part.totalPrice != null ? _currFmt.format(part.totalPrice) : '–',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 70,
            child: Align(
              alignment: Alignment.centerRight,
              child: StatusBadge(status: part.status, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
