import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project/models/notification_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

/// A single notification row shown in the Notifications screen.
///
/// Shows an icon matching the notification [type], the title/message,
/// a relative timestamp, and an unread indicator dot. Tapping marks it
/// read (via [onTap], handled by the screen) and can deep-link to the
/// related complaint/maintenance record.
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotificationTile({super.key, required this.notification, required this.onTap, this.onDelete});

  IconData get _icon {
    switch (notification.type) {
      case AppConstants.notificationTypeComplaintSubmitted:
        return Icons.report_problem_rounded;
      case AppConstants.notificationTypeComplaintUpdated:
        return Icons.update_rounded;
      case AppConstants.notificationTypeComplaintResolved:
        return Icons.check_circle_rounded;
      case AppConstants.notificationTypeComplaintEscalated:
        return Icons.priority_high_rounded;
      case AppConstants.notificationTypeMaintenanceCreated:
        return Icons.build_rounded;
      case AppConstants.notificationTypeMaintenanceCompleted:
        return Icons.build_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case AppConstants.notificationTypeComplaintSubmitted:
        return AppColors.statusPending;
      case AppConstants.notificationTypeComplaintUpdated:
        return AppColors.info;
      case AppConstants.notificationTypeComplaintResolved:
        return AppColors.success;
      case AppConstants.notificationTypeComplaintEscalated:
        return AppColors.error;
      case AppConstants.notificationTypeMaintenanceCreated:
        return AppColors.secondary;
      case AppConstants.notificationTypeMaintenanceCompleted:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String get _relativeTime {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(notification.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? AppColors.card : AppColors.primary.withOpacity(0.04),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppStyles.bodyLarge().copyWith(
                              fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            height: 8,
                            width: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: AppStyles.bodySmall(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(_relativeTime, style: AppStyles.caption()),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}