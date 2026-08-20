import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';

import 'package:project/widgets/custom_button.dart';


class AssetFilterResult {
  final String? category;
  final String? lab;

  const AssetFilterResult({this.category, this.lab});
}


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
    // ================================================================
    // FORCE LIGHT MODE - Filter dialog ko light mode mein rakho
    // ================================================================
    return Theme(
      data: ThemeData.light().copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A237E),
          secondary: Color(0xFF4CAF50),
          error: Color(0xFFDC3545),
          surface: Color(0xFFF8F9FA),
          onSurface: Colors.black,
          onPrimary: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(color: Colors.black87),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
              // Drag handle
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),

              // Title
              Text(
                'Filter Assets',
                style: AppStyles.heading3().copyWith(
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),

              // Category label
              Text(
                'Category',
                style: AppStyles.label().copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),

              // Category dropdown
              _buildDropdown(
                value: _category,
                hint: 'All Categories',
                items: AssetConstants.allCategories,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              // Lab label
              Text(
                'Lab',
                style: AppStyles.label().copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),

              // Lab dropdown
              _buildDropdown(
                value: _lab,
                hint: 'All Labs',
                items: AssetConstants.labs,
                onChanged: (value) => setState(() => _lab = value),
              ),
              const SizedBox(height: AppConstants.paddingXLarge),

              // Buttons
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: AppStyles.bodyMedium(color: Colors.grey.shade500),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
          ),
          style: AppStyles.bodyLarge().copyWith(
            color: Colors.black,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                hint,
                style: AppStyles.bodyMedium().copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            ...items.map((item) => DropdownMenuItem<String?>(
              value: item,
              child: Text(
                item,
                style: AppStyles.bodyMedium().copyWith(
                  color: Colors.black,
                ),
              ),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}