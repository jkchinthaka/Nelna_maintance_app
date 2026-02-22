import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/vehicle_entity.dart';

/// A professional, reusable card for displaying a vehicle in a list / grid.
class VehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0');

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
              // ── Row 1: Icon + Registration + Status Badge ────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: vehicle.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              vehicle.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.directions_car,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.directions_car,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.registrationNo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: vehicle.status),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Row 2: Key metrics ──────────────────────────────────
              Row(
                children: [
                  _metricChip(
                    Icons.speed,
                    '${fmt.format(vehicle.mileage)} km',
                    AppColors.info,
                  ),
                  const SizedBox(width: 16),
                  _metricChip(
                    Icons.local_gas_station,
                    vehicle.fuelType,
                    AppColors.secondary,
                  ),
                  const Spacer(),
                  if (vehicle.nextServiceDate != null) _nextService(context),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _nextService(BuildContext context) {
    final date = vehicle.nextServiceDate!;
    final isOverdue = date.isBefore(DateTime.now());
    final isSoon =
        !isOverdue &&
        date.isBefore(DateTime.now().add(const Duration(days: 14)));

    final color = isOverdue
        ? AppColors.error
        : isSoon
        ? AppColors.warning
        : AppColors.textSecondary;

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
          DateFormat('dd MMM').format(date),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
