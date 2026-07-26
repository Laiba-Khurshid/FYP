import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:project/models/asset_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';
import 'package:project/core/utils/validators.dart';

import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/complaint_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

/// The Add Complaint screen for AssetFlow (Student/Teacher).
///
/// Walks the reporter through an intelligent, dependent selection flow:
/// pick a Lab → the asset list for that lab loads live from Firestore →
/// pick an Asset → if the asset is individually tracked, pick one of its
/// live Asset Codes; if it's a bulk asset, enter the affected quantity →
/// describe the issue → optionally attach a photo → pick a priority →
/// submit. All Firestore/Storage work is delegated to
/// [ComplaintViewModel.addComplaint].
class AddComplaintScreen extends StatefulWidget {
  const AddComplaintScreen({super.key});

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _affectedQuantityController = TextEditingController();

  String? _selectedLab;
  AssetModel? _selectedAsset;
  String? _selectedAssetCode;
  String _priority = AppConstants.priorityMedium;
  File? _pickedImageFile;  // Changed: Uint8List? se File?

  @override
  void dispose() {
    _descriptionController.dispose();
    _affectedQuantityController.dispose();
    super.dispose();
  }

  bool get _assetIsTracked =>
      _selectedAsset != null && AssetConstants.isTrackedCategory(_selectedAsset!.category);

  void _onLabChanged(String? lab) {
    setState(() {
      _selectedLab = lab;
      _selectedAsset = null;
      _selectedAssetCode = null;
      _affectedQuantityController.clear();
    });
  }

