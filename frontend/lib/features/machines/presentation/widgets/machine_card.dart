import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/machine_entity.dart';

/// A professional, reusable card for displaying a machine in a list / grid.
class MachineCard extends StatelessWidget {
  final MachineEntity machine;
  final VoidCallback? onTap;

  const MachineCard({super.key, required this.machine, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numFmt = NumberFormat('#,##0');

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
              // ── Row 1: Icon + Name + Status Badge ───────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: machine.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              machine.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.precision_manufacturing,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.precision_manufacturing,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          machine.code,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: machine.status),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Row 2: Key metrics ──────────────────────────────────
              Row(
                children: [
                  _metricChip(
                    Icons.access_time,
                    '${numFmt.format(machine.operatingHours)} hrs',
                    AppColors.info,
                  ),
                  if (machine.location != null) ...[
                    const SizedBox(width: 16),
                    _metricChip(
                      Icons.location_on_outlined,
                      machine.location!,
                      AppColors.secondary,
                    ),
                  ],
                  const Spacer(),
                  if (machine.nextMaintenanceDate != null)
                    _nextMaintenance(context),
                ],
              ),

              // ── Row 3: Type ─────────────────────────────────────────
              const SizedBox(height: 8),
              Row(
                children: [
                  _metricChip(
                    Icons.category_outlined,
                    machine.type,
                    AppColors.textSecondary,
                  ),
                  if (machine.manufacturer != null) ...[
                    const SizedBox(width: 16),
                    Flexible(
                      child: _metricChip(
                        Icons.factory_outlined,
                        machine.manufacturer!,
                        AppColors.textSecondary,
                      ),
                    ),
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _nextMaintenance(BuildContext context) {
    final date = machine.nextMaintenanceDate!;
    final isOverdue = date.isBefore(DateTime.now());
    final isSoon =
        !isOverdue &&
        date.isBefore(DateTime.now().add(const Duration(days: 7)));

    final color = isOverdue
        ? AppColors.error
        : isSoon
        ? AppColors.warning
        : AppColors.textSecondary;

    final dateFmt = DateFormat('dd MMM');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? Icons.warning_amber_rounded : Icons.build_circle_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          dateFmt.format(date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
