import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/models/maintenance_model.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/maintenance_viewmodel.dart';

import 'package:project/widgets/asset_search_bar.dart';
import 'package:project/widgets/custom_button.dart';
import 'package:project/widgets/maintenance_card.dart';
import 'package:project/widgets/maintenance_filter_bottomsheet.dart';

import 'package:project/widgets/maintenance_filter_bottomsheet.dart';


class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<MaintenanceViewModel>().subscribe(role: user.role, uid: user.uid);
      }
    });
  }

  bool _canManage(String role) => role == AppConstants.roleAdmin;

  String _titleForRole(String role) {
    switch (role) {
      case AppConstants.roleVicePrincipal:
        return 'Escalated Maintenance';
      case AppConstants.rolePrincipal:
        return 'Final Escalated Maintenance';
      case AppConstants.roleHOD:
        return 'Department Maintenance';
      case AppConstants.roleAdmin:
        return 'All Maintenance Records';
      default:
        return 'My Maintenance History';
    }
  }

  Future<void> _openFilterSheet(MaintenanceViewModel viewModel) async {
    final result = await MaintenanceFilterBottomSheet.show(
      context,
      availableLabs: viewModel.availableLabs,
      availableAssets: viewModel.availableAssets,
      initialStatus: viewModel.statusFilter,
      initialType: viewModel.typeFilter,
      initialLab: viewModel.labFilter,
      initialAsset: viewModel.assetFilter,
      initialDate: viewModel.dateFilter,
    );
    if (result != null) {
      viewModel.applyFilters(
        status: result.status,
        type: result.type,
        lab: result.lab,
        asset: result.asset,
        date: result.date,
      );
    }
  }

  void _openDetails(MaintenanceModel record) {
    Navigator.of(context).pushNamed(AppRoutes.maintenanceDetails, arguments: record);
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceViewModel = context.watch<MaintenanceViewModel>();
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
                hint: 'Search by asset, lab, or technician',
                hasActiveFilters: maintenanceViewModel.hasActiveFilters,
                onChanged: maintenanceViewModel.search,
                onFilterTap: () => _openFilterSheet(maintenanceViewModel),
              ),
              if (maintenanceViewModel.hasActiveFilters) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                _buildActiveFilterChips(maintenanceViewModel),
              ],
              const SizedBox(height: AppConstants.paddingMedium),
              Expanded(child: _buildBody(maintenanceViewModel)),
            ],
          ),
        ),
      ),
      floatingActionButton: _canManage(role)
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addMaintenance),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
        label: Text('Add Record', style: AppStyles.buttonText()),
      )
          : null,
    );
  }

  Widget _buildActiveFilterChips(MaintenanceViewModel viewModel) {
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

    addChip(
      viewModel.statusFilter,
          () => viewModel.applyFilters(
        type: viewModel.typeFilter,
        lab: viewModel.labFilter,
        asset: viewModel.assetFilter,
        date: viewModel.dateFilter,
      ),
    );
    addChip(
      viewModel.typeFilter,
          () => viewModel.applyFilters(
        status: viewModel.statusFilter,
        lab: viewModel.labFilter,
        asset: viewModel.assetFilter,
        date: viewModel.dateFilter,
      ),
    );
    addChip(
      viewModel.labFilter,
          () => viewModel.applyFilters(
        status: viewModel.statusFilter,
        type: viewModel.typeFilter,
        asset: viewModel.assetFilter,
        date: viewModel.dateFilter,
      ),
    );
    addChip(
      viewModel.assetFilter,
          () => viewModel.applyFilters(
        status: viewModel.statusFilter,
        type: viewModel.typeFilter,
        lab: viewModel.labFilter,
        date: viewModel.dateFilter,
      ),
    );
    if (viewModel.dateFilter != null) {
      addChip(
        '${viewModel.dateFilter!.month}/${viewModel.dateFilter!.day}/${viewModel.dateFilter!.year}',
            () => viewModel.applyFilters(
          status: viewModel.statusFilter,
          type: viewModel.typeFilter,
          lab: viewModel.labFilter,
          asset: viewModel.assetFilter,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _buildBody(MaintenanceViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.errorMessage != null && viewModel.totalRecordCount == 0) {
      return _buildMessageState(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        message: viewModel.errorMessage!,
        actionLabel: 'Retry',
        onAction: () => viewModel.refreshRecords(),
      );
    }

    final records = viewModel.records;

    if (records.isEmpty) {
      return _buildMessageState(
        icon: Icons.build_circle_outlined,
        title: viewModel.hasActiveFilters || viewModel.searchQuery.isNotEmpty
            ? 'No matching records'
            : 'No maintenance records yet',
        message: viewModel.hasActiveFilters || viewModel.searchQuery.isNotEmpty
            ? 'Try adjusting your search or filters.'
            : 'Maintenance records created from in-progress complaints will appear here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: viewModel.refreshRecords,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppConstants.paddingMedium),
        itemBuilder: (context, index) {
          final record = records[index];
          return MaintenanceCard(record: record, onTap: () => _openDetails(record));
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