import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/audit_viewmodel.dart';

import 'package:project/widgets/audit_tile.dart';


class AuditHistoryScreen extends StatefulWidget {
  const AuditHistoryScreen({super.key});

  @override
  State<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends State<AuditHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuditViewModel>().subscribe();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuditViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text('Audit History', style: AppStyles.heading4())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(viewModel),
              if (viewModel.availableModules.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingMedium),
                _buildModuleChips(viewModel),
              ],
              const SizedBox(height: AppConstants.paddingMedium),
              Expanded(child: _buildBody(viewModel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AuditViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: viewModel.search,
        style: AppStyles.bodyMedium(),
        decoration: InputDecoration(
          hintText: 'Search by user, action, or module',
          hintStyle: AppStyles.bodyMedium(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
        ),
      ),
    );
  }

  Widget _buildModuleChips(AuditViewModel viewModel) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('All', viewModel.moduleFilter == null, () => viewModel.filterByModule(null)),
          const SizedBox(width: 8),
          ...viewModel.availableModules.map(
                (module) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(module, viewModel.moduleFilter == module, () => viewModel.filterByModule(module)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: AppStyles.caption(color: selected ? AppColors.textOnPrimary : AppColors.textSecondary)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }

  Widget _buildBody(AuditViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Text(viewModel.errorMessage!, style: AppStyles.bodyMedium(color: AppColors.textSecondary), textAlign: TextAlign.center),
      );
    }

    final logs = viewModel.logs;
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: AppConstants.paddingMedium),
            Text('No activity yet', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Important actions across the app will show up here.',
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppConstants.paddingSmall),
      itemBuilder: (context, index) => AuditTile(log: logs[index]),
    );
  }
}