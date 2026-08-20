import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

class AssetSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final String hint;

  const AssetSearchBar({
    super.key,
    required this.onChanged,
    required this.onFilterTap,
    this.hasActiveFilters = false,
    this.hint = 'Search by name, ID, category, or lab',
  });

  @override
  State<AssetSearchBar> createState() => _AssetSearchBarState();
}

class _AssetSearchBarState extends State<AssetSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: AppStyles.bodyMedium().copyWith(
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppStyles.bodyMedium(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingMedium,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
                    : null,
              ),
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: widget.hasActiveFilters,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.filter_list_rounded,
                color: widget.hasActiveFilters ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
            onPressed: widget.onFilterTap,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}