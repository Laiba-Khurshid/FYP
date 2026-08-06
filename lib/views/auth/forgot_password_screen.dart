import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/validators.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail(AuthViewModel authViewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await authViewModel.forgotPassword(_emailController.text);

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
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
      appBar: AppBar(
        title: Text('Reset Password', style: AppStyles.heading4()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: _emailSent ? _buildSuccessState() : _buildFormState(authViewModel),
        ),
      ),
    );
  }

  Widget _buildFormState(AuthViewModel authViewModel) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text('Forgot your password?', style: AppStyles.heading2()),
          const SizedBox(height: AppConstants.paddingXSmall),
          Text(
            'Enter the email associated with your account and we will '
                'send you a link to reset your password.',
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingXLarge),
          CustomTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: AppConstants.paddingXLarge),
          CustomButton(
            label: 'Send Reset Link',
            isLoading: authViewModel.isLoading,
            onPressed: () => _handleSendResetEmail(authViewModel),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          CustomButton(
            label: 'Back to Login',
            type: CustomButtonType.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 88,
            width: 88,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.success, size: 44),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text('Check your email', style: AppStyles.heading3(), textAlign: TextAlign.center),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'We sent a password reset link to\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingXLarge),
          CustomButton(
            label: 'Back to Login',
            width: 220,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
