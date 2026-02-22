import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/inventory_entity.dart';
import '../providers/inventory_provider.dart';

/// Purchase order list with status tabs (All, Draft, Submitted, Approved,
/// Ordered, Received, Cancelled).  Each PO is rendered as a card.
class PurchaseOrderScreen extends ConsumerStatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  ConsumerState<PurchaseOrderScreen> createState() =>
      _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _statusTabs = <String?>[
    null, // All
    'Draft',
    'Submitted',
    'Approved',
    'Ordered',
    'Received',
    'Cancelled',
  ];

  static const _tabLabels = [
    'All',
    'Draft',
    'Submitted',
    'Approved',
    'Ordered',
    'Received',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  PurchaseOrderListParams get _params => PurchaseOrderListParams(
    status: _statusTabs[_tabController.index],
  );

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(purchaseOrderListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(purchaseOrderListProvider(_params));
        },
        child: ordersAsync.when(
          loading: () => _buildLoadingSkeleton(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () =>
                ref.invalidate(purchaseOrderListProvider(_params)),
          ),
          data: (orders) {
            if (orders.isEmpty) return _buildEmptyState();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PurchaseOrderCard(
                    order: orders[index],
                    onTap: () => context.push(
                      '/inventory/purchase-orders/${orders[index].id}',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/purchase-orders/create'),
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 130,
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
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No purchase orders found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first purchase order.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/inventory/purchase-orders/create'),
            icon: const Icon(Icons.add),
            label: const Text('New PO'),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Purchase Order Card
// ═════════════════════════════════════════════════════════════════════════════

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrderEntity order;
  final VoidCallback? onTap;

  const _PurchaseOrderCard({required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

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
              // Row 1: Order No + Status badge
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.supplierName != null)
                          Text(
                            order.supplierName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),

              const Divider(height: 24),

              // Row 2: Details
              Row(
                children: [
                  _metricChip(
                    context,
                    Icons.shopping_cart_outlined,
                    '${order.items.length} items',
                  ),
                  const SizedBox(width: 16),
                  _metricChip(
                    context,
                    Icons.payments_outlined,
                    currFmt.format(order.totalAmount),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (order.expectedDeliveryDate != null)
                    Text(
                      'Expected: ${dateFmt.format(order.expectedDeliveryDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    dateFmt.format(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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

  Widget _metricChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
