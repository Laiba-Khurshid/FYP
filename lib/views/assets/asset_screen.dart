import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:project/models/asset_model.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';

import 'package:project/widgets/asset_card.dart';
import 'package:project/widgets/asset_filter_dialog.dart';
import 'package:project/widgets/asset_search_bar.dart';
import 'package:project/widgets/custom_button.dart';
/// The main Assets screen for AssetFlow: realtime searchable, filterable,
/// sortable list of every asset in the department.
///
/// Admin and HOD see Add/Edit/Delete controls; Students see a
/// view-only list (no add button, no edit/delete menu) per the
/// department's access rules.
class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  bool _isGridView = true;

  bool _canManage(String? role) => role == AppConstants.roleAdmin || role == AppConstants.roleHOD;

  Future<void> _openFilterDialog(AssetViewModel viewModel) async {
    final result = await AssetFilterDialog.show(
      context,
      initialCategory: viewModel.categoryFilter,
      initialLab: viewModel.labFilter,
    );
    if (result != null) {
      viewModel.applyFilters(category: result.category, lab: result.lab);
    }
  }

  void _openSortMenu(AssetViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: viewModel.sortOption,
        onSelected: viewModel.setSortOption,
      ),
    );
  }

  void _openAssetDetails(AssetModel asset) {
    Navigator.of(context).pushNamed(AppRoutes.assetDetails, arguments: asset);
  }

  void _openEditAsset(AssetModel asset) {
    Navigator.of(context).pushNamed(AppRoutes.editAsset, arguments: asset);
  }

  Future<void> _confirmDelete(BuildContext context, AssetViewModel viewModel, AssetModel asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge)),
        title: Text('Delete Asset?', style: AppStyles.heading4()),
        content: Text(
          'This will permanently delete "${asset.assetName}" (${asset.assetId}) and all of its generated Asset Codes. This cannot be undone.',
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

    if (confirmed != true || !context.mounted) return;

    final actor = context.read<AuthViewModel>().currentUser;
    final success = await viewModel.deleteAsset(
      asset,
      actorId: actor?.uid ?? '',
      actorName: actor?.fullName ?? '',
      actorRole: actor?.role ?? '',
    );
    if (!context.mounted) return;

    _showSnack(
      success ? '${asset.assetName} was deleted.' : (viewModel.errorMessage ?? 'Could not delete asset.'),
      isError: !success,
    );
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
    final assetViewModel = context.watch<AssetViewModel>();
    final role = context.watch<AuthViewModel>().currentUser?.role;
    final canManage = _canManage(role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Assets', style: AppStyles.heading4()),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: () => _openSortMenu(assetViewModel),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Asset', style: AppStyles.buttonText()),
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addAsset),
      )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssetSearchBar(
              onChanged: assetViewModel.search,
              onFilterTap: () => _openFilterDialog(assetViewModel),
              hasActiveFilters: assetViewModel.hasActiveFilters,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: assetViewModel.refreshAssets,
                child: _buildBody(assetViewModel, canManage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AssetViewModel viewModel, bool canManage) {
    if (viewModel.isLoading) {
      return _buildShimmerLoading();
    }

    if (viewModel.errorMessage != null && viewModel.totalAssetCount == 0) {
      return _buildErrorState(viewModel);
    }

    final assets = viewModel.assets;

    if (assets.isEmpty) {
      return _buildEmptyState(viewModel, canManage);
    }

    return _isGridView ? _buildGrid(assets, viewModel, canManage) : _buildList(assets, viewModel, canManage);
  }

  Widget _buildGrid(List<AssetModel> assets, AssetViewModel viewModel, bool canManage) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: assets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.paddingMedium,
        mainAxisSpacing: AppConstants.paddingMedium,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, index) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 250 + (index % 6) * 40),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
        ),
        child: _buildCard(assets[index], viewModel, canManage),
      ),
    );
  }

  Widget _buildList(List<AssetModel> assets, AssetViewModel viewModel, bool canManage) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppConstants.paddingMedium),
      itemBuilder: (context, index) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 250 + (index % 6) * 40),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
        ),
        child: _buildCard(assets[index], viewModel, canManage),
      ),
    );
  }

  Widget _buildCard(AssetModel asset, AssetViewModel viewModel, bool canManage) {
    return AssetCard(
      asset: asset,
      showActions: canManage,
      onTap: () => _openAssetDetails(asset),
      onEdit: () => _openEditAsset(asset),
      onDelete: () => _confirmDelete(context, viewModel, asset),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.divider,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.paddingMedium,
          mainAxisSpacing: AppConstants.paddingMedium,
          childAspectRatio: 0.74,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AssetViewModel viewModel, bool canManage) {
    final hasQueryOrFilters = viewModel.searchQuery.isNotEmpty || viewModel.hasActiveFilters;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasQueryOrFilters ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    hasQueryOrFilters ? 'No matching assets' : 'No assets yet',
                    style: AppStyles.heading4(),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    hasQueryOrFilters
                        ? 'Try a different search term or clear your filters.'
                        : canManage
                        ? 'Add your first asset, or load a demo dataset to explore the app.'
                        : 'No assets have been added to the department yet.',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  if (!hasQueryOrFilters && canManage) ...[
                    const SizedBox(height: AppConstants.paddingLarge),
                    CustomButton(
                      label: 'Add Asset',
                      icon: Icons.add_rounded,
                      width: 200,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addAsset),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    CustomButton(
                      label: 'Load Demo Data',
                      type: CustomButtonType.outline,
                      icon: Icons.dataset_outlined,
                      width: 200,
                      isLoading: viewModel.isSubmitting,
                      onPressed: () async {
                        final success = await viewModel.seedDemoData();
                        if (!context.mounted) return;
                        _showSnack(
                          success ? 'Demo data loaded.' : (viewModel.errorMessage ?? 'Could not load demo data.'),
                          isError: !success,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(AssetViewModel viewModel) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text('Could not load assets', style: AppStyles.heading4()),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    viewModel.errorMessage ?? 'Please check your internet connection.',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  CustomButton(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    width: 180,
                    onPressed: viewModel.refreshAssets,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for choosing the asset list's sort order.
class _SortSheet extends StatelessWidget {
  final AssetSortOption current;
  final ValueChanged<AssetSortOption> onSelected;

  const _SortSheet({required this.current, required this.onSelected});

  static const Map<AssetSortOption, String> _labels = {
    AssetSortOption.newestFirst: 'Newest First',
    AssetSortOption.oldestFirst: 'Oldest First',
    AssetSortOption.nameAscending: 'Name (A–Z)',
    AssetSortOption.nameDescending: 'Name (Z–A)',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusXLarge)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort By', style: AppStyles.heading4()),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            ..._labels.entries.map(
                  (entry) => ListTile(
                title: Text(entry.value, style: AppStyles.bodyMedium()),
                trailing: entry.key == current ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  onSelected(entry.key);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}