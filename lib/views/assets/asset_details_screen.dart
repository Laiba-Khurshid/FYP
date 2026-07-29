import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/models/asset_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';

import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';

import 'package:project/views/assets/edit_asset_screen.dart';

class AssetDetailsScreen extends StatelessWidget {
  final AssetModel asset;

  const AssetDetailsScreen({super.key, required this.asset});

  bool _canManage(String? role) => role == AppConstants.roleAdmin || role == AppConstants.roleHOD;

  Future<void> _confirmDelete(BuildContext context, AssetViewModel viewModel) async {
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

    if (success) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success ? '${asset.assetName} was deleted.' : (viewModel.errorMessage ?? 'Could not delete asset.'),
            style: AppStyles.bodyMedium(color: AppColors.textOnPrimary),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
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
    final isTracked = AssetConstants.isTrackedCategory(asset.category);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Asset Details', style: AppStyles.heading4()),
        actions: canManage
            ? [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditAssetScreen(asset: asset)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, assetViewModel),
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
            // Asset Name
            Text(
              asset.assetName,
              style: AppStyles.heading2(),
            ),
            const SizedBox(height: 4),
            Text(
              asset.assetId,
              style: AppStyles.label(color: AppColors.primary),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            // Asset Details Card
            _buildInfoCard(),
            if (isTracked) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              Text('Asset Codes', style: AppStyles.heading4()),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                'Each physical unit of this asset has its own generated code.',
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildAssetCodesList(assetViewModel),
            ],
            const SizedBox(height: AppConstants.paddingLarge),
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
          _buildInfoRow(Icons.category_outlined, 'Category', asset.category),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.meeting_room_outlined, 'Lab', asset.labName),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.numbers_rounded, 'Quantity', asset.quantity.toString()),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(
            Icons.event_outlined,
            'Purchase Date',
            DateFormat('MMMM d, y').format(asset.purchaseDate),
          ),
          const Divider(height: AppConstants.paddingLarge),
          _buildInfoRow(Icons.place_outlined, 'Location', asset.location),
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

  Widget _buildAssetCodesList(AssetViewModel viewModel) {
    return StreamBuilder<List<AssetItemModel>>(
      stream: viewModel.streamAssetItems(asset.assetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Could not load Asset Codes.',
            style: AppStyles.bodyMedium(color: AppColors.error),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Text(
            'No Asset Codes have been generated yet.',
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
                title: Text(
                  item.assetCode,
                  style: AppStyles.bodyMedium().copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(item.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Text(
                    item.status,
                    style: AppStyles.caption(color: _statusColor(item.status)),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.success;
      case 'in use':
      case 'assigned':
        return AppColors.info;
      case 'under maintenance':
        return AppColors.statusInProgress;
      case 'damaged':
      case 'lost':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}