import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/models/user_model.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/widgets/custom_button.dart';

class VerifyUsersScreen extends StatefulWidget {
  const VerifyUsersScreen({super.key});

  @override
  State<VerifyUsersScreen> createState() => _VerifyUsersScreenState();
}

class _VerifyUsersScreenState extends State<VerifyUsersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  static const Map<String, String> _roleLabels = {
    AppConstants.roleAdmin: 'Admin',
    AppConstants.roleHOD: 'Head of Department',
    AppConstants.roleVicePrincipal: 'Vice Principal',
    AppConstants.rolePrincipal: 'Principal',
    AppConstants.roleTeacher: 'Teacher',
    AppConstants.roleStudent: 'Student',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Subscribe to user lists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthViewModel>().subscribeToUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<UserModel> _filter(List<UserModel> users) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users.where((user) {
      final identifier = (user.isStudent ? user.rollNumber : user.employeeId) ?? '';
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (_roleLabels[user.role] ?? user.role).toLowerCase().contains(query) ||
          identifier.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _handleApprove(
      BuildContext context,
      AuthViewModel viewModel,
      UserModel user,
      ) async {
    final success = await viewModel.approveUser(user.uid);
    if (!context.mounted) return;
    _showSnack(
      context,
      success ? '${user.fullName} approved.' : (viewModel.errorMessage ?? 'Could not approve.'),
      isError: !success,
    );
  }

  Future<void> _handleReject(
      BuildContext context,
      AuthViewModel viewModel,
      UserModel user,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Text('Reject ${user.fullName}?', style: AppStyles.heading4()),
        content: Text(
          'They will not be able to log in. This can be reversed later by an Admin if needed.',
          style: AppStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: AppStyles.bodyMedium()),
          ),
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
    _showSnack(
      context,
      success ? '${user.fullName} rejected.' : (viewModel.errorMessage ?? 'Could not reject.'),
      isError: !success,
    );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppStyles.label(),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingLarge,
                AppConstants.paddingMedium,
                AppConstants.paddingLarge,
                AppConstants.paddingSmall,
              ),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // PENDING TAB
                  _buildUserList(
                    users: authViewModel.pendingUsers,
                    viewModel: authViewModel,
                    isPendingTab: true,
                    emptyIcon: Icons.verified_user_outlined,
                    emptyTitle: 'No pending registrations',
                    emptyMessage: 'New signups awaiting approval will show up here.',
                  ),
                  // APPROVED TAB
                  _buildUserList(
                    users: authViewModel.approvedUsers,
                    viewModel: authViewModel,
                    isPendingTab: false,
                    emptyIcon: Icons.people_outline_rounded,
                    emptyTitle: 'No approved users yet',
                    emptyMessage: 'Approved accounts will show up here.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: AppStyles.bodyMedium(),
        decoration: InputDecoration(
          hintText: 'Search by name, email, role, or ID',
          hintStyle: AppStyles.bodyMedium(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
        ),
      ),
    );
  }

  Widget _buildUserList({
    required List<UserModel> users,
    required AuthViewModel viewModel,
    required bool isPendingTab,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    final filteredUsers = _filter(users);

    if (viewModel.isLoading && filteredUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 56, color: AppColors.textHint),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                _searchQuery.isNotEmpty ? 'No matching users' : emptyTitle,
                style: AppStyles.heading4(),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term.'
                    : emptyMessage,
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
      itemCount: filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppConstants.paddingMedium),
      itemBuilder: (context, index) =>
          _buildUserCard(context, viewModel, filteredUsers[index], isPendingTab),
    );
  }

  Widget _buildUserCard(
      BuildContext context,
      AuthViewModel viewModel,
      UserModel user,
      bool isPendingTab,
      ) {
    final isStudent = user.isStudent;
    final identifier = isStudent ? user.rollNumber : user.employeeId;
    final statusColor = isPendingTab ? AppColors.statusPending : AppColors.success;

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
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                    Text(
                      user.fullName,
                      style: AppStyles.bodyLarge().copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppStyles.bodySmall(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Text(
                  _roleLabels[user.role] ?? user.role,
                  style: AppStyles.caption(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (identifier != null && identifier.isNotEmpty)
                Text(
                  '${isStudent ? 'Roll #' : 'Emp. ID'}: $identifier',
                  style: AppStyles.caption(),
                ),
              Text(
                'Requested: ${DateFormat('MMM d, y').format(user.createdAt)}',
                style: AppStyles.caption(),
              ),
            ],
          ),
          if (isPendingTab) ...[
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
        ],
      ),
    );
  }

  Future<void> _showAddAuthorizedUserDialog(
      BuildContext context,
      AuthViewModel viewModel,
      ) async {
    final identifierController = TextEditingController();
    String selectedRole = AppConstants.roleStudent;
    const eligibleRoles = [AppConstants.roleStudent, AppConstants.roleTeacher];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isStudent = selectedRole == AppConstants.roleStudent;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            ),
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
                  items: eligibleRoles
                      .map(
                        (role) => DropdownMenuItem<String>(
                      value: role,
                      child: Text(_roleLabels[role] ?? role),
                    ),
                  )
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
                    success
                        ? 'Authorized user added.'
                        : (viewModel.errorMessage ?? 'Could not add authorized user.'),
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