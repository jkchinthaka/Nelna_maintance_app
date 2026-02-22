import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A reusable coloured chip that maps common status strings to colours.
class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final normalised = status.toUpperCase().replaceAll('_', ' ').trim();
    final colorPair = _colorForStatus(normalised);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorPair.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorPair.foreground.withOpacity(0.3)),
      ),
      child: Text(
        normalised,
        style: TextStyle(
          color: colorPair.foreground,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static _StatusColors _colorForStatus(String status) {
    switch (status) {
      // ── Active / Positive ──────────────────────────────────────────
      case 'ACTIVE':
      case 'COMPLETED':
      case 'APPROVED':
      case 'RESOLVED':
      case 'DELIVERED':
      case 'PAID':
        return _StatusColors(
          foreground: AppColors.success,
          background: AppColors.success.withOpacity(0.1),
        );

      // ── Pending / Warning ──────────────────────────────────────────
      case 'PENDING':
      case 'PENDING APPROVAL':
      case 'AWAITING':
      case 'SCHEDULED':
      case 'DRAFT':
      case 'PARTIALLY PAID':
        return _StatusColors(
          foreground: AppColors.warning,
          background: AppColors.warning.withOpacity(0.1),
        );

      // ── In Progress / Info ─────────────────────────────────────────
      case 'IN PROGRESS':
      case 'IN SERVICE':
      case 'PROCESSING':
      case 'IN TRANSIT':
      case 'OPEN':
        return _StatusColors(
          foreground: AppColors.info,
          background: AppColors.info.withOpacity(0.1),
        );

      // ── Inactive / Error ───────────────────────────────────────────
      case 'INACTIVE':
      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
      case 'OVERDUE':
      case 'EXPIRED':
      case 'BREAKDOWN':
        return _StatusColors(
          foreground: AppColors.error,
          background: AppColors.error.withOpacity(0.1),
        );

      // ── Default ────────────────────────────────────────────────────
      default:
        return _StatusColors(
          foreground: AppColors.textSecondary,
          background: AppColors.textSecondary.withOpacity(0.1),
        );
    }
  }
}

class _StatusColors {
  final Color foreground;
  final Color background;
  const _StatusColors({required this.foreground, required this.background});
}