  void _onAssetChanged(AssetModel? asset) {
    setState(() {
      _selectedAsset = asset;
      _selectedAssetCode = null;
      _affectedQuantityController.clear();
    });
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;

    final file = File(picked.path);  // Changed: bytes read karna band
    setState(() => _pickedImageFile = file);  // Changed: _pickedImageBytes se _pickedImageFile
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

  Future<void> _handleSubmit(ComplaintViewModel complaintViewModel, AuthViewModel authViewModel) async {
    FocusScope.of(context).unfocus();

    if (_selectedLab == null) {
      _showSnack('Please select a lab.', isError: true);
      return;
    }
    if (_selectedAsset == null) {
      _showSnack('Please select an asset.', isError: true);
      return;
    }
    if (_assetIsTracked && _selectedAssetCode == null) {
      _showSnack('Please select an Asset Code.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = authViewModel.currentUser;
    if (user == null) {
      _showSnack('Your session has expired. Please log in again.', isError: true);
      return;
    }

    // The complaints collection has a fixed 16-field schema with no
    // dedicated "affected quantity" field, so for bulk assets that
    // figure is recorded as a clear prefix on the description instead.
    final description = _assetIsTracked
        ? _descriptionController.text.trim()
        : 'Affected Quantity: ${_affectedQuantityController.text.trim()}\n\n${_descriptionController.text.trim()}';

    final success = await complaintViewModel.addComplaint(
      assetId: _selectedAsset!.assetId,
      assetCode: _assetIsTracked ? _selectedAssetCode : null,
      assetName: _selectedAsset!.assetName,
      category: _selectedAsset!.category,
      labName: _selectedLab!,
      reportedBy: user.uid,
      reportedByName: user.fullName,
      userRole: user.role,
      description: description,
      priority: _priority,
      imageFile: _pickedImageFile,  // Changed: imageBytes se imageFile
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showSnack('Your complaint was submitted successfully.');
    } else {
      _showSnack(complaintViewModel.errorMessage ?? 'Could not submit the complaint. Please try again.', isError: true);
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
    final complaintViewModel = context.watch<ComplaintViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final assetViewModel = context.watch<AssetViewModel>();

    final labAssets = _selectedLab == null
        ? <AssetModel>[]
        : assetViewModel.allAssets.where((a) => a.labName == _selectedLab).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Submit Complaint', style: AppStyles.heading4())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Select Lab', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildDropdown<String>(
                  hint: 'Choose a lab',
                  value: _selectedLab,
                  items: AssetConstants.labs,
                  labelBuilder: (lab) => lab,
                  onChanged: _onLabChanged,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Text('2. Select Asset', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                if (_selectedLab == null)
                  _buildHint('Select a lab first to load its assets.')
                else if (assetViewModel.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (labAssets.isEmpty)
                    _buildHint('No assets are recorded for this lab yet.')
                  else
                    _buildDropdown<AssetModel>(
                      hint: 'Choose an asset',
                      value: _selectedAsset,
                      items: labAssets,
                      labelBuilder: (asset) => '${asset.assetName} (${asset.category})',
                      onChanged: _onAssetChanged,
                    ),
                if (_selectedAsset != null) ...[
                  const SizedBox(height: AppConstants.paddingLarge),
                  Text(
                    _assetIsTracked ? '3. Select Asset Code' : '3. Affected Quantity',
                    style: AppStyles.label(),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  _assetIsTracked ? _buildAssetCodePicker(assetViewModel) : _buildAffectedQuantityField(),
                ],
                const SizedBox(height: AppConstants.paddingLarge),
                Text('4. Describe the Issue', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                CustomTextField(
                  label: '',
                  hint: 'What is wrong with this asset?',
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: Validators.validateDescription,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Text('5. Attach a Photo (Optional)', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildImagePicker(),
                const SizedBox(height: AppConstants.paddingLarge),
                Text('6. Priority', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildPrioritySelector(),
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
                        label: 'Submit',
                        isLoading: complaintViewModel.isSubmitting,
                        onPressed: () => _handleSubmit(complaintViewModel, authViewModel),
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

  Widget _buildHint(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: AppConstants.iconSizeMedium),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(child: Text(message, style: AppStyles.bodySmall(color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T item) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: AppStyles.bodyMedium(color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          style: AppStyles.bodyLarge(),
          items: items
              .map((item) => DropdownMenuItem<T>(value: item, child: Text(labelBuilder(item))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAssetCodePicker(AssetViewModel assetViewModel) {
    return StreamBuilder<List<AssetItemModel>>(
      stream: assetViewModel.streamAssetItems(_selectedAsset!.assetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildHint('No Asset Codes have been generated for this asset yet.');
        }
        return _buildDropdown<String>(
          hint: 'Choose an Asset Code',
          value: _selectedAssetCode,
          items: items.map((item) => item.assetCode).toList(),
          labelBuilder: (code) => code,
          onChanged: (value) => setState(() => _selectedAssetCode = value),
        );
      },
    );
  }

  Widget _buildAffectedQuantityField() {
    final maxQuantity = _selectedAsset?.quantity ?? 1;
    return CustomTextField(
      label: '',
      hint: 'e.g. 2 (out of $maxQuantity)',
      controller: _affectedQuantityController,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.pin_outlined,
      validator: (value) {
        final basic = Validators.validatePositiveNumber(value, fieldName: 'Affected quantity');
        if (basic != null) return basic;
        final parsed = int.tryParse(value!.trim());
        if (parsed != null && parsed > maxQuantity) {
          return 'Only $maxQuantity of this asset exist in this lab.';
        }
        return null;
      },
    );
  }

  Widget _buildImagePicker() {
    if (_pickedImageFile == null) {  // Changed: _pickedImageBytes se _pickedImageFile
      return InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
              const SizedBox(height: AppConstants.paddingSmall),
              Text('Upload Photo', style: AppStyles.bodyMedium(color: AppColors.primary)),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Image.file(  // Changed: Image.memory se Image.file
            _pickedImageFile!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _pickedImageFile = null),  // Changed: _pickedImageBytes se _pickedImageFile
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: AppConstants.complaintPriorities.map((priority) {
        final isSelected = _priority == priority;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
            child: GestureDetector(
              onTap: () => setState(() => _priority = priority),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  priority,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium(color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}