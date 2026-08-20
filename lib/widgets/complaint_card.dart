import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:project/models/complaint_model.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/widgets/complaint_status_chip.dart';


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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        side: BorderSide(color: const Color(0xFFEEEEEE), width: 1),
      ),
      elevation: 1,
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
                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: const Icon(Icons.report_problem_rounded, color: Color(0xFF1A237E), size: 22),
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
                          style: AppStyles.heading4().copyWith(
                            color: Colors.black,  // ✅ Black text
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 13, color: Color(0xFF666666)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                complaint.labName,
                                style: AppStyles.bodySmall().copyWith(
                                  color: const Color(0xFF666666),  // ✅ Dark gray
                                ),
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
                style: AppStyles.bodySmall().copyWith(
                  color: const Color(0xFF444444),  // ✅ Dark gray
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  ComplaintStatusChip(status: complaint.status),
                  const Spacer(),
                  Icon(Icons.calendar_today_rounded, size: 12, color: const Color(0xFF999999)),
                  const SizedBox(width: 4),
                  Text(
                    dateLabel,
                    style: AppStyles.caption().copyWith(
                      color: const Color(0xFF999999),  // ✅ Light gray
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}