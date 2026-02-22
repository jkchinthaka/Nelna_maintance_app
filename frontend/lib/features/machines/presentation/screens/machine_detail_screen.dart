import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/machine_entity.dart';
import '../providers/machine_provider.dart';
import '../widgets/maintenance_schedule_card.dart';

/// Detailed view for a single machine with tabbed sections:
/// Details · Maintenance Schedules · Breakdown Logs · AMC Contracts · Service History
class MachineDetailScreen extends ConsumerStatefulWidget {
  final int machineId;

  const MachineDetailScreen({super.key, required this.machineId});

  @override
  ConsumerState<MachineDetailScreen> createState() =>
      _MachineDetailScreenState();
}

class _MachineDetailScreenState extends ConsumerState<MachineDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Details', 'Schedules', 'Breakdowns', 'AMC', 'History'];

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
    final machineAsync = ref.watch(machineDetailProvider(widget.machineId));

    return Scaffold(
      body: machineAsync.when(
        loading: () =>
            const LoadingOverlay(isLoading: true, child: SizedBox.expand()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(machineDetailProvider(widget.machineId)),
        ),
        data: (machine) => _buildContent(machine),
      ),
    );
  }

  Widget _buildContent(MachineEntity machine) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // ── Hero / Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(background: _buildHero(machine)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Machine',
                onPressed: () =>
                    context.push('/machines/create', extra: machine),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(value, machine),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'breakdown',
                    child: ListTile(
                      leading: Icon(Icons.report_problem_outlined),
                      title: Text('Report Breakdown'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
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
          _buildDetailsTab(machine),
          _buildSchedulesTab(),
          _buildBreakdownsTab(),
          _buildAMCTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ── Hero Section ────────────────────────────────────────────────────────

  Widget _buildHero(MachineEntity machine) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
          child: Row(
            children: [
              // Machine icon / image
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: machine.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          machine.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.precision_manufacturing,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.precision_manufacturing,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      machine.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${machine.code} • ${machine.type}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: machine.status),
                        if (machine.location != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              machine.location!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Details Tab ─────────────────────────────────────────────────────────

  Widget _buildDetailsTab(MachineEntity machine) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final numFmt = NumberFormat('#,##0.##');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('General Information'),
        _detailTile('Name', machine.name),
        _detailTile('Code', machine.code),
        _detailTile('Type / Category', machine.type),
        if (machine.manufacturer != null)
          _detailTile('Manufacturer', machine.manufacturer!),
        if (machine.model != null) _detailTile('Model', machine.model!),
        if (machine.serialNumber != null)
          _detailTile('Serial Number', machine.serialNumber!),
        if (machine.location != null)
          _detailTile('Location', machine.location!),
        if (machine.branchName != null)
          _detailTile('Branch', machine.branchName!),
        if (machine.condition != null)
          _detailTile('Condition', machine.condition!),

        const SizedBox(height: 16),
        _sectionHeader('Operating Details'),
        _detailTile(
          'Operating Hours',
          '${numFmt.format(machine.operatingHours)} hrs',
        ),
        if (machine.purchaseDate != null)
          _detailTile('Purchase Date', dateFmt.format(machine.purchaseDate!)),
        if (machine.purchasePrice != null)
          _detailTile(
            'Purchase Price',
            'LKR ${numFmt.format(machine.purchasePrice!)}',
          ),
        if (machine.lastMaintenanceDate != null)
          _detailTile(
            'Last Maintenance',
            dateFmt.format(machine.lastMaintenanceDate!),
          ),
        if (machine.nextMaintenanceDate != null)
          _detailTile(
            'Next Maintenance',
            dateFmt.format(machine.nextMaintenanceDate!),
            valueColor: machine.isMaintenanceOverdue
                ? AppColors.error
                : machine.isMaintenanceSoon
                ? AppColors.warning
                : null,
          ),

        // Specifications
        if (machine.specifications != null &&
            machine.specifications!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionHeader('Specifications'),
          ...machine.specifications!.entries.map(
            (e) => _detailTile(e.key, e.value.toString()),
          ),
        ],

        // Notes
        if (machine.notes != null && machine.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionHeader('Notes'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                machine.notes!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Schedules Tab ───────────────────────────────────────────────────────

  Widget _buildSchedulesTab() {
    final schedulesAsync = ref.watch(
      maintenanceSchedulesProvider(widget.machineId),
    );

    return schedulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () =>
            ref.invalidate(maintenanceSchedulesProvider(widget.machineId)),
      ),
      data: (schedules) {
        if (schedules.isEmpty) {
          return _buildTabEmptyState(
            Icons.calendar_month_outlined,
            'No maintenance schedules',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MaintenanceScheduleCard(schedule: schedules[index]),
            );
          },
        );
      },
    );
  }

  // ── Breakdowns Tab ──────────────────────────────────────────────────────

  Widget _buildBreakdownsTab() {
    final logsAsync = ref.watch(
      breakdownLogsProvider(BreakdownLogParams(machineId: widget.machineId)),
    );

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(
          breakdownLogsProvider(
            BreakdownLogParams(machineId: widget.machineId),
          ),
        ),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return _buildTabEmptyState(
            Icons.warning_amber_outlined,
            'No breakdown logs',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            return _buildBreakdownCard(logs[index]);
          },
        );
      },
    );
  }

  Widget _buildBreakdownCard(BreakdownLogEntity log) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final severityColor = _severityColor(log.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: severityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    log.severity.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: log.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                log.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFmt.format(log.reportedDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (log.reportedBy != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.reportedBy!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (log.downtimeHours != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${log.downtimeHours} hrs',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (log.rootCause != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Root Cause: ${log.rootCause}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── AMC Contracts Tab ───────────────────────────────────────────────────

  Widget _buildAMCTab() {
    final amcAsync = ref.watch(amcContractsProvider(widget.machineId));

    return amcAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(amcContractsProvider(widget.machineId)),
      ),
      data: (contracts) {
        if (contracts.isEmpty) {
          return _buildTabEmptyState(
            Icons.description_outlined,
            'No AMC contracts',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            return _buildAMCCard(contracts[index]);
          },
        );
      },
    );
  }

  Widget _buildAMCCard(AMCContractEntity contract) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final numFmt = NumberFormat('#,##0.00');

    Color statusColor;
    String statusLabel;
    if (contract.isExpired) {
      statusColor = AppColors.error;
      statusLabel = 'Expired';
    } else if (contract.isExpiringSoon) {
      statusColor = AppColors.warning;
      statusLabel = '${contract.daysRemaining} days left';
    } else {
      statusColor = AppColors.success;
      statusLabel = '${contract.daysRemaining} days left';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contract.vendorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Contract No: ${contract.contractNo}',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _amcDetail('Start', dateFmt.format(contract.startDate)),
                const SizedBox(width: 24),
                _amcDetail('End', dateFmt.format(contract.endDate)),
                const SizedBox(width: 24),
                _amcDetail('Amount', 'LKR ${numFmt.format(contract.amount)}'),
              ],
            ),
            if (contract.contactPerson != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    contract.contactPerson!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (contract.contactPhone != null) ...[
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      contract.contactPhone!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (contract.coverageDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                contract.coverageDetails!,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amcDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── Service History Tab ─────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(
      serviceHistoryProvider(ServiceHistoryParams(machineId: widget.machineId)),
    );

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(
          serviceHistoryProvider(
            ServiceHistoryParams(machineId: widget.machineId),
          ),
        ),
      ),
      data: (history) {
        if (history.isEmpty) {
          return _buildTabEmptyState(
            Icons.history_outlined,
            'No service history',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            return _buildHistoryCard(history[index]);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(MachineServiceHistoryEntity entry) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final numFmt = NumberFormat('#,##0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.build_circle_outlined,
            color: AppColors.info,
            size: 22,
          ),
        ),
        title: Text(
          entry.serviceType,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  dateFmt.format(entry.serviceDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (entry.performedBy != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '• ${entry.performedBy}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: entry.cost != null
            ? Text(
                'LKR\n${numFmt.format(entry.cost!)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              )
            : null,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.error;
      case 'HIGH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  void _handleAction(String value, MachineEntity machine) {
    switch (value) {
      case 'breakdown':
        context.push('/machines/${machine.id}/breakdown');
        break;
      case 'delete':
        _showDeleteConfirmation(machine);
        break;
    }
  }

  void _showDeleteConfirmation(MachineEntity machine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Machine'),
        content: Text(
          'Are you sure you want to delete "${machine.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(machineRepositoryProvider);
              final result = await repo.deleteMachine(machine.id);
              result.fold(
                (failure) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Machine deleted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.pop();
                  }
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
