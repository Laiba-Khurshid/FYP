import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';
import 'package:project/core/utils/validators.dart';

import 'package:project/widgets/custom_textfield.dart';

/// The shared set of form fields used by both the Add Asset and Edit
/// Asset screens: Asset Name, Category, Lab, Quantity, Purchase Date,
/// Location, and Image.
///
/// State (controllers, selected values, the picked image) is owned by
/// the calling screen — this widget is purely presentational, keeping
/// all Firestore/Storage logic out of the UI layer per the project's
/// MVVM architecture. In edit mode ([isEditMode]), Category and Lab are
/// shown as read-only, since they determine the Asset Code prefix and
/// `asset_items` subcollection scoping established when the asset was
/// created.
class AssetForm extends StatelessWidget {
  final TextEditingController assetNameController;
  final TextEditingController quantityController;
  final TextEditingController locationController;

  final String? selectedCategory;
  final ValueChanged<String?>? onCategoryChanged;

  final String? selectedLab;
  final ValueChanged<String?>? onLabChanged;

  final DateTime? purchaseDate;
  final VoidCallback onPickDate;

  final File? pickedImageFile;  // Changed from Uint8List? to File?
  final String? existingImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  final bool isEditMode;

  const AssetForm({
    super.key,
    required this.assetNameController,
    required this.quantityController,
    required this.locationController,
    required this.selectedCategory,
    required this.selectedLab,
    required this.purchaseDate,
    required this.onPickDate,
    required this.pickedImageFile,  // Changed from pickedImageBytes
    required this.existingImageUrl,
    required this.onPickImage,
    this.onCategoryChanged,
    this.onLabChanged,
    this.onRemoveImage,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePicker(),
        const SizedBox(height: AppConstants.paddingLarge),
        CustomTextField(
          label: 'Asset Name',
          hint: 'e.g. Dell OptiPlex Desktop',
          controller: assetNameController,
          prefixIcon: Icons.inventory_2_outlined,
          textCapitalization: TextCapitalization.words,
          validator: (value) => Validators.validateRequired(value, fieldName: 'Asset name'),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        _buildCategoryDropdown(),
        const SizedBox(height: AppConstants.paddingMedium),
        _buildLabDropdown(),
        const SizedBox(height: AppConstants.paddingMedium),
        CustomTextField(
          label: 'Quantity',
          hint: 'e.g. 25',
          controller: quantityController,
          prefixIcon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
          validator: (value) => Validators.validatePositiveNumber(value, fieldName: 'Quantity'),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        _buildDatePicker(context),
        const SizedBox(height: AppConstants.paddingMedium),
        CustomTextField(
          label: 'Location',
          hint: 'e.g. Row A–C, Front Wall, Server Corner',
          controller: locationController,
          prefixIcon: Icons.place_outlined,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) => Validators.validateRequired(value, fieldName: 'Location'),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImagePreview(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPickImage,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.textOnPrimary, size: 18),
                ),
              ),
            ),
          ),
          if (onRemoveImage != null && (pickedImageFile != null || (existingImageUrl?.isNotEmpty ?? false)))
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: AppColors.error,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemoveImage,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded, color: AppColors.textOnPrimary, size: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (pickedImageFile != null) {
      // For newly picked image (works on both web & Android)
      return Image.file(
        pickedImageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.textHint),
          );
        },
      );
    }
    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      // For existing image from Firebase Storage
      return CachedNetworkImage(
        imageUrl: existingImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.broken_image_outlined,
          color: AppColors.textHint,
        ),
      );
    }
    return const Center(
      child: Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.textHint),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        Container(
          decoration: BoxDecoration(
            color: isEditMode ? AppColors.divider : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              hint: Text('Select a category', style: AppStyles.bodyMedium(color: AppColors.textHint)),
              icon: isEditMode
                  ? const SizedBox.shrink()
                  : const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              style: AppStyles.bodyLarge(),
              items: isEditMode
                  ? (selectedCategory != null
                  ? [DropdownMenuItem<String>(value: selectedCategory, child: Text(selectedCategory!))]
                  : const [])
                  : AssetConstants.categoryGroups.entries
                  .expand(
                    (group) => [
                  DropdownMenuItem<String>(
                    enabled: false,
                    value: '__group_${group.key}',
                    child: Text(
                      group.key,
                      style: AppStyles.label(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ...group.value.map(
                        (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppConstants.paddingSmall),
                        child: Text(category),
                      ),
                    ),
                  ),
                ],
              )
                  .toList(),
              onChanged: isEditMode ? null : onCategoryChanged,
            ),
          ),
        ),
        if (isEditMode)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Category cannot be changed after an asset is created.',
              style: AppStyles.caption(),
            ),
          ),
      ],
    );
  }

  Widget _buildLabDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lab', style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        Container(
          decoration: BoxDecoration(
            color: isEditMode ? AppColors.divider : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLab,
              isExpanded: true,
              hint: Text('Select a lab', style: AppStyles.bodyMedium(color: AppColors.textHint)),
              icon: isEditMode
                  ? const SizedBox.shrink()
                  : const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              style: AppStyles.bodyLarge(),
              items: isEditMode
                  ? (selectedLab != null
                  ? [DropdownMenuItem<String>(value: selectedLab, child: Text(selectedLab!))]
                  : const [])
                  : AssetConstants.labs
                  .map((lab) => DropdownMenuItem<String>(value: lab, child: Text(lab)))
                  .toList(),
              onChanged: isEditMode ? null : onLabChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Purchase Date', style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        InkWell(
          onTap: onPickDate,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: AppConstants.iconSizeMedium),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  purchaseDate != null ? DateFormat('MMMM d, y').format(purchaseDate!) : 'Select purchase date',
                  style: AppStyles.bodyLarge(
                    color: purchaseDate != null ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}