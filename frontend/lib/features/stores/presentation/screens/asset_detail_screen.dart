import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/asset_entity.dart';
import '../providers/asset_provider.dart';
import '../widgets/depreciation_chart.dart';

/// Asset detail screen showing full asset information, depreciation card,
/// and tabs for Details / Repair Logs / Transfers with action buttons.
class AssetDetailScreen extends ConsumerWidget {
  final int assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(assetDetailProvider(assetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
        actions: [
          assetAsync.whenOrNull(
                data: (asset) => PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleMenuAction(context, ref, asset, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Asset')),
                    const PopupMenuItem(
                        value: 'repair', child: Text('Report Repair')),
                    const PopupMenuItem(
                        value: 'transfer', child: Text('Transfer Asset')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'dispose',
                      child: Text('Dispose Asset',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: assetAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(assetDetailProvider(assetId)),
        ),
        data: (asset) => _AssetDetailBody(asset: asset),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    AssetEntity asset,
    String action,
  ) {
    switch (action) {
      case 'edit':
        context.push('/stores/assets/${asset.id}/edit');
        break;
      case 'repair':
        _showRepairDialog(context, ref, asset);
        break;
      case 'transfer':
        context.push('/stores/transfers/create?assetId=${asset.id}');
        break;
      case 'dispose':
        _showDisposeDialog(context, ref, asset);
        break;
    }
  }

  void _showRepairDialog(
      BuildContext context, WidgetRef ref, AssetEntity asset) {
    final descController = TextEditingController();
    String severity = 'Medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report Repair'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High', 'Critical']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => severity = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (descController.text.isEmpty) return;
                final notifier = ref.read(assetFormProvider.notifier);
                final success = await notifier.createRepairLog({
                  'assetId': asset.id,
                  'description': descController.text,
                  'severity': severity,
                  'reportedDate': DateTime.now().toIso8601String(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (success) {
                  ref.invalidate(repairLogsProvider(asset.id));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Repair reported')),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisposeDialog(
      BuildContext context, WidgetRef ref, AssetEntity asset) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispose Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. The asset will be marked as disposed.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final notifier = ref.read(assetFormProvider.notifier);
              final success = await notifier.disposeAsset(
                asset.id,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (success && context.mounted) {
                ref.invalidate(assetDetailProvider(assetId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Asset disposed')),
                );
              }
            },
            child: const Text('Dispose'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Body
// ═══════════════════════════════════════════════════════════════════════════

class _AssetDetailBody extends ConsumerWidget {
  final AssetEntity asset;

  const _AssetDetailBody({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final currencyFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Card ──────────────────────────────────────
                  _buildHeaderCard(context, dateFmt, currencyFmt),
                  const SizedBox(height: 16),

                  // ── Depreciation Chart ───────────────────────────────
                  if (asset.purchasePrice != null)
                    DepreciationChart(asset: asset),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              const TabBar(
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Repair Logs'),
                  Tab(text: 'Transfers'),
                ],
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _DetailsTab(asset: asset),
            _RepairLogsTab(assetId: asset.id),
            _TransfersTab(assetId: asset.id),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    DateFormat dateFmt,
    NumberFormat currencyFmt,
  ) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.inventory_2,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: asset.status),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _chipInfo(Icons.category, asset.category),
                _chipInfo(Icons.location_on_outlined,
                    asset.location ?? 'No location'),
                if (asset.branchName != null)
                  _chipInfo(Icons.business, asset.branchName!),
                if (asset.assignedToName != null)
                  _chipInfo(Icons.person_outline, asset.assignedToName!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Details Tab
// ═══════════════════════════════════════════════════════════════════════════

class _DetailsTab extends StatelessWidget {
  final AssetEntity asset;

  const _DetailsTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final currencyFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(context, 'General Information'),
        _detailRow('Category', asset.category),
        _detailRow('Condition', asset.condition),
        _detailRow('Serial Number', asset.serialNumber ?? '—'),
        _detailRow('Location', asset.location ?? '—'),
        _detailRow('Description', asset.description ?? '—'),

        const SizedBox(height: 20),
        _sectionTitle(context, 'Financial Information'),
        if (asset.purchaseDate != null)
          _detailRow('Purchase Date', dateFmt.format(asset.purchaseDate!)),
        if (asset.purchasePrice != null)
          _detailRow(
              'Purchase Price', currencyFmt.format(asset.purchasePrice)),
        if (asset.currentValue != null)
          _detailRow('Current Value', currencyFmt.format(asset.currentValue)),
        if (asset.depreciationRate != null)
          _detailRow(
              'Depreciation Rate', '${asset.depreciationRate}% per annum'),

        const SizedBox(height: 20),
        _sectionTitle(context, 'Warranty & Assignment'),
        if (asset.warrantyExpiry != null)
          _detailRow('Warranty Expiry', dateFmt.format(asset.warrantyExpiry!)),
        _detailRow('Assigned To', asset.assignedToName ?? '—'),
        _detailRow('Branch', asset.branchName ?? '—'),

        if (asset.notes != null && asset.notes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle(context, 'Notes'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(asset.notes!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Repair Logs Tab
// ═══════════════════════════════════════════════════════════════════════════

class _RepairLogsTab extends ConsumerWidget {
  final int assetId;

  const _RepairLogsTab({required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(repairLogsProvider(assetId));
    final dateFmt = DateFormat('dd MMM yyyy');
    final currencyFmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(repairLogsProvider(assetId)),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.build_circle_outlined,
            title: 'No Repair Logs',
            subtitle: 'No repairs have been reported for this asset.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: _severityColor(log.severity).withOpacity(0.1),
                  child: Icon(Icons.build,
                      color: _severityColor(log.severity), size: 20),
                ),
                title: Text(
                  log.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      StatusBadge(status: log.status),
                      const SizedBox(width: 8),
                      Text(dateFmt.format(log.reportedDate),
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      if (log.repairCost != null) ...[
                        const Spacer(),
                        Text(
                          currencyFmt.format(log.repairCost),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return AppColors.error;
      case 'High':
        return const Color(0xFFE67E22);
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Transfers Tab
// ═══════════════════════════════════════════════════════════════════════════

class _TransfersTab extends ConsumerWidget {
  final int assetId;

  const _TransfersTab({required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-use the transfers provider with no status filter
    final transfersAsync =
        ref.watch(transfersProvider(const TransferListParams()));
    final dateFmt = DateFormat('dd MMM yyyy');

    return transfersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () =>
            ref.invalidate(transfersProvider(const TransferListParams())),
      ),
      data: (transfers) {
        // Filter locally by assetId for this tab view
        final filtered =
            transfers.where((t) => t.assetId == assetId).toList();
        if (filtered.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.swap_horiz,
            title: 'No Transfers',
            subtitle: 'No transfers have been made for this asset.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final transfer = filtered[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppColors.info.withOpacity(0.1),
                  child: const Icon(Icons.swap_horiz,
                      color: AppColors.info, size: 20),
                ),
                title: Text(
                  '${transfer.fromBranchName ?? 'Branch ${transfer.fromBranchId}'}'
                  ' → '
                  '${transfer.toBranchName ?? 'Branch ${transfer.toBranchId}'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      StatusBadge(status: transfer.status),
                      const SizedBox(width: 8),
                      Text(dateFmt.format(transfer.transferDate),
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tab Bar Delegate
// ═══════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
