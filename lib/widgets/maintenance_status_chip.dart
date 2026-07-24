import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

/// A small rounded chip that displays a maintenance record's
/// [status] with a consistent color and icon across the Maintenance
/// Management module (list cards, details screen).
class MaintenanceStatusChip extends StatelessWidget {
  final String status;
  final double fontSize;

  const MaintenanceStatusChip({super.key, required this.status, this.fontSize = 11});

  Color get _color {
    switch (status) {
      case AppConstants.maintenanceStatusPending:
        return AppColors.statusPending;
      case AppConstants.maintenanceStatusAssigned:
        return AppColors.info;
      case AppConstants.maintenanceStatusInProgress:
        return AppColors.statusInProgress;
      case AppConstants.maintenanceStatusCompleted:
        return AppColors.statusResolved;
      case AppConstants.maintenanceStatusCancelled:
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (status) {
      case AppConstants.maintenanceStatusPending:
        return Icons.hourglass_empty_rounded;
      case AppConstants.maintenanceStatusAssigned:
        return Icons.assignment_ind_outlined;
      case AppConstants.maintenanceStatusInProgress:
        return Icons.build_circle_outlined;
      case AppConstants.maintenanceStatusCompleted:
        return Icons.check_circle_outline_rounded;
      case AppConstants.maintenanceStatusCancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
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
          Text(status, style: AppStyles.caption(color: _color).copyWith(fontSize: fontSize, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A small rounded chip that displays a maintenance record's
/// [type] (Repair, Replacement, Inspection, etc.).
class MaintenanceTypeChip extends StatelessWidget {
  final String type;

  const MaintenanceTypeChip({super.key, required this.type});

  IconData get _icon {
    switch (type) {
      case AppConstants.maintenanceTypeRepair:
        return Icons.build_rounded;
      case AppConstants.maintenanceTypeReplacement:
        return Icons.autorenew_rounded;
      case AppConstants.maintenanceTypeInspection:
        return Icons.search_rounded;
      case AppConstants.maintenanceTypeCleaning:
        return Icons.cleaning_services_rounded;
      case AppConstants.maintenanceTypeSoftwareInstallation:
        return Icons.install_desktop_rounded;
      case AppConstants.maintenanceTypeHardwareUpgrade:
        return Icons.memory_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(type, style: AppStyles.caption(color: AppColors.primary).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}