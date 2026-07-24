import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

/// A small rounded chip that displays a complaint's [status] with a
/// consistent color and icon across the Complaint Management module
/// (list cards, details screen, timeline).
class ComplaintStatusChip extends StatelessWidget {
  final String status;
  final double fontSize;

  const ComplaintStatusChip({super.key, required this.status, this.fontSize = 11});

  Color get _color {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.statusPending;
      case AppConstants.statusInProgress:
        return AppColors.statusInProgress;
      case AppConstants.statusResolved:
        return AppColors.statusResolved;
      case AppConstants.statusEscalated:
        return AppColors.statusEscalated;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.hourglass_empty_rounded;
      case AppConstants.statusInProgress:
        return Icons.build_circle_outlined;
      case AppConstants.statusResolved:
        return Icons.check_circle_outline_rounded;
      case AppConstants.statusEscalated:
        return Icons.priority_high_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String get _label {
    switch (status) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusResolved:
        return 'Resolved';
      case AppConstants.statusEscalated:
        return 'Escalated';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: fontSize + 3, color: _color),
          const SizedBox(width: 4),
          Text(_label, style: AppStyles.caption(color: _color).copyWith(fontSize: fontSize, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A small rounded chip that displays a complaint's [priority].
class ComplaintPriorityChip extends StatelessWidget {
  final String priority;

  const ComplaintPriorityChip({super.key, required this.priority});

  Color get _color {
    switch (priority) {
      case AppConstants.priorityHigh:
        return AppColors.error;
      case AppConstants.priorityMedium:
        return AppColors.accent;
      case AppConstants.priorityLow:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(priority, style: AppStyles.caption(color: _color).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
