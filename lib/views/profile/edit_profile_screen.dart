import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/validators.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/profile_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

/// The Edit Profile screen for AssetFlow.
///
/// Lets the signed-in user update their full name, phone number, and
/// profile picture. Email, role, and department are shown as
/// disabled/read-only fields for context but can never be submitted —
/// [ProfileService.updateProfile] doesn't even accept them as
/// parameters, so this is enforced at every layer, not just the UI.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  File? _pickedImage;
  bool _removeImage = false;
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusXLarge)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Take a photo', style: AppStyles.bodyMedium()),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Choose from gallery', style: AppStyles.bodyMedium()),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1000);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _removeImage = false;
      });
    }
  }

  Future<void> _handleSave(ProfileViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final updated = await viewModel.updateProfile(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text,
      newProfileImage: _pickedImage,
      removeProfileImage: _removeImage,
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
                Center(child: _buildAvatarPicker(profile)),
                const SizedBox(height: AppConstants.paddingXLarge),
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

  Widget _buildAvatarPicker(dynamic profile) {
    ImageProvider? backgroundImage;
    if (_pickedImage != null) {
      backgroundImage = FileImage(_pickedImage!);
    } else if (!_removeImage && profile.profileImage != null && (profile.profileImage as String).isNotEmpty) {
      backgroundImage = NetworkImage(profile.profileImage as String);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: backgroundImage,
          child: backgroundImage == null
              ? Icon(Icons.person_rounded, size: 44, color: AppColors.primary)
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _pickImage,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.textOnPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}