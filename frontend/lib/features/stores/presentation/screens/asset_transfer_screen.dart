import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/asset_entity.dart';
import '../providers/asset_provider.dart';

/// Transfer list with status tabs (Pending / Approved / InTransit / Completed),
/// create transfer form, and approve/reject actions.
class AssetTransferScreen extends ConsumerStatefulWidget {
  const AssetTransferScreen({super.key});

  @override
  ConsumerState<AssetTransferScreen> createState() =>
      _AssetTransferScreenState();
}

class _AssetTransferScreenState extends ConsumerState<AssetTransferScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['All', 'Pending', 'Approved', 'InTransit', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? get _currentStatus {
    final index = _tabController.index;
    return index == 0 ? null : _tabs[index];
  }

  TransferListParams get _params => TransferListParams(status: _currentStatus);

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(transfersProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Transfers'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: transfersAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(transfersProvider(_params)),
        ),
        data: (transfers) {
          if (transfers.isEmpty) return _buildEmptyState();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(transfersProvider(_params)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transfers.length,
              itemBuilder: (context, index) =>
                  _TransferCard(transfer: transfers[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTransferSheet(context),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('New Transfer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Create Transfer Bottom Sheet ────────────────────────────────────────

  void _showCreateTransferSheet(BuildContext context) {
    final assetIdCtrl = TextEditingController();
    final fromBranchCtrl = TextEditingController();
    final toBranchCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    DateTime transferDate = DateTime.now();
    final dateFmt = DateFormat('dd MMM yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Create Transfer',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: assetIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Asset ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fromBranchCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'From Branch ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: AppColors.info),
                  ),
                  Expanded(
                    child: TextField(
                      controller: toBranchCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'To Branch ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: transferDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setSheetState(() => transferDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Transfer Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(dateFmt.format(transferDate)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final assetId = int.tryParse(assetIdCtrl.text);
                  final fromBranch = int.tryParse(fromBranchCtrl.text);
                  final toBranch = int.tryParse(toBranchCtrl.text);
                  if (assetId == null ||
                      fromBranch == null ||
                      toBranch == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                      ),
                    );
                    return;
                  }

                  final notifier = ref.read(assetFormProvider.notifier);
                  final success = await notifier.createTransfer({
                    'assetId': assetId,
                    'fromBranchId': fromBranch,
                    'toBranchId': toBranch,
                    'transferDate': transferDate.toIso8601String(),
                    if (reasonCtrl.text.isNotEmpty) 'reason': reasonCtrl.text,
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (success) {
                    ref.invalidate(transfersProvider(_params));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transfer created')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Create Transfer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Skeleton Loader ─────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
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

  // ── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Transfers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'No transfers found for the selected status.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Transfer Card
// ═══════════════════════════════════════════════════════════════════════════

class _TransferCard extends ConsumerWidget {
  final AssetTransferEntity transfer;

  const _TransferCard({required this.transfer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Asset name + Status ───────────────────────────
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
                    Icons.swap_horiz,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    transfer.assetName ?? 'Asset #${transfer.assetId}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusBadge(status: transfer.status),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Branch transfer info ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transfer.fromBranchName ??
                            'Branch ${transfer.fromBranchId}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.info,
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'To',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transfer.toBranchName ??
                            'Branch ${transfer.toBranchId}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Date + Reason ─────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(transfer.transferDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (transfer.reason != null && transfer.reason!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      transfer.reason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            // ── Approve / Reject buttons ──────────────────────────────
            if (transfer.canApprove) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleApproval(context, ref, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _handleApproval(context, ref, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleApproval(
    BuildContext context,
    WidgetRef ref,
    bool approved,
  ) async {
    final notifier = ref.read(assetFormProvider.notifier);
    final success = await notifier.approveTransfer(
      transfer.id,
      approved: approved,
    );
    if (success && context.mounted) {
      // Invalidate all transfer tabs to refresh
      ref.invalidate(transfersProvider(const TransferListParams()));
      ref.invalidate(
        transfersProvider(const TransferListParams(status: 'Pending')),
      );
      ref.invalidate(
        transfersProvider(const TransferListParams(status: 'Approved')),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? 'Transfer approved' : 'Transfer rejected'),
        ),
      );
    }
  }
}
