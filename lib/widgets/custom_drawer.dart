import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

/// A single navigable item shown inside [CustomDrawer].
class DrawerMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// A reusable navigation drawer used by all role-based dashboards
/// (Admin, Lab Incharge, Faculty, Technician).
///
/// The list of [menuItems] and [onLogout] callback are supplied by the
/// caller so the same drawer shell can be reused with role-specific
/// navigation options once the dashboard module is implemented.
class CustomDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? userEmail;
  final List<DrawerMenuItem> menuItems;
  final VoidCallback onLogout;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.menuItems,
    required this.onLogout,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return ListTile(
                    leading: Icon(item.icon, color: AppColors.textSecondary),
                    title: Text(item.label, style: AppStyles.bodyMedium()),
                    onTap: item.onTap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text('Logout', style: AppStyles.bodyMedium(color: AppColors.error)),
              onTap: onLogout,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLarge,
        AppConstants.paddingXLarge,
        AppConstants.paddingLarge,
        AppConstants.paddingLarge,
      ),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.textOnPrimary.withOpacity(0.2),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
              style: AppStyles.heading3(color: AppColors.textOnPrimary),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppStyles.heading4(color: AppColors.textOnPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userRole,
                  style: AppStyles.bodySmall(color: AppColors.textOnPrimary.withOpacity(0.85)),
                  overflow: TextOverflow.ellipsis,
                ),
                if (userEmail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    userEmail!,
                    style: AppStyles.caption(color: AppColors.textOnPrimary.withOpacity(0.75)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
