import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:project/models/asset_model.dart';
import 'package:project/routes/app_routes.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';
import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/widgets/asset_filter_dialog.dart';
import 'package:project/widgets/asset_search_bar.dart';
import 'package:project/widgets/custom_button.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AssetViewModel>().subscribe();
    });
  }

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Assets', style: AppStyles.heading4()),
        actions: [
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

    return _buildProfessionalList(assets, viewModel, canManage);
  }

  Widget _buildProfessionalList(List<AssetModel> assets, AssetViewModel viewModel, bool canManage) {
    // Group assets by category
    final Map<String, List<AssetModel>> groupedAssets = {};
    for (final asset in assets) {
      final category = asset.category;
      if (!groupedAssets.containsKey(category)) {
        groupedAssets[category] = [];
      }
      groupedAssets[category]!.add(asset);
    }

    final sortedCategories = groupedAssets.keys.toList()..sort();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryAssets = groupedAssets[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Text(
                    category,
                    style: AppStyles.heading4().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${categoryAssets.length} items',
                    style: AppStyles.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Assets in this category
            ...categoryAssets.map((asset) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 200 + (categoryAssets.indexOf(asset) * 50)),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 10),
                  child: child,
                ),
              ),
              child: _buildListItem(asset, viewModel, canManage),
            )),
            const SizedBox(height: AppConstants.paddingMedium),
          ],
        );
      },
    );
  }

  Widget _buildListItem(AssetModel asset, AssetViewModel viewModel, bool canManage) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            _getCategoryIcon(asset.category),
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          asset.assetName,
          style: AppStyles.bodyLarge().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.meeting_room_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                asset.labName,
                style: AppStyles.caption(color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Qty ${asset.quantity}',
                style: AppStyles.caption(color: AppColors.textSecondary),
              ),
              if (_isTracked(asset.category)) ...[
                const SizedBox(width: AppConstants.paddingMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 12, color: AppColors.info),
                      const SizedBox(width: 2),
                      Text(
                        'Tracked',
                        style: AppStyles.caption(color: AppColors.info),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _openEditAsset(asset);
                break;
              case 'delete':
                _confirmDelete(context, viewModel, asset);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Edit', style: AppStyles.bodyMedium()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: AppStyles.bodyMedium(color: AppColors.error)),
                ],
              ),
            ),
          ],
        )
            : null,
        onTap: () => _openAssetDetails(asset),
      ),
    );
  }

  bool _isTracked(String category) {
    return AssetConstants.isTrackedCategory(category);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'computer':
        return Icons.computer_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'projector':
        return Icons.airplay_rounded; // projector_rounded nahi hai, airplay_rounded use karein
      case 'monitor':
        return Icons.monitor_rounded;
      case 'keyboard':
        return Icons.keyboard_rounded;
      case 'mouse':
        return Icons.mouse_rounded;
      case 'printer':
        return Icons.print_rounded;
      case 'scanner':
        return Icons.scanner_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.divider,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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