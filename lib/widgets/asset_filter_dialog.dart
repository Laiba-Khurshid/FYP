import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';

import 'package:project/widgets/custom_button.dart';

/// The result returned by [AssetFilterDialog] when the user taps Apply.
class AssetFilterResult {
  final String? category;
  final String? lab;

  const AssetFilterResult({this.category, this.lab});
}

/// A reusable bottom-sheet dialog for filtering the asset list by
/// category and lab.
///
/// Shown via [AssetFilterDialog.show], which returns the user's
/// selection (or `null` if dismissed without applying).
class AssetFilterDialog extends StatefulWidget {
  final String? initialCategory;
  final String? initialLab;

  const AssetFilterDialog({
    super.key,
    this.initialCategory,
    this.initialLab,
  });

  static Future<AssetFilterResult?> show(
      BuildContext context, {
        String? initialCategory,
        String? initialLab,
      }) {
    return showModalBottomSheet<AssetFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetFilterDialog(
        initialCategory: initialCategory,
        initialLab: initialLab,
      ),
    );
  }

  @override
  State<AssetFilterDialog> createState() => _AssetFilterDialogState();
}

class _AssetFilterDialogState extends State<AssetFilterDialog> {
  String? _category;
  String? _lab;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _lab = widget.initialLab;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusXLarge)),
        ),
        padding: EdgeInsets.only(
          left: AppConstants.paddingLarge,
          right: AppConstants.paddingLarge,
          top: AppConstants.paddingLarge,
          bottom: AppConstants.paddingLarge + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Filter Assets', style: AppStyles.heading3()),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Category', style: AppStyles.label()),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildDropdown(
              value: _category,
              hint: 'All Categories',
              items: AssetConstants.allCategories,
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text('Lab', style: AppStyles.label()),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildDropdown(
              value: _lab,
              hint: 'All Labs',
              items: AssetConstants.labs,
              onChanged: (value) => setState(() => _lab = value),
            ),
            const SizedBox(height: AppConstants.paddingXLarge),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Clear',
                    type: CustomButtonType.outline,
                    onPressed: () {
                      setState(() {
                        _category = null;
                        _lab = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: CustomButton(
                    label: 'Apply',
                    onPressed: () => Navigator.of(context).pop(
                      AssetFilterResult(category: _category, lab: _lab),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: AppStyles.bodyMedium(color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          style: AppStyles.bodyLarge(),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(hint)),
            ...items.map((item) => DropdownMenuItem<String?>(value: item, child: Text(item))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}