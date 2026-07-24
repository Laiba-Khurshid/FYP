import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/widgets/custom_button.dart';
/// A generic full-screen error state used whenever a critical failure
/// occurs (e.g. Firebase initialization failure, network unavailability,
/// unhandled route). Provides an optional retry action.
class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorScreen({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'An unexpected error occurred. Please try again.',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: AppColors.error),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppStyles.heading3(),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppConstants.paddingXLarge),
                  CustomButton(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                    width: 180,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
