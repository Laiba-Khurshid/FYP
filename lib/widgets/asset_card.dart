import 'package:flutter/material.dart';

import 'package:project/models/asset_model.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';


class AssetCard extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const AssetCard({
    super.key,
    required this.asset,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  bool get _isTracked => AssetConstants.isTrackedCategory(asset.category);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Name + Action Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      asset.assetName,
                      style: AppStyles.heading4(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showActions) _buildPopupMenu(),
                ],
              ),
              const SizedBox(height: 4),
              // Category
              Text(
                asset.category,
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              // Tags: Lab, Quantity, Tracked
              Wrap(
                spacing: AppConstants.paddingSmall,
                runSpacing: 4,
                children: [
                  _buildChip(icon: Icons.meeting_room_outlined, label: asset.labName),
                  _buildChip(icon: Icons.inventory_2_outlined, label: 'Qty ${asset.quantity}'),
                  if (_isTracked)
                    _buildChip(icon: Icons.qr_code_2_rounded, label: 'Tracked', color: AppColors.info),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String label, Color? color}) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(label, style: AppStyles.caption(color: chipColor)),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      onSelected: (value) {
        switch (value) {
          case 'details':
            onTap();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Details', style: AppStyles.bodyMedium()),
            ],
          ),
        ),
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
    );
  }
}