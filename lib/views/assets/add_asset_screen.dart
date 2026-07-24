import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';

import 'package:project/widgets/asset_form.dart';
import 'package:project/widgets/custom_button.dart';
/// The Add Asset screen for AssetFlow (Admin/HOD only).
///
/// Collects all fields required to create a new asset, optionally
/// uploads an image, and delegates creation — including automatic
/// Asset Code generation for individually-tracked categories — to
/// [AssetViewModel.addAsset].
class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategory;
  String? _selectedLab;
  DateTime? _purchaseDate;
  File? _pickedImageFile;

  @override
  void dispose() {
    _assetNameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;

    setState(() => _pickedImageFile = File(picked.path));
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusXLarge)),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: Text('Take a Photo', style: AppStyles.bodyMedium()),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Choose from Gallery', style: AppStyles.bodyMedium()),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(now.year - 15),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _handleSave(AssetViewModel viewModel) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showSnack('Please select a category.', isError: true);
      return;
    }
    if (_selectedLab == null) {
      _showSnack('Please select a lab.', isError: true);
      return;
    }
    if (_purchaseDate == null) {
      _showSnack('Please select a purchase date.', isError: true);
      return;
    }

    final actor = context.read<AuthViewModel>().currentUser;
    final success = await viewModel.addAsset(
      assetName: _assetNameController.text,
      category: _selectedCategory!,
      labName: _selectedLab!,
      quantity: int.parse(_quantityController.text.trim()),
      purchaseDate: _purchaseDate!,
      location: _locationController.text,
      actorId: actor?.uid ?? '',
      actorName: actor?.fullName ?? '',
      actorRole: actor?.role ?? '',
      imageFile: _pickedImageFile,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showSnack('${_assetNameController.text.trim()} was added successfully.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not add the asset. Please try again.', isError: true);
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
    final assetViewModel = context.watch<AssetViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Asset', style: AppStyles.heading4()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AssetForm(
                  assetNameController: _assetNameController,
                  quantityController: _quantityController,
                  locationController: _locationController,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (value) => setState(() => _selectedCategory = value),
                  selectedLab: _selectedLab,
                  onLabChanged: (value) => setState(() => _selectedLab = value),
                  purchaseDate: _purchaseDate,
                  onPickDate: _pickPurchaseDate,
                  pickedImageFile: _pickedImageFile,
                  existingImageUrl: null,
                  onPickImage: _pickImage,
                  onRemoveImage: _pickedImageFile != null ? () => setState(() => _pickedImageFile = null) : null,
                ),
                const SizedBox(height: AppConstants.paddingXLarge),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Cancel',
                        type: CustomButtonType.outline,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: CustomButton(
                        label: 'Save',
                        isLoading: assetViewModel.isSubmitting,
                        onPressed: () => _handleSave(assetViewModel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}