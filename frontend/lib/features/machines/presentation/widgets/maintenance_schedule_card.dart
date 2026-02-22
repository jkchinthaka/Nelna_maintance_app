import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/machine_entity.dart';

/// Card displaying a maintenance schedule with type, frequency,
/// next due date (with colored urgency), assigned person, and active toggle.
class MaintenanceScheduleCard extends StatelessWidget {
  final MaintenanceScheduleEntity schedule;
  final ValueChanged<bool>? onToggleActive;

  const MaintenanceScheduleCard({
    super.key,
    required this.schedule,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final numFmt = NumberFormat('#,##0.00');

    Color dueColor;
    IconData dueIcon;
    if (schedule.isOverdue) {
      dueColor = AppColors.error;
      dueIcon = Icons.warning_amber_rounded;
    } else if (schedule.isDueSoon) {
      dueColor = AppColors.warning;
      dueIcon = Icons.schedule;
    } else {
      dueColor = AppColors.success;
      dueIcon = Icons.check_circle_outline;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Type badge + Active toggle ────────────────────
            Row(
              children: [
                _typeBadge(schedule.type),
                const SizedBox(width: 8),
                _frequencyChip(schedule.frequency),
                const Spacer(),
                Switch.adaptive(
                  value: schedule.isActive,
                  onChanged: onToggleActive,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Next Due ──────────────────────────────────────────────
            Row(
              children: [
                Icon(dueIcon, size: 18, color: dueColor),
                const SizedBox(width: 6),
                Text(
                  'Next Due: ${dateFmt.format(schedule.nextDue)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dueColor,
                  ),
                ),
              ],
            ),

            // ── Last Performed ────────────────────────────────────────
            if (schedule.lastPerformed != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Last: ${dateFmt.format(schedule.lastPerformed!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 20),

            // ── Bottom row: Assigned + Duration + Cost ────────────────
            Row(
              children: [
                if (schedule.assignedTo != null) ...[
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      schedule.assignedTo!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (schedule.estimatedDuration != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${schedule.estimatedDuration} min',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (schedule.estimatedCost != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LKR ${numFmt.format(schedule.estimatedCost!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),

            // ── Instructions preview ──────────────────────────────────
            if (schedule.instructions != null &&
                schedule.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                schedule.instructions!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String type) {
    Color bg;
    Color fg;
    switch (type.toUpperCase()) {
      case 'PREVENTIVE':
        bg = AppColors.success.withOpacity(0.1);
        fg = AppColors.success;
        break;
      case 'PREDICTIVE':
        bg = AppColors.info.withOpacity(0.1);
        fg = AppColors.info;
        break;
      case 'CORRECTIVE':
        bg = AppColors.warning.withOpacity(0.1);
        fg = AppColors.warning;
        break;
      default:
        bg = AppColors.textSecondary.withOpacity(0.1);
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _frequencyChip(String frequency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        frequency,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
