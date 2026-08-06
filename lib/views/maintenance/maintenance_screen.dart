import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/admin_tools_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/theme_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/setting_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showInfoDialog(BuildContext context, {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
        title: Text(title, style: AppStyles.heading4()),
        content: SingleChildScrollView(
          child: Text(content, style: AppStyles.bodyMedium(color: AppColors.textSecondary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close', style: AppStyles.bodyMedium(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
        title: Text('Logout?', style: AppStyles.heading4()),
        content: Text('You will need to log in again to access your account.', style: AppStyles.bodyMedium(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('Cancel', style: AppStyles.bodyMedium())),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Logout', style: AppStyles.bodyMedium(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    final role = context.watch<AuthViewModel>().currentUser?.role;
    final isAdmin = role == AppConstants.roleAdmin;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text('Settings', style: AppStyles.heading4())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          children: [
            Text('Account', style: AppStyles.label(color: AppColors.textSecondary)),
            const SizedBox(height: AppConstants.paddingSmall),
            SettingTile(
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              subtitle: 'View and edit your profile',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileScreen),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Appearance', style: AppStyles.label(color: AppColors.textSecondary)),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildThemeOption(context, themeViewModel, ThemeMode.light, Icons.light_mode_outlined, 'Light Mode'),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildThemeOption(context, themeViewModel, ThemeMode.dark, Icons.dark_mode_outlined, 'Dark Mode'),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildThemeOption(context, themeViewModel, ThemeMode.system, Icons.settings_suggest_outlined, 'System Theme'),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('About', style: AppStyles.label(color: AppColors.textSecondary)),
            const SizedBox(height: AppConstants.paddingSmall),
            SettingTile(
              icon: Icons.info_outline_rounded,
              title: 'About Application',
              onTap: () => _showInfoDialog(
                context,
                title: 'About ${AppConstants.appName}',
                content:
                '${AppConstants.appName} v${AppConstants.appVersion}\n\n${AppConstants.appTagline}\n\nBuilt for ${AppConstants.organizationName}, ${AppConstants.departmentName}, to manage lab assets, complaints, and maintenance across ${AppConstants.totalLabs} computer laboratories.',
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            SettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _showInfoDialog(
                context,
                title: 'Privacy Policy',
                content:
                'AssetFlow collects only the information needed to manage departmental assets: your name, role, department, and contact details, plus records of complaints and maintenance you are involved in. This data is stored securely in Firebase and is only accessible to authorized roles within the department.',
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            SettingTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              onTap: () => _showInfoDialog(
                context,
                title: 'Terms & Conditions',
                content:
                'AssetFlow is provided for internal use by ${AppConstants.organizationName} to manage the ${AppConstants.departmentName}\'s laboratory assets. Accounts are restricted to authorized students, faculty, and staff. Misuse of the reporting or asset-management features may result in account suspension.',
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            SettingTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () => _showInfoDialog(
                context,
                title: 'Help & Support',
                content:
                'Need help? Contact your lab HOD for complaint or asset issues, or reach the department office directly for account access problems.',
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              Text('Admin', style: AppStyles.label(color: AppColors.textSecondary)),
              const SizedBox(height: AppConstants.paddingSmall),
              SettingTile(
                icon: Icons.history_rounded,
                title: 'Audit History',
                subtitle: 'View a log of important system activity',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.auditHistoryScreen),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildAdminToolsCard(context),
            ],
            const SizedBox(height: AppConstants.paddingLarge),
            CustomButton(
              label: 'Logout',
              type: CustomButtonType.danger,
              icon: Icons.logout_rounded,
              onPressed: () => _handleLogout(context),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeViewModel viewModel, ThemeMode mode, IconData icon, String label) {
    final isSelected = viewModel.themeMode == mode;
    return SettingTile(
      icon: icon,
      title: label,
      showChevron: false,
      iconColor: isSelected ? AppColors.primary : AppColors.textSecondary,
      trailing: Radio<ThemeMode>(
        value: mode,
        groupValue: viewModel.themeMode,
        activeColor: AppColors.primary,
        onChanged: (value) {
          if (value != null) viewModel.setThemeMode(value);
        },
      ),
      onTap: () => viewModel.setThemeMode(mode),
    );
  }

  Widget _buildAdminToolsCard(BuildContext context) {
    final adminTools = context.watch<AdminToolsViewModel>();

    Future<void> confirmAndRun(String title, String message, Future<void> Function() action) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
          title: Text(title, style: AppStyles.heading4()),
          content: Text(message, style: AppStyles.bodyMedium(color: AppColors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('Cancel', style: AppStyles.bodyMedium())),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Confirm', style: AppStyles.bodyMedium(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      await action();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              adminTools.errorMessage ?? '$title completed successfully.',
              style: AppStyles.bodyMedium(color: AppColors.textOnPrimary),
            ),
            backgroundColor: adminTools.errorMessage != null ? AppColors.error : AppColors.success,
            duration: AppConstants.snackBarDuration,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demo Data Tools', style: AppStyles.bodyLarge().copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'These actions modify Firestore data directly and cannot be undone.',
            style: AppStyles.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          if (adminTools.isRunning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            CustomButton(
              label: 'Seed Demo Data',
              type: CustomButtonType.outline,
              icon: Icons.cloud_upload_outlined,
              onPressed: () => confirmAndRun(
                'Seed Demo Data',
                'This will add the department\'s labs and a demo set of assets to Firestore. Existing assets are left untouched.',
                adminTools.seedDemoData,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            CustomButton(
              label: 'Reset Demo Data',
              type: CustomButtonType.outline,
              icon: Icons.refresh_rounded,
              onPressed: () => confirmAndRun(
                'Reset Demo Data',
                'This will delete all seeded demo assets and re-seed them fresh.',
                adminTools.resetDemoData,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            CustomButton(
              label: 'Clear Complaints',
              type: CustomButtonType.outline,
              icon: Icons.delete_sweep_outlined,
              onPressed: () => confirmAndRun(
                'Clear Complaints',
                'This will permanently delete every complaint record.',
                adminTools.clearComplaints,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            CustomButton(
              label: 'Clear Maintenance',
              type: CustomButtonType.outline,
              icon: Icons.delete_sweep_outlined,
              onPressed: () => confirmAndRun(
                'Clear Maintenance',
                'This will permanently delete every maintenance record.',
                adminTools.clearMaintenance,
              ),
            ),
          ],
        ],
      ),
    );
  }
}