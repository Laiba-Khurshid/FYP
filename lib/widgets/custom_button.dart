import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

/// Button visual variants supported by [CustomButton].
enum CustomButtonType { primary, secondary, outline, text, danger }

/// A reusable, themeable button used across the entire AssetFlow app.
///
/// Supports a loading state, disabled state, leading icon, and multiple
/// visual variants so screens never need to hand-roll button styling.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppConstants.buttonHeight,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppConstants.iconSizeMedium, color: _foregroundColor),
          const SizedBox(width: AppConstants.paddingSmall),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.buttonText(color: _foregroundColor),
          ),
        ),
      ],
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: _buildByType(context, child),
    );
  }

  Widget _buildByType(BuildContext context, Widget child) {
    final radius = BorderRadius.circular(AppConstants.borderRadiusMedium);

    switch (type) {
      case CustomButtonType.outline:
        return OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isDisabled ? AppColors.border : AppColors.primary,
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );

      case CustomButtonType.text:
        return TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );

      case CustomButtonType.secondary:
      case CustomButtonType.danger:
      case CustomButtonType.primary:
        return ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _backgroundColor,
            disabledBackgroundColor: AppColors.border,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
    }
  }

  Color get _backgroundColor {
    switch (type) {
      case CustomButtonType.primary:
        return AppColors.primary;
      case CustomButtonType.secondary:
        return AppColors.secondary;
      case CustomButtonType.danger:
        return AppColors.error;
      case CustomButtonType.outline:
      case CustomButtonType.text:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (type) {
      case CustomButtonType.outline:
      case CustomButtonType.text:
        return _isDisabled ? AppColors.textHint : AppColors.primary;
      case CustomButtonType.primary:
      case CustomButtonType.secondary:
      case CustomButtonType.danger:
        return AppColors.textOnPrimary;
    }
  }
}
