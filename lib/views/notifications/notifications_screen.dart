import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/models/notification_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/notification_viewmodel.dart';

import 'package:project/widgets/notification_tile.dart';
/// The Notifications screen for AssetFlow.
///
/// Shared by every role: shows notifications addressed personally to
/// the signed-in user, merged with any broadcast to their role (e.g.
/// "New Complaint Filed" broadcasts to HOD). Tapping a notification
/// marks it read; "Mark all read" clears the unread badge in one tap.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<NotificationViewModel>().subscribe(uid: user.uid, role: user.role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Notifications', style: AppStyles.heading4()),
        actions: [
          if (viewModel.unreadCount > 0)
            TextButton(
              onPressed: viewModel.markAllAsRead,
              child: Text('Mark all read', style: AppStyles.label(color: AppColors.primary)),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(viewModel)),
    );
  }

  Widget _buildBody(NotificationViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.errorMessage != null && viewModel.notifications.isEmpty) {
      return _buildMessageState(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        message: viewModel.errorMessage!,
      );
    }

    if (viewModel.notifications.isEmpty) {
      return _buildMessageState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications yet',
        message: "You'll see updates about complaints and maintenance here.",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      itemCount: viewModel.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppConstants.paddingSmall),
      itemBuilder: (context, index) {
        final notification = viewModel.notifications[index];
        return NotificationTile(
          notification: notification,
          onTap: () => _handleTap(viewModel, notification),
          onDelete: () => viewModel.deleteNotification(notification.notificationId),
        );
      },
    );
  }

  void _handleTap(NotificationViewModel viewModel, NotificationModel notification) {
    viewModel.markAsRead(notification);
    // Deep-linking to the exact complaint/maintenance details screen
    // would require fetching that record by ID first (complaint vs.
    // maintenance can't be told apart from `type` alone in every case),
    // so for now this simply acknowledges the notification; the
    // relevant list screens remain one tap away from the dashboard.
  }

  Widget _buildMessageState({required IconData icon, required String title, required String message}) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge, vertical: AppConstants.paddingXLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.textHint),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(title, style: AppStyles.heading4(), textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(message, textAlign: TextAlign.center, style: AppStyles.bodyMedium(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}