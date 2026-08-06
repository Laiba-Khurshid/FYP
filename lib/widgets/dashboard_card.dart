import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';


class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? count;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.count,
    this.iconColor = AppColors.primary,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(AppConstants.paddingMedium),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Icon(icon, color: iconColor, size: AppConstants.iconSizeMedium),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyLarge().copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppStyles.bodySmall(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppConstants.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
                  ),
                  child: Text(
                    count!,
                    style: AppStyles.label(color: iconColor),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppConstants.paddingSmall),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: AppConstants.paddingXSmall),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
