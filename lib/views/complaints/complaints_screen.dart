import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/models/complaint_model.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/complaint_viewmodel.dart';

import 'package:project/widgets/asset_search_bar.dart';
import 'package:project/widgets/complaint_card.dart';
import 'package:project/widgets/custom_button.dart';
/// The Complaints screen for AssetFlow.
///
/// What a user sees here depends entirely on their role — enforced by
/// `ComplaintService.streamComplaints` on the server-query side:
/// - Admin / HOD: every complaint ("Department Complaints").
/// - Vice Principal: only escalated complaints.
/// - Principal: only final-escalation complaints.
/// - Teacher / Student: only their own complaint history, plus a
///   floating action button to file a new one.
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<ComplaintViewModel>().subscribe(role: user.role, uid: user.uid);
      }
    });
  }

  bool _canCreateComplaint(String role) =>
      role == AppConstants.roleStudent || role == AppConstants.roleTeacher;

  String _titleForRole(String role) {
    switch (role) {
      case AppConstants.roleVicePrincipal:
        return 'Escalated Complaints';
      case AppConstants.rolePrincipal:
        return 'Final Escalations';
      case AppConstants.roleHOD:
        return 'Department Complaints';
      case AppConstants.roleAdmin:
        return 'All Complaints';
      default:
        return 'My Complaints';
    }
  }

  Future<void> _openFilterSheet(ComplaintViewModel viewModel) async {
    final result = await showModalBottomSheet<_ComplaintFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintFilterSheet(
        initialStatus: viewModel.statusFilter,
        initialPriority: viewModel.priorityFilter,
        initialLab: viewModel.labFilter,
        initialCategory: viewModel.categoryFilter,
      ),
    );
    if (result != null) {
      viewModel.applyFilters(
        status: result.status,
        priority: result.priority,
        lab: result.lab,
        category: result.category,
      );
    }
  }

  void _openComplaintDetails(ComplaintModel complaint) {
    Navigator.of(context).pushNamed(AppRoutes.complaintDetails, arguments: complaint);
  }

  @override
  Widget build(BuildContext context) {
    final complaintViewModel = context.watch<ComplaintViewModel>();
    final user = context.watch<AuthViewModel>().currentUser;
    final role = user?.role ?? AppConstants.roleStudent;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(_titleForRole(role), style: AppStyles.heading4())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssetSearchBar(
                hint: 'Search by ID, asset, code, or lab',
                hasActiveFilters: complaintViewModel.hasActiveFilters,
                onChanged: complaintViewModel.search,
                onFilterTap: () => _openFilterSheet(complaintViewModel),
              ),
              if (complaintViewModel.hasActiveFilters) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                _buildActiveFilterChips(complaintViewModel),
              ],
              const SizedBox(height: AppConstants.paddingMedium),
              Expanded(child: _buildBody(complaintViewModel)),
            ],
          ),
        ),
      ),
      floatingActionButton: _canCreateComplaint(role)
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addComplaint),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
        label: Text('New Complaint', style: AppStyles.buttonText()),
      )
          : null,
    );
  }

  Widget _buildActiveFilterChips(ComplaintViewModel viewModel) {
    final chips = <Widget>[];
    void addChip(String? value, VoidCallback onClear) {
      if (value == null) return;
      chips.add(Padding(
        padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
        child: Chip(
          label: Text(value, style: AppStyles.caption(color: AppColors.primary)),
          backgroundColor: AppColors.primary.withOpacity(0.08),
          deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
          onDeleted: onClear,
          side: BorderSide.none,
        ),
      ));
    }

    addChip(viewModel.statusFilter, () => viewModel.applyFilters(
        priority: viewModel.priorityFilter, lab: viewModel.labFilter, category: viewModel.categoryFilter));
    addChip(viewModel.priorityFilter, () => viewModel.applyFilters(
        status: viewModel.statusFilter, lab: viewModel.labFilter, category: viewModel.categoryFilter));
    addChip(viewModel.labFilter, () => viewModel.applyFilters(
        status: viewModel.statusFilter, priority: viewModel.priorityFilter, category: viewModel.categoryFilter));
    addChip(viewModel.categoryFilter, () => viewModel.applyFilters(
        status: viewModel.statusFilter, priority: viewModel.priorityFilter, lab: viewModel.labFilter));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _buildBody(ComplaintViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.errorMessage != null && viewModel.totalComplaintCount == 0) {
      return _buildMessageState(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        message: viewModel.errorMessage!,
        actionLabel: 'Retry',
        onAction: () => viewModel.refreshComplaints(),
      );
    }

    final complaints = viewModel.complaints;

    if (complaints.isEmpty) {
      return _buildMessageState(
        icon: Icons.fact_check_outlined,
        title: viewModel.hasActiveFilters || viewModel.searchQuery.isNotEmpty
            ? 'No matching complaints'
            : 'No complaints yet',
        message: viewModel.hasActiveFilters || viewModel.searchQuery.isNotEmpty
            ? 'Try adjusting your search or filters.'
            : 'Complaints filed against assets will appear here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: viewModel.refreshComplaints,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: complaints.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppConstants.paddingMedium),
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return ComplaintCard(
            complaint: complaint,
            onTap: () => _openComplaintDetails(complaint),
          );
        },
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingXLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.textHint),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(title, style: AppStyles.heading4(), textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppConstants.paddingLarge),
                CustomButton(label: actionLabel, width: 160, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The result returned by [_ComplaintFilterSheet] when the user taps Apply.
class _ComplaintFilterResult {
  final String? status;
  final String? priority;
  final String? lab;
  final String? category;

  const _ComplaintFilterResult({this.status, this.priority, this.lab, this.category});
}

/// A bottom-sheet dialog for filtering complaints by status, priority,
/// lab, and category — mirrors AssetFilterDialog's look and feel.
class _ComplaintFilterSheet extends StatefulWidget {
  final String? initialStatus;
  final String? initialPriority;
  final String? initialLab;
  final String? initialCategory;

  const _ComplaintFilterSheet({
    this.initialStatus,
    this.initialPriority,
    this.initialLab,
    this.initialCategory,
  });

  @override
  State<_ComplaintFilterSheet> createState() => _ComplaintFilterSheetState();
}

class _ComplaintFilterSheetState extends State<_ComplaintFilterSheet> {
  String? _status;
  String? _priority;
  String? _lab;
  String? _category;

  static const Map<String, String> _statusLabels = {
    AppConstants.statusPending: 'Pending',
    AppConstants.statusInProgress: 'In Progress',
    AppConstants.statusResolved: 'Resolved',
    AppConstants.statusEscalated: 'Escalated',
  };

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _priority = widget.initialPriority;
    _lab = widget.initialLab;
    _category = widget.initialCategory;
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
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              Text('Filter Complaints', style: AppStyles.heading3()),
              const SizedBox(height: AppConstants.paddingLarge),
              Text('Status', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _status,
                hint: 'All Statuses',
                items: _statusLabels.keys.toList(),
                labelBuilder: (v) => _statusLabels[v] ?? v,
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text('Priority', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _priority,
                hint: 'All Priorities',
                items: AppConstants.complaintPriorities,
                labelBuilder: (v) => v,
                onChanged: (value) => setState(() => _priority = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text('Lab', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _lab,
                hint: 'All Labs',
                items: AssetConstants.labs,
                labelBuilder: (v) => v,
                onChanged: (value) => setState(() => _lab = value),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text('Category', style: AppStyles.label()),
              const SizedBox(height: AppConstants.paddingSmall),
              _buildDropdown(
                value: _category,
                hint: 'All Categories',
                items: AssetConstants.allCategories,
                labelBuilder: (v) => v,
                onChanged: (value) => setState(() => _category = value),
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
                          _priority = null;
                          _lab = null;
                          _category = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: CustomButton(
                      label: 'Apply',
                      onPressed: () => Navigator.of(context).pop(
                        _ComplaintFilterResult(status: _status, priority: _priority, lab: _lab, category: _category),
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
    required String Function(String) labelBuilder,
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
            ...items.map((item) => DropdownMenuItem<String?>(value: item, child: Text(labelBuilder(item)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}