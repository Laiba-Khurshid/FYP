import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:project/models/complaint_model.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/widgets/complaint_status_chip.dart';

/// A single complaint's card in the Complaints list.
///
/// Shows the asset/lab identity, a short description preview, and the
/// status/priority chips. Tapping opens complaint details.
class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onTap;

  const ComplaintCard({super.key, required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, y').format(complaint.createdAt);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: const Icon(Icons.report_problem_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.assetCode != null && complaint.assetCode!.isNotEmpty
                              ? '${complaint.assetName} • ${complaint.assetCode}'
                              : complaint.assetName,
                          style: AppStyles.heading4(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                complaint.labName,
                                style: AppStyles.bodySmall(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ComplaintPriorityChip(priority: complaint.priority),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                complaint.description,
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  ComplaintStatusChip(status: complaint.status),
                  const Spacer(),
                  Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
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
