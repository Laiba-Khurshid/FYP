import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:project/models/report_model.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/report_viewmodel.dart';

import 'package:project/widgets/custom_button.dart';


class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;

  const ReportDetailsScreen({super.key, required this.report});

  String get _title {
    switch (report.reportType) {
      case AppConstants.reportTypeAssets:
        return 'Assets Report';
      case AppConstants.reportTypeComplaints:
        return 'Complaints Report';
      case AppConstants.reportTypeMaintenance:
        return 'Maintenance Report';
      case AppConstants.reportTypeUsers:
        return 'Users Report';
      default:
        return 'Report';
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();
    final bytes = await viewModel.generatePdfBytes(report);

    if (!context.mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? 'Could not generate the PDF.',
              style: AppStyles.bodyMedium(color: AppColors.textOnPrimary),
            ),
            backgroundColor: AppColors.error,
            duration: AppConstants.snackBarDuration,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${report.reportType}_report_${DateFormat('yyyyMMdd_HHmm').format(report.generatedAt)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(_title, style: AppStyles.heading4())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: AppConstants.paddingLarge),
              ..._buildSections(),
              const SizedBox(height: AppConstants.paddingLarge),
              CustomButton(
                label: 'Download PDF Report',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () => _downloadPdf(context),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppConstants.organizationName, style: AppStyles.heading4(color: AppColors.textOnPrimary)),
          const SizedBox(height: 4),
          Text(AppConstants.departmentName, style: AppStyles.bodySmall(color: AppColors.textOnPrimary.withOpacity(0.9))),
          const SizedBox(height: 8),
          Text(
            'Generated: ${DateFormat('MMMM d, y • h:mm a').format(report.generatedAt)}',
            style: AppStyles.caption(color: AppColors.textOnPrimary.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections() {
    switch (report.reportType) {
      case AppConstants.reportTypeAssets:
        return [
          _summaryTile('Total Assets', report.totalAssets.toString(), Icons.inventory_2_rounded),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCard('Assets by Lab', report.assetsByLab),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCard('Assets by Category', report.assetsByCategory),
        ];
      case AppConstants.reportTypeComplaints:
        return [
          _summaryTile('Total Complaints', report.totalComplaints.toString(), Icons.report_problem_rounded),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCard('Complaint Summary', report.complaintsByStatus),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCard('Complaints by Lab', report.complaintsByLab),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCard('Complaints by Priority', report.complaintsByPriority),
        ];
      case AppConstants.reportTypeMaintenance:
        return [
          _summaryTile('Total Records', report.totalMaintenanceRecords.toString(), Icons.build_rounded),
          const SizedBox(height: AppConstants.paddingSmall),
          _summaryTile(
            'Total Cost',
            'PKR ${report.totalMaintenanceCost.toStringAsFixed(0)}',
            Icons.payments_rounded,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCard('Maintenance Summary', report.maintenanceByStatus),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCardDouble('Cost by Type (PKR)', report.maintenanceCostByType),
        ];
      case AppConstants.reportTypeUsers:
        return [
          _summaryTile('Total Users', report.totalUsers.toString(), Icons.people_alt_rounded),
          const SizedBox(height: AppConstants.paddingLarge),
          _breakdownCard('Users by Role', report.usersByRole),
        ];
      default:
        return [];
    }
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(child: Text(label, style: AppStyles.bodyMedium())),
          Text(value, style: AppStyles.heading4(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _breakdownCard(String title, Map<String, int> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.heading4()),
          const SizedBox(height: AppConstants.paddingSmall),
          if (data.isEmpty || data.values.every((v) => v == 0))
            Text('No data available.', style: AppStyles.bodySmall(color: AppColors.textSecondary))
          else
            ...data.entries.where((e) => e.value > 0).map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.key, style: AppStyles.bodyMedium())),
                    Text(e.value.toString(), style: AppStyles.bodyMedium(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _breakdownCardDouble(String title, Map<String, double> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.heading4()),
          const SizedBox(height: AppConstants.paddingSmall),
          if (data.isEmpty || data.values.every((v) => v == 0))
            Text('No data available.', style: AppStyles.bodySmall(color: AppColors.textSecondary))
          else
            ...data.entries.where((e) => e.value > 0).map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.key, style: AppStyles.bodyMedium())),
                    Text(e.value.toStringAsFixed(0), style: AppStyles.bodyMedium(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}