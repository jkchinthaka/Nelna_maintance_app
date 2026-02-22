import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/service_provider.dart';

/// Widget displaying a list of tasks for a service request.
///
/// Features:
/// - Progress bar showing completed / total
/// - Expandable task items
/// - Checkbox to toggle completion
/// - Assigned person, estimated / actual hours
/// - Add task button
class TaskListWidget extends ConsumerStatefulWidget {
  final int serviceRequestId;
  final List<ServiceTaskEntity> tasks;

  const TaskListWidget({
    super.key,
    required this.serviceRequestId,
    required this.tasks,
  });

  @override
  ConsumerState<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends ConsumerState<TaskListWidget> {
  late List<ServiceTaskEntity> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant TaskListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _tasks = List.from(widget.tasks);
    }
  }

  int get _completedCount =>
      _tasks.where((t) => t.status == 'Completed').length;

  double get _progress => _tasks.isEmpty ? 0 : _completedCount / _tasks.length;

  double get _totalEstimatedHours =>
      _tasks.fold(0.0, (sum, t) => sum + (t.estimatedHours ?? 0));

  double get _totalActualHours =>
      _tasks.fold(0.0, (sum, t) => sum + (t.actualHours ?? 0));

  Future<void> _toggleTask(ServiceTaskEntity task) async {
    final notifier = ref.read(serviceFormProvider.notifier);
    final newStatus = task.isCompleted ? 'Pending' : 'Completed';
    final data = <String, dynamic>{
      'status': newStatus,
      if (newStatus == 'Completed')
        'completedAt': DateTime.now().toIso8601String(),
    };

    final success = await notifier.updateTask(task.id, data);
    if (success && mounted) {
      ref.invalidate(serviceDetailProvider(widget.serviceRequestId));
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Estimated Hours',
                  border: OutlineInputBorder(),
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
      if (titleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task title is required')));
        return;
      }

      final data = <String, dynamic>{
        'serviceRequestId': widget.serviceRequestId,
        'title': titleCtrl.text.trim(),
        if (descCtrl.text.trim().isNotEmpty)
          'description': descCtrl.text.trim(),
        if (hoursCtrl.text.isNotEmpty)
          'estimatedHours': double.tryParse(hoursCtrl.text),
      };

      final notifier = ref.read(serviceFormProvider.notifier);
      final success = await notifier.createTask(data);
      if (success && mounted) {
        ref.invalidate(serviceDetailProvider(widget.serviceRequestId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    titleCtrl.dispose();
    descCtrl.dispose();
    hoursCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Progress Section ──────────────────────────────────────────
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.task_alt,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Task Progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_completedCount / ${_tasks.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _progress == 1.0 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Est: ${_totalEstimatedHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Actual: ${_totalActualHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Task Items ────────────────────────────────────────────────
        if (_tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.playlist_add_check_circle_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No tasks yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ..._tasks.asMap().entries.map((entry) {
            final task = entry.value;
            return _buildTaskItem(task);
          }),

        const SizedBox(height: 16),

        // ── Add Task Button ───────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: _showAddTaskDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
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

  Widget _buildTaskItem(ServiceTaskEntity task) {
    final isCompleted = task.isCompleted;

    return Card(
      elevation: 0.3,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: Checkbox(
          value: isCompleted,
          activeColor: AppColors.success,
          onChanged: (_) => _toggleTask(task),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        subtitle: task.assignedToName != null
            ? Text(
                task.assignedToName!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: _statusIcon(task.status),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  Text(
                    task.description!,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    _hourChip('Est.', task.estimatedHours, AppColors.info),
                    const SizedBox(width: 12),
                    _hourChip('Actual', task.actualHours, AppColors.secondary),
                  ],
                ),
                if (task.notes != null && task.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${task.notes}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hourChip(String label, double? hours, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ${hours?.toStringAsFixed(1) ?? '–'}h',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'Completed':
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        );
      case 'InProgress':
        return const Icon(Icons.autorenew, color: AppColors.warning, size: 20);
      default:
        return const Icon(
          Icons.radio_button_unchecked,
          color: AppColors.textSecondary,
          size: 20,
        );
    }
  }
}
