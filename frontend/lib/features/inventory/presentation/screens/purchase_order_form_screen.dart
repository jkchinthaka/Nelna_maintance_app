import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/inventory_entity.dart';
import '../providers/inventory_provider.dart';

/// Form screen for creating / editing a purchase order.
///
/// Features: supplier dropdown, dynamic line items, running totals.
class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  /// When editing an existing PO, pass the id here.
  final int? purchaseOrderId;

  const PurchaseOrderFormScreen({super.key, this.purchaseOrderId});

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState
    extends ConsumerState<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _expectedDate;
  bool _isInitialized = false;

  bool get isEditing => widget.purchaseOrderId != null;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(purchaseOrderFormProvider);
    final suppliersAsync = ref.watch(
      suppliersProvider(const SupplierListParams(limit: 100)),
    );
    final productsAsync = ref.watch(
      productListProvider(const ProductListParams(limit: 200)),
    );

    // Initialise form state when editing
    if (isEditing && !_isInitialized) {
      final orderAsync = ref.watch(
        purchaseOrderDetailProvider(widget.purchaseOrderId!),
      );
      orderAsync.whenData((order) {
        if (!_isInitialized) {
          _isInitialized = true;
          Future.microtask(() {
            ref.read(purchaseOrderFormProvider.notifier).loadOrder(order);
            _notesController.text = order.notes ?? '';
            setState(() => _expectedDate = order.expectedDeliveryDate);
          });
        }
      });
    }

    final suppliers = suppliersAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];
    final currFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Purchase Order' : 'New Purchase Order'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Error Banner ──────────────────────────────────────────
            if (formState.errorMessage != null) ...[
              MaterialBanner(
                backgroundColor: AppColors.error.withOpacity(0.08),
                content: Text(
                  formState.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        ref.read(purchaseOrderFormProvider.notifier).reset(),
                    child: const Text('DISMISS'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Supplier Dropdown ─────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: formState.supplierId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select supplier',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items: suppliers
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final supplier = suppliers.firstWhere(
                            (s) => s.id == val,
                          );
                          ref
                              .read(purchaseOrderFormProvider.notifier)
                              .setSupplier(val, supplier.name);
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Supplier is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Expected delivery date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _expectedDate ?? DateTime.now().add(
                                const Duration(days: 7),
                              ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _expectedDate = picked);
                          ref
                              .read(purchaseOrderFormProvider.notifier)
                              .setExpectedDeliveryDate(picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Expected Delivery Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _expectedDate != null
                              ? DateFormat('dd MMM yyyy')
                                    .format(_expectedDate!)
                              : 'Tap to select',
                          style: TextStyle(
                            color: _expectedDate != null
                                ? null
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      onChanged: (val) => ref
                          .read(purchaseOrderFormProvider.notifier)
                          .setNotes(val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Line Items ────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Line Items',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(purchaseOrderFormProvider.notifier)
                              .addLineItem(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (formState.lineItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No items yet. Tap "Add Item" to begin.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...formState.lineItems.asMap().entries.map(
                        (entry) => _LineItemRow(
                          key: ValueKey('line_${entry.key}'),
                          index: entry.key,
                          item: entry.value,
                          products: products,
                          onChanged: (updated) => ref
                              .read(purchaseOrderFormProvider.notifier)
                              .updateLineItem(entry.key, updated),
                          onRemove: () => ref
                              .read(purchaseOrderFormProvider.notifier)
                              .removeLineItem(entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Grand Total ───────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.primary.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currFmt.format(formState.grandTotal),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: formState.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final notifier = ref.read(
                              purchaseOrderFormProvider.notifier,
                            );
                            final success = isEditing
                                ? await notifier.updateOrder(
                                    widget.purchaseOrderId!,
                                  )
                                : await notifier.saveDraft();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Draft saved'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.of(context).pop(true);
                            }
                          },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: formState.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (formState.lineItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Add at least one line item',
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }
                            final notifier = ref.read(
                              purchaseOrderFormProvider.notifier,
                            );
                            final success =
                                await notifier.submitForApproval();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Submitted for approval'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.of(context).pop(true);
                            }
                          },
                    icon: formState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Submit'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Dynamic Line Item Row
// ═════════════════════════════════════════════════════════════════════════════

class _LineItemRow extends StatelessWidget {
  final int index;
  final POLineItem item;
  final List<ProductEntity> products;
  final ValueChanged<POLineItem> onChanged;
  final VoidCallback onRemove;

  const _LineItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.products,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Product + Remove
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: item.productId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Select product',
                    ),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} (${p.code})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final product = products.firstWhere(
                          (p) => p.id == val,
                        );
                        onChanged(
                          item.copyWith(
                            productId: val,
                            productName: product.name,
                            productCode: product.code,
                            unitPrice: product.unitPrice,
                          ),
                        );
                      }
                    },
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.error,
                  ),
                  tooltip: 'Remove',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Quantity + Unit Price + Total
            Row(
              children: [
                // Quantity
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.quantity > 0
                        ? item.quantity.toString()
                        : '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelText: 'Qty',
                    ),
                    onChanged: (val) {
                      final qty = int.tryParse(val) ?? 0;
                      onChanged(item.copyWith(quantity: qty));
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if ((int.tryParse(val) ?? 0) <= 0) return '> 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Unit Price
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.unitPrice > 0
                        ? item.unitPrice.toStringAsFixed(2)
                        : '',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelText: 'Unit Price',
                      prefixText: 'Rs ',
                    ),
                    onChanged: (val) {
                      final price = double.tryParse(val) ?? 0;
                      onChanged(item.copyWith(unitPrice: price));
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if ((double.tryParse(val) ?? 0) <= 0) return '> 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Line Total
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primary.withOpacity(0.06),
                    ),
                    child: Text(
                      currFmt.format(item.totalPrice),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
