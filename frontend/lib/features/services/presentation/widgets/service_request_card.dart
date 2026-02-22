import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/service_entity.dart';

/// A reusable card for displaying a service request in a list or grid.
///
/// Features:
/// - Priority-colored left border
/// - Request number, title
/// - Status badge, type icon
/// - SLA timer (red when breaching)
/// - Assigned technician indicator
class ServiceRequestCard extends StatelessWidget {
  final ServiceRequestEntity request;
  final VoidCallback? onTap;

  const ServiceRequestCard({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _priorityColor(request.priority),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Icon + Request# + Status ─────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _typeColor(request.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcon(request.type),
                      color: _typeColor(request.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.requestNo,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: request.status),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Row 2: Metrics (type, priority, SLA, assignee) ──────
              Row(
                children: [
                  // Type chip
                  _metricChip(
                    _typeIcon(request.type),
                    request.type,
                    _typeColor(request.type),
                  ),
                  const SizedBox(width: 12),
                  // Priority chip
                  _metricChip(
                    Icons.flag,
                    request.priority,
                    _priorityColor(request.priority),
                  ),
                  const Spacer(),
                  // SLA countdown
                  if (request.slaDeadline != null) _slaIndicator(),
                  // Assigned avatar
                  if (request.assignedToName != null) ...[
                    const SizedBox(width: 8),
                    _assigneeAvatar(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _slaIndicator() {
    final remaining = request.slaRemaining;
    final breached = request.isSLABreached;

    String label;
    if (remaining == null) {
      label = '--';
    } else if (breached) {
      label = 'Breached';
    } else if (remaining.inDays > 0) {
      label = '${remaining.inDays}d';
    } else if (remaining.inHours > 0) {
      label = '${remaining.inHours}h';
    } else {
      label = '${remaining.inMinutes}m';
    }

    final color = breached
        ? AppColors.error
        : (remaining != null && remaining.inHours < 4)
            ? AppColors.warning
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            breached ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assigneeAvatar() {
    final name = request.assignedToName ?? '';
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    return Tooltip(
      message: name,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
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

  Color _typeColor(String type) {
    switch (type) {
      case 'Repair':
        return AppColors.info;
      case 'Maintenance':
        return AppColors.secondary;
      case 'Inspection':
        return AppColors.primary;
      case 'Emergency':
        return AppColors.error;
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
