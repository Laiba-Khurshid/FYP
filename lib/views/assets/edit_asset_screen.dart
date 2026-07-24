import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:project/models/asset_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';

import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';

import 'package:project/widgets/asset_form.dart';
import 'package:project/widgets/custom_button.dart';
/// The Edit Asset screen for AssetFlow (Admin/HOD only).
///
/// Allows updating an asset's name, quantity, purchase date, location,
/// and image. Category and Lab are shown read-only since they determine
/// the Asset Code prefix and `asset_items` subcollection scoping set
/// when the asset was first created. If quantity is increased for an
/// individually-tracked category, new Asset Codes are generated
/// automatically; decreasing quantity never deletes existing codes.
class EditAssetScreen extends StatefulWidget {
  final AssetModel asset;

  const EditAssetScreen({super.key, required this.asset});

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _assetNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _locationController;

  late DateTime _purchaseDate;
  File? _pickedImageFile;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _assetNameController = TextEditingController(text: widget.asset.assetName);
    _quantityController = TextEditingController(text: widget.asset.quantity.toString());
    _locationController = TextEditingController(text: widget.asset.location);
    _purchaseDate = widget.asset.purchaseDate;
  }

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

    setState(() {
      _pickedImageFile = File(picked.path);
      _removeImage = false;
    });
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
      initialDate: _purchaseDate,
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

    final newQuantity = int.parse(_quantityController.text.trim());
    final isTracked = AssetConstants.isTrackedCategory(widget.asset.category);
    final willGenerateCodes = isTracked && newQuantity > widget.asset.quantity;

    final actor = context.read<AuthViewModel>().currentUser;
    final success = await viewModel.updateAsset(
      existingAsset: widget.asset,
      assetName: _assetNameController.text,
      quantity: newQuantity,
      purchaseDate: _purchaseDate,
      location: _locationController.text,
      actorId: actor?.uid ?? '',
      actorName: actor?.fullName ?? '',
      actorRole: actor?.role ?? '',
      newImageFile: _pickedImageFile,
      removeImage: _removeImage,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showSnack(
        willGenerateCodes
            ? '${_assetNameController.text.trim()} updated — ${newQuantity - widget.asset.quantity} new Asset Code(s) generated.'
            : '${_assetNameController.text.trim()} was updated successfully.',
      );
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not update the asset. Please try again.', isError: true);
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
        title: Text('Edit Asset', style: AppStyles.heading4()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text('Asset ID: ${widget.asset.assetId}', style: AppStyles.label(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                AssetForm(
                  isEditMode: true,
                  assetNameController: _assetNameController,
                  quantityController: _quantityController,
                  locationController: _locationController,
                  selectedCategory: widget.asset.category,
                  selectedLab: widget.asset.labName,
                  purchaseDate: _purchaseDate,
                  onPickDate: _pickPurchaseDate,
                  pickedImageFile: _pickedImageFile,
                  existingImageUrl: _removeImage ? null : widget.asset.imageUrl,
                  onPickImage: _pickImage,
                  onRemoveImage: (_pickedImageFile != null || (widget.asset.imageUrl?.isNotEmpty ?? false)) && !_removeImage
                      ? () => setState(() {
                    _pickedImageFile = null;
                    _removeImage = true;
                  })
                      : null,
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
                        label: 'Save Changes',
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