import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/widgets/custom_button.dart';

/// The result returned by [MaintenanceFilterBottomSheet] when the user
/// taps Apply.
class MaintenanceFilterResult {
  final String? status;
  final String? type;
  final String? lab;
  final String? asset;
  final DateTime? date;

  const MaintenanceFilterResult({this.status, this.type, this.lab, this.asset, this.date});
}

/// A reusable bottom sheet for filtering the maintenance list by
/// status, type, lab, asset, and date.
///
/// Shown via [MaintenanceFilterBottomSheet.show], which returns the
/// user's selection (or `null` if dismissed without applying).
class MaintenanceFilterBottomSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialType;
  final String? initialLab;
  final String? initialAsset;
  final DateTime? initialDate;
  final List<String> availableLabs;
  final List<String> availableAssets;

  const MaintenanceFilterBottomSheet({
    super.key,
    required this.availableLabs,
    required this.availableAssets,
    this.initialStatus,
    this.initialType,
    this.initialLab,
    this.initialAsset,
    this.initialDate,
  });

  static Future<MaintenanceFilterResult?> show(
      BuildContext context, {
        required List<String> availableLabs,
        required List<String> availableAssets,
        String? initialStatus,
        String? initialType,
        String? initialLab,
        String? initialAsset,
        DateTime? initialDate,
      }) {
    return showModalBottomSheet<MaintenanceFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenanceFilterBottomSheet(
        availableLabs: availableLabs,
        availableAssets: availableAssets,
        initialStatus: initialStatus,
        initialType: initialType,
        initialLab: initialLab,
        initialAsset: initialAsset,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<MaintenanceFilterBottomSheet> createState() => _MaintenanceFilterBottomSheetState();
}

class _MaintenanceFilterBottomSheetState extends State<MaintenanceFilterBottomSheet> {
  String? _status;
  String? _type;
  String? _lab;
  String? _asset;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _type = widget.initialType;
    _lab = widget.initialLab;
    _asset = widget.initialAsset;
    _date = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
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
        child: SingleChildScrollView(
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
              Text('Filter Maintenance', style: AppStyles.heading3()),
              const SizedBox(height: AppConstants.paddingLarge),
              Text('Status', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _status,
                hint: 'All Statuses',
                items: AppConstants.maintenanceStatuses,
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text('Type', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _type,
                hint: 'All Types',
                items: AppConstants.maintenanceTypes,
                onChanged: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text('Lab', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _lab,
                hint: 'All Labs',
                items: widget.availableLabs,
                onChanged: (value) => setState(() => _lab = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text('Asset', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _asset,
                hint: 'All Assets',
                items: widget.availableAssets,
                onChanged: (value) => setState(() => _asset = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text('Date', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              InkWell(
                onTap: _pickDate,
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
                      const Icon(Icons.event_outlined, color: AppColors.textSecondary, size: AppConstants.iconSizeMedium),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Text(
                          _date != null ? DateFormat('MMMM d, y').format(_date!) : 'Any Date',
                          style: AppStyles.bodyMedium(color: _date != null ? AppColors.textPrimary : AppColors.textHint),
                        ),
                      ),
                      if (_date != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                          onPressed: () => setState(() => _date = null),
                        ),
                    ],
                  ),
                ),
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
                          _status = null;
                          _type = null;
                          _lab = null;
                          _asset = null;
                          _date = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: CustomButton(
                      label: 'Apply',
                      onPressed: () => Navigator.of(context).pop(
                        MaintenanceFilterResult(status: _status, type: _type, lab: _lab, asset: _asset, date: _date),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: items.contains(value) ? value : null,
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