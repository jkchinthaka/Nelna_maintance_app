import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/service_provider.dart';
import '../widgets/task_list_widget.dart';
import '../widgets/spare_part_list_widget.dart';

/// Detailed view for a single service request with tabs for info,
/// tasks, spare parts, and timeline.
class ServiceDetailScreen extends ConsumerStatefulWidget {
  final int serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _tabs = ['Details', 'Tasks', 'Spare Parts', 'Timeline'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(serviceDetailProvider(widget.serviceId));

    return Scaffold(
      body: requestAsync.when(
        loading: () =>
            const LoadingOverlay(isLoading: true, child: SizedBox.expand()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(serviceDetailProvider(widget.serviceId)),
        ),
        data: (request) => _buildContent(request),
      ),
    );
  }

  Widget _buildContent(ServiceRequestEntity request) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // ── Hero Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _priorityColor(request.priority),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(background: _buildHero(request)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Request',
                onPressed: () =>
                    context.push('/services/create', extra: request),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(value, request),
                itemBuilder: (_) => [
                  if (request.status == 'Pending')
                    const PopupMenuItem(
                      value: 'approve',
                      child: ListTile(
                        leading: Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        title: Text('Approve'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (request.status == 'Pending')
                    const PopupMenuItem(
                      value: 'reject',
                      child: ListTile(
                        leading: Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
                        ),
                        title: Text('Reject'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (request.status == 'InProgress' ||
                      request.status == 'Approved')
                    const PopupMenuItem(
                      value: 'complete',
                      child: ListTile(
                        leading: Icon(
                          Icons.task_alt_outlined,
                          color: AppColors.success,
                        ),
                        title: Text('Complete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(request),
          TaskListWidget(
            serviceRequestId: request.id,
            tasks: request.tasks ?? [],
          ),
          SparePartListWidget(
            serviceRequestId: request.id,
            spareParts: request.spareParts ?? [],
          ),
          _buildTimelineTab(request),
        ],
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────

  Widget _buildHero(ServiceRequestEntity request) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _priorityColor(request.priority),
            _priorityColor(request.priority).withOpacity(0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              StatusBadge(status: request.status),
              const SizedBox(width: 8),
              _typeChip(request.type),
              const Spacer(),
              if (request.slaDeadline != null) _slaWidget(request),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.requestNo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(type, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _slaWidget(ServiceRequestEntity request) {
    final remaining = request.slaRemaining;
    final breached = request.isSLABreached;

    String label;
    if (remaining == null) {
      label = '--';
    } else if (breached) {
      label = 'SLA Breached';
    } else if (remaining.inDays > 0) {
      label = '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else {
      label = '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: breached
            ? AppColors.error.withOpacity(0.9)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            breached ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Details Tab ─────────────────────────────────────────────────────────

  Widget _buildDetailsTab(ServiceRequestEntity request) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final currFmt = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'Rs ',
      decimalDigits: 2,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Description Card ────────────────────────────────────────────
        _infoCard(
          title: 'Description',
          icon: Icons.description_outlined,
          child: Text(
            request.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),

        // ── Request Info ────────────────────────────────────────────────
        _infoCard(
          title: 'Request Information',
          icon: Icons.info_outline,
          child: Column(
            children: [
              _detailRow('Requested By', request.requestedByName ?? '–'),
              _detailRow('Assigned To', request.assignedToName ?? 'Unassigned'),
              _detailRow('Priority', request.priority),
              _detailRow('Type', request.type),
              _detailRow('Branch ID', request.branchId.toString()),
              _detailRow('Created', dateFmt.format(request.createdAt)),
              _detailRow('Updated', dateFmt.format(request.updatedAt)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Vehicle / Machine ───────────────────────────────────────────
        if (request.vehicleName != null || request.machineName != null)
          _infoCard(
            title: 'Asset',
            icon: Icons.precision_manufacturing_outlined,
            child: Column(
              children: [
                if (request.vehicleName != null)
                  _detailRow('Vehicle', request.vehicleName!),
                if (request.machineName != null)
                  _detailRow('Machine', request.machineName!),
              ],
            ),
          ),
        if (request.vehicleName != null || request.machineName != null)
          const SizedBox(height: 12),

        // ── Dates ───────────────────────────────────────────────────────
        _infoCard(
          title: 'Dates & Deadlines',
          icon: Icons.calendar_today_outlined,
          child: Column(
            children: [
              _detailRow(
                'Est. Completion',
                request.estimatedCompletionDate != null
                    ? dateFmt.format(request.estimatedCompletionDate!)
                    : '–',
              ),
              _detailRow(
                'Actual Completion',
                request.actualCompletionDate != null
                    ? dateFmt.format(request.actualCompletionDate!)
                    : '–',
              ),
              _detailRow(
                'SLA Deadline',
                request.slaDeadline != null
                    ? dateFmt.format(request.slaDeadline!)
                    : '–',
              ),
              if (request.approvedDate != null)
                _detailRow(
                  'Approved Date',
                  dateFmt.format(request.approvedDate!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Costs ───────────────────────────────────────────────────────
        _infoCard(
          title: 'Cost Overview',
          icon: Icons.attach_money,
          child: Column(
            children: [
              _detailRow(
                'Estimated Cost',
                request.estimatedCost != null
                    ? currFmt.format(request.estimatedCost)
                    : '–',
              ),
              _detailRow(
                'Actual Cost',
                request.actualCost != null
                    ? currFmt.format(request.actualCost)
                    : '–',
              ),
              _detailRow(
                'Spare Parts Cost',
                currFmt.format(request.totalSparePartsCost),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Rejection / Completion Notes ────────────────────────────────
        if (request.rejectionReason != null)
          _infoCard(
            title: 'Rejection Reason',
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            child: Text(
              request.rejectionReason!,
              style: const TextStyle(fontSize: 14, color: AppColors.error),
            ),
          ),
        if (request.completionNotes != null)
          _infoCard(
            title: 'Completion Notes',
            icon: Icons.note_outlined,
            child: Text(
              request.completionNotes!,
              style: const TextStyle(fontSize: 14),
            ),
          ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? color,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color ?? AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline Tab ────────────────────────────────────────────────────────

  Widget _buildTimelineTab(ServiceRequestEntity request) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final events = <_TimelineEvent>[
      _TimelineEvent(
        title: 'Request Created',
        subtitle: 'By ${request.requestedByName ?? 'Unknown'}',
        date: dateFmt.format(request.createdAt),
        icon: Icons.add_circle_outline,
        color: AppColors.info,
      ),
      if (request.approvedDate != null)
        _TimelineEvent(
          title: 'Request Approved',
          subtitle: 'Approved',
          date: dateFmt.format(request.approvedDate!),
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        ),
      if (request.rejectionReason != null)
        _TimelineEvent(
          title: 'Request Rejected',
          subtitle: request.rejectionReason!,
          date: dateFmt.format(request.updatedAt),
          icon: Icons.cancel_outlined,
          color: AppColors.error,
        ),
      if (request.status == 'InProgress')
        _TimelineEvent(
          title: 'Work In Progress',
          subtitle: request.assignedToName != null
              ? 'Assigned to ${request.assignedToName}'
              : 'In progress',
          date: dateFmt.format(request.updatedAt),
          icon: Icons.engineering_outlined,
          color: AppColors.warning,
        ),
      if (request.actualCompletionDate != null)
        _TimelineEvent(
          title: 'Request Completed',
          subtitle: request.completionNotes ?? 'Completed',
          date: dateFmt.format(request.actualCompletionDate!),
          icon: Icons.task_alt,
          color: AppColors.success,
        ),
    ];

    if (events.isEmpty) {
      return const Center(child: Text('No timeline events yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timeline indicator ────────────────────────────────────
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(event.icon, size: 16, color: event.color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: AppColors.border),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.date,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _handleAction(String action, ServiceRequestEntity request) {
    switch (action) {
      case 'approve':
        _showApproveDialog(request);
        break;
      case 'reject':
        _showRejectDialog(request);
        break;
      case 'complete':
        _showCompleteDialog(request);
        break;
    }
  }

  Future<void> _showApproveDialog(ServiceRequestEntity request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text('Approve service request ${request.requestNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(serviceFormProvider.notifier);
      final success = await notifier.approveServiceRequest(request.id, {});
      if (success && mounted) {
        ref.invalidate(serviceDetailProvider(widget.serviceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(ServiceRequestEntity request) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason…',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a rejection reason')),
        );
        return;
      }
      final notifier = ref.read(serviceFormProvider.notifier);
      final success = await notifier.rejectServiceRequest(request.id, reason);
      if (success && mounted) {
        ref.invalidate(serviceDetailProvider(widget.serviceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    reasonController.dispose();
  }

  Future<void> _showCompleteDialog(ServiceRequestEntity request) async {
    final notesController = TextEditingController();
    final costController = TextEditingController(
      text: request.actualCost?.toStringAsFixed(2) ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual Cost',
                border: OutlineInputBorder(),
                prefixText: 'Rs ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Completion Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final data = <String, dynamic>{
        'completionNotes': notesController.text.trim(),
        if (costController.text.isNotEmpty)
          'actualCost': double.tryParse(costController.text),
      };
      final notifier = ref.read(serviceFormProvider.notifier);
      final success = await notifier.completeServiceRequest(request.id, data);
      if (success && mounted) {
        ref.invalidate(serviceDetailProvider(widget.serviceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request completed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
    notesController.dispose();
    costController.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppColors.error;
      case 'High':
        return const Color(0xFFE67E22);
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Repair':
        return Icons.build;
      case 'Maintenance':
        return Icons.handyman;
      case 'Inspection':
        return Icons.search;
      case 'Emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.miscellaneous_services;
    }
  }
}

// ── Timeline Event DTO ────────────────────────────────────────────────────

class _TimelineEvent {
  final String title;
  final String subtitle;
  final String date;
  final IconData icon;
  final Color color;

  const _TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
  });
}
