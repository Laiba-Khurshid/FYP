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
/// The Login screen for AssetFlow.
///
/// Collects email/password, offers a "Remember Me" toggle and a
/// "Forgot Password?" link, and delegates authentication entirely to
/// [AuthViewModel]. On success, routes to the role-appropriate
/// dashboard using [AppRoutes.dashboardForRole].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthViewModel authViewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await authViewModel.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success && authViewModel.currentUser != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboardForRole(authViewModel.currentUser!.role),
            (route) => false,
      );
    } else if (authViewModel.errorMessage != null) {
      _showError(authViewModel.errorMessage!);
    }
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppConstants.paddingXLarge),
                        _buildHeader(),
                        const SizedBox(height: AppConstants.paddingXLarge),
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
                          hint: 'Enter your password',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          validator: (value) => Validators.validateRequired(
                            value,
                            fieldName: 'Password',
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        _buildRememberAndForgot(authViewModel),
                        const SizedBox(height: AppConstants.paddingLarge),
                        CustomButton(
                          label: 'Login',
                          isLoading: authViewModel.isLoading,
                          onPressed: () => _handleLogin(authViewModel),
                        ),
                        const Spacer(),
                        _buildSignupPrompt(),
                        const SizedBox(height: AppConstants.paddingLarge),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: AppColors.textOnPrimary, size: 32),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        Text('Welcome Back', style: AppStyles.heading1()),
        const SizedBox(height: AppConstants.paddingXSmall),
        Text(
          'Log in to continue managing ${AppConstants.departmentName} assets.',
          style: AppStyles.bodyMedium(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot(AuthViewModel authViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: authViewModel.rememberMe,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (value) => authViewModel.toggleRememberMe(value ?? true),
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Text('Remember me', style: AppStyles.bodySmall(color: AppColors.textSecondary)),
          ],
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
          child: Text('Forgot Password?', style: AppStyles.label(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildSignupPrompt() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text("Don't have an account? ", style: AppStyles.bodySmall(color: AppColors.textSecondary)),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.signup),
            child: Text(
              'Sign Up',
              style: AppStyles.bodySmall(color: AppColors.primary).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
