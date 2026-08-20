import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/validators.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/profile_viewmodel.dart';
import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = context.read<ProfileViewModel>().profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(ProfileViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final updated = await viewModel.updateProfile(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text,
    );

    if (!mounted) return;

    if (updated != null) {
      Navigator.of(context).pop();
      _showSnack('Profile updated successfully.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not update your profile.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
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
    final viewModel = context.watch<ProfileViewModel>();
    final profile = viewModel.profile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Profile', style: AppStyles.heading4())),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Edit Profile', style: AppStyles.heading4())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // SIRF NAME, PHONE, EMAIL, DEPARTMENT - KOI AVATAR NAHI
                // ============================================================
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Phone Number (optional)',
                  hint: 'e.g. 03XXXXXXXXX',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return Validators.validatePhone(value);
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Email (read-only)',
                  controller: TextEditingController(text: profile.email),
                  prefixIcon: Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Department (read-only)',
                  controller: TextEditingController(text: profile.department),
                  prefixIcon: Icons.apartment_rounded,
                  enabled: false,
                ),
                const SizedBox(height: AppConstants.paddingXLarge),
                CustomButton(
                  label: 'Save Changes',
                  isLoading: viewModel.isSaving,
                  onPressed: () => _handleSave(viewModel),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomButton(
                  label: 'Cancel',
                  type: CustomButtonType.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}