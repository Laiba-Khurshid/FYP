import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/models/complaint_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/maintenance_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/custom_textfield.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final ComplaintModel complaint;

  const AddMaintenanceScreen({super.key, required this.complaint});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _technicianController = TextEditingController();
  final _remarksController = TextEditingController();
  final _costController = TextEditingController(text: '0');

  String _maintenanceType = AppConstants.maintenanceTypeRepair;
  DateTime _maintenanceDate = DateTime.now();

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

    final success = await viewModel.addMaintenance(
      complaintId: widget.complaint.complaintId,
      assetId: widget.complaint.assetId,
      assetName: widget.complaint.assetName,
      labName: widget.complaint.labName,
      technicianName: _technicianController.text,
      maintenanceType: _maintenanceType,
      remarks: _remarksController.text,
      cost: double.parse(_costController.text.trim()),
      maintenanceDate: _maintenanceDate,
      createdBy: actor?.uid ?? '',
      createdByName: actor?.fullName ?? '',
      createdByRole: actor?.role ?? '',
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      _showSnack('Maintenance record created.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not create the record.', isError: true);
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
      appBar: AppBar(title: Text('Add Maintenance', style: AppStyles.heading4())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComplaintSummary(),
                const SizedBox(height: AppConstants.paddingLarge),
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
                _buildTypeDropdown(),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomTextField(
                  label: 'Remarks',
                  hint: 'Describe the work to be done',
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
                const SizedBox(height: AppConstants.paddingXLarge),
                CustomButton(
                  label: 'Save Record',
                  isLoading: viewModel.isSubmitting,
                  onPressed: () => _handleSave(viewModel),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomButton(
                  label: 'Cancel',
                  type: CustomButtonType.outline,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_problem_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('For Complaint: ${widget.complaint.complaintId}', style: AppStyles.label(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  widget.complaint.assetCode != null
                      ? '${widget.complaint.assetName} • ${widget.complaint.assetCode} • ${widget.complaint.labName}'
                      : '${widget.complaint.assetName} • ${widget.complaint.labName}',
                  style: AppStyles.bodyMedium(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Maintenance Type', style: AppStyles.label()),
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
              value: _maintenanceType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              style: AppStyles.bodyLarge(),
              items: AppConstants.maintenanceTypes
                  .map((type) => DropdownMenuItem<String>(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _maintenanceType = value);
              },
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