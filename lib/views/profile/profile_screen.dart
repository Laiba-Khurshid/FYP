import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/profile_viewmodel.dart';
import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthViewModel>().currentUser?.uid;
      if (uid != null) {
        context.read<ProfileViewModel>().loadProfile(uid);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid != null) {
      await context.read<ProfileViewModel>().loadProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final profile = viewModel.profile;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('My Profile', style: AppStyles.heading4()),
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _handleRefresh,
          child: _buildBody(viewModel, profile),
        ),
      ),
    );
  }

  Widget _buildBody(ProfileViewModel viewModel, dynamic profile) {
    if (viewModel.isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.errorMessage != null && profile == null) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textHint),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(viewModel.errorMessage!, textAlign: TextAlign.center, style: AppStyles.bodyMedium(color: AppColors.textSecondary)),
                    const SizedBox(height: AppConstants.paddingLarge),
                    CustomButton(label: 'Retry', width: 160, onPressed: _handleRefresh),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (profile == null) {
      return const SizedBox.shrink();
    }

    final isStudent = profile.isStudent as bool;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      children: [
        ProfileHeader(user: profile),
        const SizedBox(height: AppConstants.paddingLarge),
        _sectionCard([
          _infoRow(Icons.badge_outlined, isStudent ? 'Roll Number' : 'Employee ID',
              (isStudent ? profile.rollNumber : profile.employeeId) as String? ?? 'Not set'),
          _divider(),
          _infoRow(Icons.email_outlined, 'Email', profile.email as String, readOnly: true),
          _divider(),
          _infoRow(Icons.work_outline_rounded, 'Role', _roleLabel(profile.role as String), readOnly: true),
          _divider(),
          _infoRow(Icons.apartment_rounded, 'Department', profile.department as String, readOnly: true),
          _divider(),
          _infoRow(Icons.phone_outlined, 'Phone Number', (profile.phoneNumber as String?) ?? 'Not set'),
        ]),
        const SizedBox(height: AppConstants.paddingLarge),
        CustomButton(
          label: 'Edit Profile',
          icon: Icons.edit_outlined,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    const labels = {
      AppConstants.roleAdmin: 'Admin',
      AppConstants.roleHOD: 'Head of Department',
      AppConstants.roleVicePrincipal: 'Vice Principal',
      AppConstants.rolePrincipal: 'Principal',
      AppConstants.roleTeacher: 'Teacher',
      AppConstants.roleStudent: 'Student',
    };
    return labels[role] ?? role;
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: AppConstants.paddingLarge);

  Widget _infoRow(IconData icon, String label, String value, {bool readOnly = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label, style: AppStyles.caption()),
                  if (readOnly) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.textHint),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(value, style: AppStyles.bodyLarge()),
            ],
          ),
        ),
      ],
    );
  }
}