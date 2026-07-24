import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
/// A reusable loading indicator with an optional message.
///
/// Used across the app whenever data is being fetched from Firestore,
/// an operation is in progress, or a screen is awaiting async state.
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color color;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 42,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A thin, inline loading indicator suitable for buttons or small spaces.
class InlineLoadingWidget extends StatelessWidget {
  final Color color;
  final double size;

  const InlineLoadingWidget({
    super.key,
    this.color = AppColors.primary,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// A full-screen translucent overlay with a centered loading indicator.
///
/// Useful for blocking user interaction while a critical async action
/// (e.g. sign-in, submitting a complaint) is in progress.
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
          child: LoadingWidget(message: message),
        ),
      ),
    );
  }
}
