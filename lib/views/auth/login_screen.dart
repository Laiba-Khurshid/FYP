import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/routes/app_routes.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/validators.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ============================================================
  // EMAIL SUGGESTIONS KE LIYE VARIABLES
  // ============================================================
  List<String> _emailSuggestions = [];
  final FocusNode _emailFocusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _loadEmailSuggestions();

    _emailController.addListener(() {
      _updateSuggestions(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // EMAIL SUGGESTIONS - LOAD & SAVE
  // ============================================================

  Future<void> _loadEmailSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmails = prefs.getStringList('saved_emails') ?? [];
      setState(() {
        _emailSuggestions = savedEmails;
      });
    } catch (e) {
      print('Error loading email suggestions: $e');
    }
  }

  Future<void> _saveEmailSuggestion(String email) async {
    if (email.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmails = prefs.getStringList('saved_emails') ?? [];

      // Remove if already exists
      savedEmails.remove(email.trim());
      // Add at the top
      savedEmails.insert(0, email.trim());
      // Keep only last 10 emails
      if (savedEmails.length > 10) {
        savedEmails.removeRange(10, savedEmails.length);
      }

      await prefs.setStringList('saved_emails', savedEmails);
      setState(() {
        _emailSuggestions = savedEmails;
      });
    } catch (e) {
      print('Error saving email suggestion: $e');
    }
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _emailSuggestions = []);
      return;
    }

    // Load suggestions from shared preferences
    SharedPreferences.getInstance().then((pref) {
      final savedEmails = pref.getStringList('saved_emails') ?? [];
      final filtered = savedEmails
          .where((email) => email.toLowerCase().contains(query.toLowerCase()))
          .toList();
      setState(() {
        _emailSuggestions = filtered;
      });
    }).catchError((e) {
      print('Error loading suggestions: $e');
    });
  }

  Future<void> _handleLogin(AuthViewModel authViewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    // Save email for suggestions
    await _saveEmailSuggestion(email);

    final success = await authViewModel.login(
      email: email,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppConstants.paddingXLarge),
                        _buildHeader(),
                        const SizedBox(height: AppConstants.paddingXLarge),
                        // ============================================================
                        // EMAIL FIELD WITH SUGGESTIONS
                        // ============================================================
                        _buildEmailField(),
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
                          label: 'Sign in',
                          isLoading: authViewModel.isLoading,
                          onPressed: () => _handleLogin(authViewModel),
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                        _buildSignupPrompt(),
                        const SizedBox(height: AppConstants.paddingXLarge),
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo - CS AssetFlow
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            child: Image.asset(
              'lib/images/logo.png',
              height: 80,
              width: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback logo agar image load na ho
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOnPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'AssetFlow',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        Text(
          'Welcome Back',
          style: AppStyles.heading1(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingXSmall),
        Text(
          'Sign in to continue using CS AssetFlow.',
          style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================================
  // EMAIL FIELD WITH AUTO-SUGGESTIONS
  // ============================================================
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                style: AppStyles.bodyMedium(),
                keyboardType: TextInputType.emailAddress,
                onTap: () {
                  setState(() => _isFocused = true);
                  _updateSuggestions(_emailController.text);
                },
                onChanged: (value) => _updateSuggestions(value),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: AppStyles.bodyMedium(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                    vertical: AppConstants.paddingMedium,
                  ),
                  suffixIcon: _emailController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                    onPressed: () {
                      _emailController.clear();
                      setState(() => _emailSuggestions = []);
                    },
                  )
                      : null,
                ),
              ),
              // ============================================================
              // SUGGESTIONS LIST
              // ============================================================
              if (_emailSuggestions.isNotEmpty && _emailController.text.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppConstants.borderRadiusMedium),
                      bottomRight: Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 0.5),
                      left: BorderSide(color: AppColors.border, width: 0.5),
                      right: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _emailSuggestions.length,
                    itemBuilder: (context, index) {
                      final email = _emailSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history_rounded, size: 16, color: AppColors.textHint),
                        title: Text(
                          email,
                          style: AppStyles.bodyMedium().copyWith(
                            color: Colors.black,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textHint),
                          onPressed: () async {
                            // Remove email from suggestions
                            final prefs = await SharedPreferences.getInstance();
                            final savedEmails = prefs.getStringList('saved_emails') ?? [];
                            savedEmails.remove(email);
                            await prefs.setStringList('saved_emails', savedEmails);
                            _loadEmailSuggestions();
                          },
                        ),
                        onTap: () {
                          _emailController.text = email;
                          setState(() => _emailSuggestions = []);
                          _emailFocusNode.unfocus();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
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