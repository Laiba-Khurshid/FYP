import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/models/maintenance_model.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/maintenance_viewmodel.dart';

import 'package:project/widgets/maintenance_status_chip.dart';
/// The Maintenance Details screen for AssetFlow.
///
/// Shows the full record — asset/lab, technician, type, remarks, cost,
/// scheduled and completed dates, and which complaint it resolves.
/// Admin sees Edit and Delete actions in the app bar; every other role
/// gets a read-only view.
class MaintenanceDetailsScreen extends StatefulWidget {
  final MaintenanceModel record;

  const MaintenanceDetailsScreen({super.key, required this.record});

  @override
  State<MaintenanceDetailsScreen> createState() => _MaintenanceDetailsScreenState();
}

class _MaintenanceDetailsScreenState extends State<MaintenanceDetailsScreen> {
  late MaintenanceModel _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _confirmDelete(MaintenanceViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
        title: Text('Delete Maintenance Record?', style: AppStyles.heading4()),
        content: Text(
          'This will permanently delete this maintenance record. This cannot be undone.',
          style: AppStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: AppStyles.bodyMedium()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: AppStyles.bodyMedium(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await viewModel.deleteMaintenance(_record.maintenanceId);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showSnack('Maintenance record deleted.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not delete the record.', isError: true);
    }
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.editMaintenance,
      arguments: _record,
    );
    if (updated is MaintenanceModel && mounted) {
      setState(() => _record = updated);
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
    final maintenanceViewModel = context.watch<MaintenanceViewModel>();
    final role = context.watch<AuthViewModel>().currentUser?.role;
    final canManage = role == AppConstants.roleAdmin;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Maintenance Details', style: AppStyles.heading4()),
        actions: canManage
            ? [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _confirmDelete(maintenanceViewModel),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
        ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(_record.assetName, style: AppStyles.heading2())),
                MaintenanceStatusChip(status: _record.maintenanceStatus, fontSize: 12),
              ],
            ),
            const SizedBox(height: 4),
            Text('Record ID: ${_record.maintenanceId}', style: AppStyles.label(color: AppColors.primary)),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                MaintenanceTypeChip(type: _record.maintenanceType),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Remarks', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingSmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _record.remarks.isNotEmpty ? _record.remarks : 'No remarks recorded.',
                style: AppStyles.bodyMedium(),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.report_problem_outlined, 'Complaint ID', _record.complaintId),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.meeting_room_outlined, 'Lab', _record.labName),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.engineering_outlined, 'Technician', _record.technicianName),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(
            Icons.payments_outlined,
            'Cost',
            _record.cost > 0 ? 'PKR ${_record.cost.toStringAsFixed(0)}' : 'Not recorded',
          ),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.event_outlined, 'Maintenance Date', DateFormat('MMMM d, y').format(_record.maintenanceDate)),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(
            Icons.event_available_outlined,
            'Completed Date',
            _record.completedDate != null ? DateFormat('MMMM d, y').format(_record.completedDate!) : 'Not completed yet',
          ),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.schedule_outlined, 'Created On', DateFormat('MMMM d, y • h:mm a').format(_record.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppStyles.caption()),
              const SizedBox(height: 2),
              Text(value, style: AppStyles.bodyLarge()),
            ],
          ),
        ),
      ],
    );
  }
}