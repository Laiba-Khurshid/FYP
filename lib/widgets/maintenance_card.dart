import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project/models/maintenance_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/widgets/maintenance_status_chip.dart';


/// [MaintenanceDetailsScreen].
class MaintenanceCard extends StatelessWidget {
  final MaintenanceModel record;
  final VoidCallback onTap;

  const MaintenanceCard({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, y').format(record.maintenanceDate);
    final costLabel = record.cost > 0 ? 'PKR ${record.cost.toStringAsFixed(0)}' : 'No cost recorded';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: const Icon(Icons.build_rounded, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.assetName,
                          style: AppStyles.heading4(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.labName} • ${record.technicianName}',
                          style: AppStyles.bodySmall(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  MaintenanceStatusChip(status: record.maintenanceStatus),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              if (record.remarks.isNotEmpty)
                Text(
                  record.remarks,
                  style: AppStyles.bodySmall(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  MaintenanceTypeChip(type: record.maintenanceType),
                  const Spacer(),
                  Icon(Icons.payments_outlined, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(costLabel, style: AppStyles.caption()),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Icon(Icons.event_outlined, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(dateLabel, style: AppStyles.caption()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}