import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/models/complaint_model.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/complaint_viewmodel.dart';

import 'package:project/widgets/complaint_status_chip.dart';
import 'package:project/widgets/custom_button.dart';

/// The Complaint Details screen for AssetFlow.
///
/// Shows the full complaint record — asset identity, description,
/// optional photo, a visual status timeline, and who it's assigned to —
/// plus, for HOD/Admin, the actions to update its status or escalate it
/// up the HOD → Vice Principal → Principal chain.
class ComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late ComplaintModel _complaint;

  static const List<String> _statusSteps = [
    AppConstants.statusPending,
    AppConstants.statusInProgress,
    AppConstants.statusResolved,
  ];

  static const Map<String, String> _roleLabels = {
    AppConstants.roleAdmin: 'Asset manager',
    AppConstants.roleHOD: 'HOD',
    AppConstants.roleVicePrincipal: 'Vice Principal',
    AppConstants.rolePrincipal: 'Principal',
    AppConstants.roleTeacher: 'Teacher',
    AppConstants.roleStudent: 'Student',
  };

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
  }

  bool _canManage(String? role) => role == AppConstants.roleAdmin || role == AppConstants.roleHOD;

  String _roleLabel(String role) => _roleLabels[role] ?? role;

  Future<void> _updateStatus(ComplaintViewModel viewModel, String status) async {
    final actor = context.read<AuthViewModel>().currentUser;
    final success = await viewModel.updateStatus(
      _complaint,
      status,
      actorId: actor?.uid ?? '',
      actorName: actor?.fullName ?? '',
      actorRole: actor?.role ?? '',
    );
    if (!mounted) return;
    if (success) {
      setState(() => _complaint = _complaint.copyWith(status: status, updatedAt: DateTime.now()));
      _showSnack('Status updated to ${_statusLabel(status)}.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not update status.', isError: true);
    }
  }

  Future<void> _confirmEscalate(ComplaintViewModel viewModel) async {
    final nextLevel = _complaint.escalationLevel + 1;
    final nextRole = nextLevel == AppConstants.escalationLevelVicePrincipal
        ? AppConstants.roleVicePrincipal
        : AppConstants.rolePrincipal;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
        title: Text('Escalate Complaint?', style: AppStyles.heading4()),
        content: Text(
          'This will escalate the complaint to the ${_roleLabel(nextRole)} and mark it as Escalated. This cannot be undone.',
          style: AppStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: AppStyles.bodyMedium()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Escalate', style: AppStyles.bodyMedium(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final actor = context.read<AuthViewModel>().currentUser;
    final success = await viewModel.escalateComplaint(
      _complaint,
      actorId: actor?.uid ?? '',
      actorName: actor?.fullName ?? '',
      actorRole: actor?.role ?? '',
    );
    if (!mounted) return;
    if (success) {
      setState(() => _complaint = _complaint.copyWith(
        status: AppConstants.statusEscalated,
        escalationLevel: nextLevel,
        assignedTo: nextRole,
        updatedAt: DateTime.now(),
      ));
      _showSnack('Complaint escalated to ${_roleLabel(nextRole)}.');
    } else {
      _showSnack(viewModel.errorMessage ?? 'Could not escalate complaint.', isError: true);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusResolved:
        return 'Resolved';
      case AppConstants.statusEscalated:
        return 'Escalated';
      default:
        return status;
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
    final role = context.watch<AuthViewModel>().currentUser?.role;
    final canManage = _canManage(role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text('Complaint Details', style: AppStyles.heading4())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_complaint.imageUrl != null && _complaint.imageUrl!.isNotEmpty) ...[
              _buildImage(),
              const SizedBox(height: AppConstants.paddingLarge),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    _complaint.assetCode != null && _complaint.assetCode!.isNotEmpty
                        ? '${_complaint.assetName} • ${_complaint.assetCode}'
                        : _complaint.assetName,
                    style: AppStyles.heading2(),
                  ),
                ),
                ComplaintPriorityChip(priority: _complaint.priority),
              ],
            ),
            const SizedBox(height: 4),
            Text('Complaint ID: ${_complaint.complaintId}', style: AppStyles.label(color: AppColors.primary)),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildStatusTimeline(),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Description', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingSmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(_complaint.description, style: AppStyles.bodyMedium()),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildInfoCard(),
            if (role == AppConstants.roleAdmin && _complaint.status == AppConstants.statusInProgress) ...[
              const SizedBox(height: AppConstants.paddingXLarge),
              CustomButton(
                label: 'Create Maintenance Record',
                icon: Icons.build_rounded,
                type: CustomButtonType.secondary,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addMaintenance, arguments: _complaint),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: AppConstants.paddingXLarge),
              Text('Manage Complaint', style: AppStyles.heading4()),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildManagementActions(complaintViewModel),
            ],
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: CachedNetworkImage(
          imageUrl: _complaint.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.surface,
            child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.surface,
            child: const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textHint)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final isEscalated = _complaint.status == AppConstants.statusEscalated;
    final currentIndex = isEscalated ? _statusSteps.length : _statusSteps.indexOf(_complaint.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: isEscalated
          ? Row(
        children: [
          const Icon(Icons.priority_high_rounded, color: AppColors.statusEscalated),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              'This complaint has been escalated to ${_roleLabel(_complaint.assignedTo)}.',
              style: AppStyles.bodyMedium(color: AppColors.statusEscalated).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      )
          : Row(
        children: List.generate(_statusSteps.length, (index) {
          final isDone = index <= currentIndex;
          final isLast = index == _statusSteps.length - 1;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      height: 26,
                      width: 26,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : Icons.circle,
                        size: isDone ? 16 : 8,
                        color: isDone ? AppColors.textOnPrimary : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusLabel(_statusSteps[index]),
                      textAlign: TextAlign.center,
                      style: AppStyles.caption(color: isDone ? AppColors.primary : AppColors.textHint),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: index < currentIndex ? AppColors.primary : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
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
          _buildInfoRow(Icons.category_outlined, 'Category', _complaint.category),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.meeting_room_outlined, 'Lab', _complaint.labName),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.person_outline_rounded, 'Reported By', _roleLabel(_complaint.userRole)),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.assignment_ind_outlined, 'Assigned To', _roleLabel(_complaint.assignedTo)),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.event_outlined, 'Filed On', DateFormat('MMMM d, y • h:mm a').format(_complaint.createdAt)),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.update_rounded, 'Last Updated', DateFormat('MMMM d, y • h:mm a').format(_complaint.updatedAt)),
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

  Widget _buildManagementActions(ComplaintViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Update Status', style: AppStyles.label()),
        const SizedBox(height: AppConstants.paddingSmall),
        Wrap(
          spacing: AppConstants.paddingSmall,
          runSpacing: AppConstants.paddingSmall,
          children: _statusSteps.map((status) {
            final isSelected = _complaint.status == status;
            return ChoiceChip(
              label: Text(_statusLabel(status)),
              selected: isSelected,
              onSelected: viewModel.isSubmitting || isSelected
                  ? null
                  : (_) => _updateStatus(viewModel, status),
              selectedColor: AppColors.primary,
              labelStyle: AppStyles.bodySmall(color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              ),
            );
          }).toList(),
        ),
        if (_complaint.escalationLevel < AppConstants.escalationLevelPrincipal) ...[
          const SizedBox(height: AppConstants.paddingLarge),
          CustomButton(
            label: _complaint.escalationLevel == AppConstants.escalationLevelNone
                ? 'Escalate to Vice Principal'
                : 'Escalate to Principal',
            icon: Icons.priority_high_rounded,
            type: CustomButtonType.danger,
            isLoading: viewModel.isSubmitting,
            onPressed: () => _confirmEscalate(viewModel),
          ),
        ],
      ],
    );
  }
}