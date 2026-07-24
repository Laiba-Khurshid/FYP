import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:project/models/asset_model.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/core/utils/constants.dart';


/// A single asset shown in the Assets screen's grid/list.
///
/// Displays the asset's image (via [CachedNetworkImage], with a
/// graceful fallback icon when there is no image), name, category, lab,
/// and quantity. When [showActions] is `true` (Admin/HOD), a popup menu
/// offers Edit/Delete in addition to tapping the card for details;
/// Students only ever see [showActions] as `false`, so they can view
/// but never modify assets.
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      asset.category,
                      style: AppStyles.bodySmall(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: (asset.imageUrl != null && asset.imageUrl!.isNotEmpty)
            ? CachedNetworkImage(
          imageUrl: asset.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: AppColors.surface),
          errorWidget: (context, url, error) => _buildImagePlaceholder(),
        )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.inventory_2_rounded, size: 40, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String label, Color? color}) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
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
              const SizedBox(width: AppConstants.paddingSmall),
              Text('Details', style: AppStyles.bodyMedium()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppConstants.paddingSmall),
              Text('Edit', style: AppStyles.bodyMedium()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: AppConstants.paddingSmall),
              Text('Delete', style: AppStyles.bodyMedium(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
