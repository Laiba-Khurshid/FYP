import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project/models/audit_log_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

/// A single row in the Audit History screen's list.
///
/// Shows who did what, in which module, and when — with a module-based
/// icon/color for quick visual scanning.
class AuditTile extends StatelessWidget {
  final AuditLogModel log;

  const AuditTile({super.key, required this.log});

  IconData get _icon {
    switch (log.module) {
      case AppConstants.auditModuleAsset:
        return Icons.inventory_2_rounded;
      case AppConstants.auditModuleComplaint:
        return Icons.report_problem_rounded;
      case AppConstants.auditModuleMaintenance:
        return Icons.build_rounded;
      case AppConstants.auditModuleProfile:
        return Icons.person_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color get _color {
    switch (log.module) {
      case AppConstants.auditModuleAsset:
        return AppColors.primary;
      case AppConstants.auditModuleComplaint:
        return AppColors.statusPending;
      case AppConstants.auditModuleMaintenance:
        return AppColors.statusInProgress;
      case AppConstants.auditModuleProfile:
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('MMM d, y • h:mm a').format(log.timestamp);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.action, style: AppStyles.bodyLarge().copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${log.userName} • ${log.module}',
                  style: AppStyles.bodySmall(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(timeLabel, style: AppStyles.caption()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}