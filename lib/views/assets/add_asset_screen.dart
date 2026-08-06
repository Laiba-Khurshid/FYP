import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';
import 'package:project/core/utils/validators.dart';
import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

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
  DateTime? _selectedDate;

  @override
  void dispose() {
    _assetNameController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave(AssetViewModel viewModel, AuthViewModel authViewModel) async {
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
    if (_selectedDate == null) {
      _showSnack('Please select a purchase date.', isError: true);
      return;
    }

    final user = authViewModel.currentUser;
    if (user == null) {
      _showSnack('Your session has expired. Please log in again.', isError: true);
      return;
    }

    final success = await viewModel.addAsset(
      assetName: _assetNameController.text,
      category: _selectedCategory!,
      labName: _selectedLab!,
      quantity: int.parse(_quantityController.text),
      purchaseDate: _selectedDate!,
      location: _locationController.text,
      actorId: user.uid,
      actorName: user.fullName,
      actorRole: user.role,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showSnack('Asset added successfully.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not add asset. Please try again.', isError: true);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AssetViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

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
                // Asset Name
                CustomTextField(
                  label: 'Asset Name',
                  hint: 'e.g. Dell OptiPlex Desktop',
                  controller: _assetNameController,
                  prefixIcon: Icons.inventory_2_outlined,
                  validator: Validators.validateAssetName,
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Category
                Text('Category', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildDropdown<String>(
                  hint: 'Select a category',
                  value: _selectedCategory,
                  items: AssetConstants.allCategories,
                  labelBuilder: (category) => category,
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Lab
                Text('Lab', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildDropdown<String>(
                  hint: 'Select a lab',
                  value: _selectedLab,
                  items: AssetConstants.labs,
                  labelBuilder: (lab) => lab,
                  onChanged: (value) => setState(() => _selectedLab = value),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Quantity
                CustomTextField(
                  label: 'Quantity',
                  hint: 'e.g. 25',
                  controller: _quantityController,
                  prefixIcon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateQuantity,
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Purchase Date
                Text('Purchase Date', style: AppStyles.label()),
                const SizedBox(height: AppConstants.paddingSmall),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  child: Container(
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
                        const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Select purchase date',
                            style: _selectedDate != null
                                ? AppStyles.bodyLarge()
                                : AppStyles.bodyMedium(color: AppColors.textHint),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // Location
                CustomTextField(
                  label: 'Location',
                  hint: 'e.g. Row A–C, Front Wall, Server Corner',
                  controller: _locationController,
                  prefixIcon: Icons.place_outlined,
                  validator: (value) => Validators.validateRequired(value, fieldName: 'Location'),
                ),
                const SizedBox(height: AppConstants.paddingXLarge),

                // Buttons
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
                        isLoading: viewModel.isSubmitting,
                        onPressed: () => _handleSave(viewModel, authViewModel),
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
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(hint, style: AppStyles.bodyMedium(color: AppColors.textHint)),
            ),
            ...items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item), style: AppStyles.bodyLarge()),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}