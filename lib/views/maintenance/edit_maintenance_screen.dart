import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/models/maintenance_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/maintenance_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

class EditMaintenanceScreen extends StatefulWidget {
  final MaintenanceModel record;

  const EditMaintenanceScreen({super.key, required this.record});

  @override
  State<EditMaintenanceScreen> createState() => _EditMaintenanceScreenState();
}

class _EditMaintenanceScreenState extends State<EditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _technicianController;
  late final TextEditingController _remarksController;
  late final TextEditingController _costController;

  late String _maintenanceType;
  late String _maintenanceStatus;
  late DateTime _maintenanceDate;

  @override
  void initState() {
    super.initState();
    _technicianController = TextEditingController(text: widget.record.technicianName);
    _remarksController = TextEditingController(text: widget.record.remarks);
    _costController = TextEditingController(text: widget.record.cost.toStringAsFixed(0));
    _maintenanceType = widget.record.maintenanceType;
    _maintenanceStatus = widget.record.maintenanceStatus;
    _maintenanceDate = widget.record.maintenanceDate;
  }

  @override
  void dispose() {
    _technicianController.dispose();
    _remarksController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _maintenanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _maintenanceDate = picked);
    }
  }

  String? _validateCost(String? value) {
    if (value == null || value.trim().isEmpty) return 'Cost is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0) return 'Cost cannot be negative';
    return null;
  }

  Future<void> _handleSave(MaintenanceViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final actor = context.read<AuthViewModel>().currentUser;

    final updated = await viewModel.updateMaintenance(
      existing: widget.record,
      technicianName: _technicianController.text,
      maintenanceType: _maintenanceType,
      maintenanceStatus: _maintenanceStatus,
      remarks: _remarksController.text,
      cost: double.parse(_costController.text.trim()),
      maintenanceDate: _maintenanceDate,
      actorId: actor?.uid ?? '',
      actorName: actor?.fullName ?? '',
      actorRole: actor?.role ?? '',
    );

    if (!mounted) return;

    if (updated != null) {
      Navigator.of(context).pop(updated);
      _showSnack('Maintenance record updated.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not update the record.', isError: true);
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
    final viewModel = context.watch<MaintenanceViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Edit Maintenance', style: AppStyles.heading4())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Technician Name',
                  hint: 'e.g. Ahmed Raza',
                  controller: _technicianController,
                  prefixIcon: Icons.engineering_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Technician name is required' : null,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildDropdown(
                  label: 'Maintenance Type',
                  value: _maintenanceType,
                  items: AppConstants.maintenanceTypes,
                  onChanged: (value) => setState(() => _maintenanceType = value!),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildDropdown(
                  label: 'Maintenance Status',
                  value: _maintenanceStatus,
                  items: AppConstants.maintenanceStatuses,
                  onChanged: (value) => setState(() => _maintenanceStatus = value!),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Remarks',
                  hint: 'Describe the work done',
                  controller: _remarksController,
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Remarks are required' : null,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Cost (PKR)',
                  hint: 'e.g. 1500',
                  controller: _costController,
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateCost,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildDatePicker(),
                if (_maintenanceStatus == AppConstants.maintenanceStatusCompleted) ...[
                  const SizedBox(height: AppConstants.paddingSmall),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'The completed date will be recorded automatically.',
                          style: AppStyles.caption(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppConstants.paddingXLarge),
                CustomButton(
                  label: 'Save Changes',
                  isLoading: viewModel.isSubmitting,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              style: AppStyles.bodyLarge(),
              items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Maintenance Date', style: AppStyles.label()),
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
                Text(DateFormat('MMMM d, y').format(_maintenanceDate), style: AppStyles.bodyMedium()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}