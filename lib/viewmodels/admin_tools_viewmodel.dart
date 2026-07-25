import 'package:flutter/material.dart';

import 'package:project/services/admin_tools_service.dart';

/// The ViewModel behind the Settings screen's Admin-only "Demo Data
/// Tools" section: Seed Demo Data, Reset Demo Data, Clear Complaints,
/// Clear Maintenance.
class AdminToolsViewModel extends ChangeNotifier {
  final AdminToolsService _adminToolsService;

  AdminToolsViewModel({AdminToolsService? adminToolsService})
      : _adminToolsService = adminToolsService ?? AdminToolsService();

  bool _isRunning = false;
  String? _errorMessage;

  bool get isRunning => _isRunning;
  String? get errorMessage => _errorMessage;

  Future<void> _run(Future<void> Function() action) async {
    _errorMessage = null;
    _isRunning = true;
    notifyListeners();
    try {
      await action();
    } on AdminToolsException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> seedDemoData() => _run(_adminToolsService.seedDemoData);
  Future<void> resetDemoData() => _run(_adminToolsService.resetDemoData);
  Future<void> clearComplaints() => _run(_adminToolsService.clearComplaints);
  Future<void> clearMaintenance() => _run(_adminToolsService.clearMaintenance);
}