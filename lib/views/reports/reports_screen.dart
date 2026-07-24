import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/report_viewmodel.dart';

import 'package:project/widgets/report_card.dart';

/// The Reports screen for AssetFlow.
///
/// Lets Admin generate a fresh, on-demand report for Assets,
/// Complaints, Maintenance, or Users. Tapping a card aggregates the
/// current Firestore data (via [ReportViewModel.generateReport]) and
/// opens [ReportDetailsScreen] with the result, from which it can be
/// exported to PDF.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _openReport(BuildContext context, String reportType) async {
    final viewModel = context.read<ReportViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final success = await viewModel.generateReport(reportType);

    if (!context.mounted) return;
    Navigator.of(context).pop(); // close loading dialog

    if (success && viewModel.currentReport != null) {
      Navigator.of(context).pushNamed(AppRoutes.reportDetails, arguments: viewModel.currentReport);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? 'Could not generate the report.',
              style: AppStyles.bodyMedium(color: AppColors.textOnPrimary),
            ),
            backgroundColor: AppColors.error,
            duration: AppConstants.snackBarDuration,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text('Reports', style: AppStyles.heading4())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.paddingMedium,
            mainAxisSpacing: AppConstants.paddingMedium,
            childAspectRatio: 1.05,
            children: [
              ReportCard(
                icon: Icons.inventory_2_rounded,
                title: 'Assets Report',
                subtitle: 'Totals by lab and category',
                color: AppColors.primary,
                onTap: () => _openReport(context, AppConstants.reportTypeAssets),
              ),
              ReportCard(
                icon: Icons.report_problem_rounded,
                title: 'Complaints Report',
                subtitle: 'Status, lab, and priority breakdown',
                color: AppColors.statusPending,
                onTap: () => _openReport(context, AppConstants.reportTypeComplaints),
              ),
              ReportCard(
                icon: Icons.build_rounded,
                title: 'Maintenance Report',
                subtitle: 'Status summary and cost by type',
                color: AppColors.statusInProgress,
                onTap: () => _openReport(context, AppConstants.reportTypeMaintenance),
              ),
              ReportCard(
                icon: Icons.people_alt_rounded,
                title: 'Users Report',
                subtitle: 'Accounts by role',
                color: AppColors.secondary,
                onTap: () => _openReport(context, AppConstants.reportTypeUsers),
              ),
            ],
          ),
        ),
      ),
    );
  }
}