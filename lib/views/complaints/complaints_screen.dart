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
    final result = await showModalBottomSheet<ComplaintFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ComplaintFilterSheet(),
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

    // ================================================================
    // FORCE LIGHT MODE - Complete screen light mode
    // ================================================================
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A237E),
          secondary: Color(0xFF4CAF50),
          error: Color(0xFFDC3545),
          surface: Color(0xFFF8F9FA),
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Color(0xFF666666)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            _titleForRole(role),
            style: AppStyles.heading4().copyWith(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
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
          backgroundColor: const Color(0xFF1A237E),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'New Complaint',
            style: AppStyles.buttonText().copyWith(color: Colors.white),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildActiveFilterChips(ComplaintViewModel viewModel) {
    final chips = <Widget>[];
    void addChip(String? value, VoidCallback onClear) {
      if (value == null) return;
      chips.add(Padding(
        padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
        child: Chip(
          label: Text(
            value,
            style: AppStyles.caption(color: const Color(0xFF1A237E)),
          ),
          backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.08),
          deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF1A237E)),
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
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
      color: const Color(0xFF1A237E),
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
              Icon(icon, size: 56, color: const Color(0xFFBDBDBD)),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                title,
                style: AppStyles.heading4().copyWith(color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium(color: const Color(0xFF666666)),
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

class ComplaintFilterResult {
  final String? status;
  final String? priority;
  final String? lab;
  final String? category;

  const ComplaintFilterResult({this.status, this.priority, this.lab, this.category});
}

class ComplaintFilterSheet extends StatefulWidget {
  const ComplaintFilterSheet({super.key});

  @override
  State<ComplaintFilterSheet> createState() => _ComplaintFilterSheetState();
}

class _ComplaintFilterSheetState extends State<ComplaintFilterSheet> {
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
  Widget build(BuildContext context) {
    // Force Light Mode for Filter Sheet
    return Theme(
      data: ThemeData.light(),
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
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Text(
                  'Filter Complaints',
                  style: AppStyles.heading3().copyWith(color: Colors.black),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Text(
                  'Status',
                  style: AppStyles.label().copyWith(color: const Color(0xFF444444)),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildDropdown(
                  value: _status,
                  hint: 'All Statuses',
                  items: _statusLabels.keys.toList(),
                  labelBuilder: (v) => _statusLabels[v] ?? v,
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Priority',
                  style: AppStyles.label().copyWith(color: const Color(0xFF444444)),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildDropdown(
                  value: _priority,
                  hint: 'All Priorities',
                  items: AppConstants.complaintPriorities,
                  labelBuilder: (v) => v,
                  onChanged: (value) => setState(() => _priority = value),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Lab',
                  style: AppStyles.label().copyWith(color: const Color(0xFF444444)),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                _buildDropdown(
                  value: _lab,
                  hint: 'All Labs',
                  items: AssetConstants.labs,
                  labelBuilder: (v) => v,
                  onChanged: (value) => setState(() => _lab = value),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Category',
                  style: AppStyles.label().copyWith(color: const Color(0xFF444444)),
                ),
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
                          ComplaintFilterResult(
                            status: _status,
                            priority: _priority,
                            lab: _lab,
                            category: _category,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: AppStyles.bodyMedium(color: const Color(0xFF999999)),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF666666)),
          style: AppStyles.bodyLarge().copyWith(color: Colors.black),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All')),
            ...items.map((item) => DropdownMenuItem<String?>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: AppStyles.bodyMedium().copyWith(color: Colors.black),
              ),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}