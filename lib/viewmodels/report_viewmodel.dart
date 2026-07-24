import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:project/models/report_model.dart';

import 'package:project/services/report_service.dart';

import 'package:project/core/utils/app_constants.dart';
/// The ViewModel for the Reports & Dashboard Analytics module.
///
/// Owns all UI-facing state and delegates every Firestore aggregation
/// and PDF-rendering operation to [ReportService]. Screens interact with
/// this class exclusively through [Provider] / [Consumer] — no Firebase
/// calls are ever made directly from the UI.
class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService;

  ReportViewModel({ReportService? reportService}) : _reportService = reportService ?? ReportService();

  bool _isLoading = false;
  String? _errorMessage;
  ReportModel? _currentReport;

  bool _isLoadingStats = false;
  Map<String, dynamic>? _dashboardStats;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReportModel? get currentReport => _currentReport;

  bool get isLoadingStats => _isLoadingStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Generates a report of the given [reportType] (one of
  /// `AppConstants.reportTypeAssets/Complaints/Maintenance/Users`).
  Future<bool> generateReport(String reportType) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      switch (reportType) {
        case AppConstants.reportTypeAssets:
          _currentReport = await _reportService.generateAssetsReport();
          break;
        case AppConstants.reportTypeComplaints:
          _currentReport = await _reportService.generateComplaintsReport();
          break;
        case AppConstants.reportTypeMaintenance:
          _currentReport = await _reportService.generateMaintenanceReport();
          break;
        case AppConstants.reportTypeUsers:
          _currentReport = await _reportService.generateUsersReport();
          break;
      }
      return true;
    } on ReportException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not generate the report. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the lightweight stats shown on the Admin Dashboard's
  /// analytics section.
  Future<void> loadDashboardStats() async {
    _isLoadingStats = true;
    notifyListeners();
    try {
      _dashboardStats = await _reportService.generateDashboardStats();
    } on ReportException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not load dashboard statistics.';
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Renders [report] to PDF bytes, ready to hand to the `printing`
  /// package for preview/share/print in the UI layer.
  Future<Uint8List?> generatePdfBytes(ReportModel report) async {
    try {
      return await _reportService.generatePdf(report);
    } catch (_) {
      _errorMessage = 'Could not generate the PDF. Please try again.';
      notifyListeners();
      return null;
    }
  }
}