import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:project/models/user_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';


class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEditAvatarTap;

  const ProfileHeader({super.key, required this.user, this.onEditAvatarTap});

  static const Map<String, String> _roleLabels = {
    AppConstants.roleAdmin: 'Admin',
    AppConstants.roleHOD: 'Head of Department',
    AppConstants.roleVicePrincipal: 'Vice Principal',
    AppConstants.rolePrincipal: 'Principal',
    AppConstants.roleTeacher: 'Teacher',
    AppConstants.roleStudent: 'Student',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.textOnPrimary.withOpacity(0.2),
                backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                    ? CachedNetworkImageProvider(user.profileImage!)
                    : null,
                child: (user.profileImage == null || user.profileImage!.isEmpty)
                    ? Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: AppStyles.heading1(color: AppColors.textOnPrimary),
                )
                    : null,
              ),
              if (onEditAvatarTap != null)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Material(
                    color: AppColors.textOnPrimary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onEditAvatarTap,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(user.fullName, style: AppStyles.heading3(color: AppColors.textOnPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
            ),
            child: Text(
              _roleLabels[user.role] ?? user.role,
              style: AppStyles.caption(color: AppColors.textOnPrimary).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.department,
            style: AppStyles.bodySmall(color: AppColors.textOnPrimary.withOpacity(0.85)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}