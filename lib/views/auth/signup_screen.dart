import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/validators.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

/// The Signup screen for AssetFlow.
///
/// Collects full name, email, password, confirm password, department,
/// and role. Only **Student** additionally shows a Roll Number field,
/// and only **Teacher** additionally shows an Employee ID field — HOD,
/// Vice Principal, Principal, and Admin show neither, since only
/// Student/Teacher registrations are gated by the authorized-users
/// allow-list. On success, Student/Teacher accounts are Pending (an
/// Admin must approve them first); every other role is Approved
/// immediately. Either way, the user is routed back to Login with an
/// appropriate message.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _identifierController = TextEditingController();

  String _selectedRole = AppConstants.roleStudent;
  final String _department = AppConstants.departmentName;

  static const Map<String, String> _roleLabels = {
    AppConstants.roleAdmin: 'Admin',
    AppConstants.roleHOD: 'Head of Department (HOD)',
    AppConstants.roleVicePrincipal: 'Vice Principal',
    AppConstants.rolePrincipal: 'Principal',
    AppConstants.roleTeacher: 'Teacher',
    AppConstants.roleStudent: 'Student',
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  bool get _isStudentRole => _selectedRole == AppConstants.roleStudent;
  bool get _isTeacherRole => _selectedRole == AppConstants.roleTeacher;

  /// Only Student and Teacher registrations are gated by an identifier
  /// + the authorized-users allow-list + admin approval. HOD, Vice
  /// Principal, Principal, and Admin need neither.
  bool get _requiresIdentifier => _isStudentRole || _isTeacherRole;

  Future<void> _handleSignup(AuthViewModel authViewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await authViewModel.signUp(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
      department: _department,
      rollNumber: _isStudentRole ? _identifierController.text : null,
      employeeId: _isTeacherRole ? _identifierController.text : null,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      _showSuccess(
        _requiresIdentifier
            ? 'Registration successful! Your account is pending admin approval — you\'ll be able to log in once approved.'
            : 'Registration successful! You can now log in.',
      );
    } else if (authViewModel.errorMessage != null) {
      _showError(authViewModel.errorMessage!);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppStyles.bodyMedium(color: AppColors.textOnPrimary)),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
        ),
      );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppStyles.bodyMedium(color: AppColors.textOnPrimary)),
          backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Create Account', style: AppStyles.heading4()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLarge,
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
            AppConstants.paddingLarge,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join AssetFlow',
                  style: AppStyles.heading2(),
                ),
                const SizedBox(height: AppConstants.paddingXSmall),
                Text(
                  'Create an account for ${AppConstants.departmentName}.',
                  style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                CustomTextField(
                  label: 'Full Name',
                  hint: 'e.g. Ayesha Khan',
                  controller: _fullNameController,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildDepartmentField(),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildRoleSelector(),
                // Only Student (Roll Number) and Teacher (Employee ID)
                // show an identifier field. HOD/Vice Principal/
                // Principal/Admin show neither.
                if (_requiresIdentifier) ...[
                  const SizedBox(height: AppConstants.paddingMedium),
                  CustomTextField(
                    label: _isStudentRole ? 'Roll Number' : 'Employee ID',
                    hint: _isStudentRole ? 'e.g. F21-BSCS-045' : 'e.g. EMP-1042',
                    controller: _identifierController,
                    prefixIcon: Icons.badge_outlined,
                    validator: (value) => Validators.validateRequired(
                      value,
                      fieldName: _isStudentRole ? 'Roll number' : 'Employee ID',
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.paddingXLarge),
                CustomButton(
                  label: 'Create Account',
                  isLoading: authViewModel.isLoading,
                  onPressed: () => _handleSignup(authViewModel),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildLoginPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Department is fixed to the single supported department for this
  /// project, shown as a read-only field for transparency and to keep
  /// the data model consistent for future multi-department support.
  Widget _buildDepartmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Department', style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.apartment_rounded, color: AppColors.textSecondary, size: AppConstants.iconSizeMedium),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: Text(
                  _department,
                  style: AppStyles.bodyMedium(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role', style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              style: AppStyles.bodyLarge(),
              dropdownColor: AppColors.surface,
              items: AppConstants.allRoles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(_roleLabels[role] ?? role, style: AppStyles.bodyLarge()),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedRole = value;
                  // Clear any previously entered identifier when
                  // switching to/from a role that doesn't need one.
                  _identifierController.clear();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text('Already have an account? ', style: AppStyles.bodySmall(color: AppColors.textSecondary)),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Login',
              style: AppStyles.bodySmall(color: AppColors.primary).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}