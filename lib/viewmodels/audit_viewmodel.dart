import 'dart:async';

import 'package:flutter/material.dart';

import '../models/audit_log_model.dart';
import '../services/audit_service.dart';

/// The ViewModel for the Audit History module (Admin-only).
///
/// Owns all UI-facing state and delegates the Firestore stream to
/// [AuditService]. Also provides lightweight client-side search/filter
/// over the most recent 200 entries the service streams.
class AuditViewModel extends ChangeNotifier {
  final AuditService _auditService;

  AuditViewModel({AuditService? auditService}) : _auditService = auditService ?? AuditService();

  StreamSubscription<List<AuditLogModel>>? _subscription;
  bool _subscribed = false;

  List<AuditLogModel> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _moduleFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get moduleFilter => _moduleFilter;

  List<String> get availableModules => _logs.map((l) => l.module).toSet().toList()..sort();

  List<AuditLogModel> get logs {
    return _logs.where((log) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          log.userName.toLowerCase().contains(query) ||
          log.action.toLowerCase().contains(query) ||
          log.module.toLowerCase().contains(query) ||
          log.referenceId.toLowerCase().contains(query);
      final matchesModule = _moduleFilter == null || log.module == _moduleFilter;
      return matchesSearch && matchesModule;
    }).toList();
  }

  /// Subscribes to the audit log stream. Safe to call on every build —
  /// only subscribes once.
  void subscribe() {
    if (_subscribed) return;
    _subscribed = true;
    _subscription = _auditService.streamAuditLogs().listen(
          (logs) {
        _logs = logs;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Could not load audit logs. Please check your internet connection.';
        notifyListeners();
      },
    );
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void filterByModule(String? module) {
    _moduleFilter = module;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}