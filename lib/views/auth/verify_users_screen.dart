import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/models/user_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';
/// The Verify Users screen for AssetFlow (Admin-only).
///
/// Lists every account currently Pending, with a summary of who they
/// are (role, roll number/employee ID, department) and Approve/Reject
/// actions. Only Approved accounts can log in — enforced by
/// [AuthService.signIn] and [AuthViewModel.tryAutoLogin], not just here.
class VerifyUsersScreen extends StatelessWidget {
  const VerifyUsersScreen({super.key});

  static const Map<String, String> _roleLabels = {
    AppConstants.roleAdmin: 'Admin',
    AppConstants.roleHOD: 'Head of Department',
    AppConstants.roleVicePrincipal: 'Vice Principal',
    AppConstants.rolePrincipal: 'Principal',
    AppConstants.roleTeacher: 'Teacher',
    AppConstants.roleStudent: 'Student',
  };

  Future<void> _handleApprove(BuildContext context, AuthViewModel viewModel, UserModel user) async {
    final success = await viewModel.approveUser(user.uid);
    if (!context.mounted) return;
    _showSnack(context, success ? '${user.fullName} approved.' : (viewModel.errorMessage ?? 'Could not approve.'), isError: !success);
  }

  Future<void> _handleReject(BuildContext context, AuthViewModel viewModel, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
        title: Text('Reject ${user.fullName}?', style: AppStyles.heading4()),
        content: Text(
          'They will not be able to log in. This can be reversed later by an Admin if needed.',
          style: AppStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('Cancel', style: AppStyles.bodyMedium())),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Reject', style: AppStyles.bodyMedium(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await viewModel.rejectUser(user.uid);
    if (!context.mounted) return;
    _showSnack(context, success ? '${user.fullName} rejected.' : (viewModel.errorMessage ?? 'Could not reject.'), isError: !success);
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppStyles.bodyMedium(color: AppColors.textOnPrimary)),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          duration: AppConstants.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Verify Users', style: AppStyles.heading4()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Authorized User',
            onPressed: () => _showAddAuthorizedUserDialog(context, authViewModel),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: authViewModel.streamPendingUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load pending registrations.',
                  style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                ),
              );
            }

            final pendingUsers = snapshot.data ?? [];
            if (pendingUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 56, color: AppColors.textHint),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Text('No pending registrations', style: AppStyles.heading4()),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        'New signups awaiting approval will show up here.',
                        style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              itemCount: pendingUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppConstants.paddingMedium),
              itemBuilder: (context, index) => _buildUserCard(context, authViewModel, pendingUsers[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthViewModel viewModel, UserModel user) {
    final isStudent = user.isStudent;
    final identifier = isStudent ? user.rollNumber : user.employeeId;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: AppStyles.heading4(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: AppStyles.bodyLarge().copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(user.email, style: AppStyles.bodySmall(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusPending.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Text(_roleLabels[user.role] ?? user.role, style: AppStyles.caption(color: AppColors.statusPending)),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('${isStudent ? 'Roll #' : 'Emp. ID'}: ${identifier ?? '—'}', style: AppStyles.caption()),
              Text('Requested: ${DateFormat('MMM d, y').format(user.createdAt)}', style: AppStyles.caption()),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Reject',
                  type: CustomButtonType.outline,
                  onPressed: () => _handleReject(context, viewModel, user),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: CustomButton(
                  label: 'Approve',
                  onPressed: () => _handleApprove(context, viewModel, user),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAuthorizedUserDialog(BuildContext context, AuthViewModel viewModel) async {
    final identifierController = TextEditingController();
    String selectedRole = AppConstants.roleStudent;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isStudent = selectedRole == AppConstants.roleStudent;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
            title: Text('Add Authorized User', style: AppStyles.heading4()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  items: AppConstants.allRoles
                      .map((role) => DropdownMenuItem<String>(value: role, child: Text(_roleLabels[role] ?? role)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedRole = value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextField(
                  controller: identifierController,
                  decoration: InputDecoration(
                    labelText: isStudent ? 'Roll Number' : 'Employee ID',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel', style: AppStyles.bodyMedium()),
              ),
              TextButton(
                onPressed: () async {
                  final success = await viewModel.addAuthorizedUser(
                    rollNumber: isStudent ? identifierController.text : null,
                    employeeId: isStudent ? null : identifierController.text,
                    role: selectedRole,
                    department: AppConstants.departmentName,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (!context.mounted) return;
                  _showSnack(
                    context,
                    success ? 'Authorized user added.' : (viewModel.errorMessage ?? 'Could not add authorized user.'),
                    isError: !success,
                  );
                },
                child: Text('Add', style: AppStyles.bodyMedium(color: AppColors.primary)),
              ),
            ],
          );
        },
      ),
    );
  }
}