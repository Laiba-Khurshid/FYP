import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:project/models/maintenance_model.dart';

import 'package:project/services/complaint_service.dart';
import 'package:project/services/maintenance_service.dart';

import 'package:project/core/utils/app_constants.dart';

class MaintenanceViewModel extends ChangeNotifier {
  final MaintenanceService _maintenanceService;
  final ComplaintService _complaintService;

  MaintenanceViewModel({
    MaintenanceService? maintenanceService,
    ComplaintService? complaintService,
  })  : _maintenanceService = maintenanceService ?? MaintenanceService(),
        _complaintService = complaintService ?? ComplaintService();

  // -----------------------------------------------------------------
  // State
  // -----------------------------------------------------------------

  StreamSubscription? _complaintsSubscription;
  StreamSubscription<List<MaintenanceModel>>? _maintenanceSubscription;
  String? _subscribedRole;
  String? _subscribedUid;

  List<MaintenanceModel> _allRecords = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _statusFilter;
  String? _typeFilter;
  String? _labFilter;
  String? _assetFilter;
  DateTime? _dateFilter;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get typeFilter => _typeFilter;
  String? get labFilter => _labFilter;
  String? get assetFilter => _assetFilter;
  DateTime? get dateFilter => _dateFilter;
  int get totalRecordCount => _allRecords.length;
  bool get hasActiveFilters =>
      _statusFilter != null || _typeFilter != null || _labFilter != null || _assetFilter != null || _dateFilter != null;

  /// The list of maintenance records after search and filters have been
  /// applied — what the Maintenance list screen should actually render.
  /// Role-based visibility is already enforced upstream by [subscribe].
  List<MaintenanceModel> get records {
    return _allRecords.where((record) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          record.maintenanceId.toLowerCase().contains(query) ||
          record.assetName.toLowerCase().contains(query) ||
          record.labName.toLowerCase().contains(query) ||
          record.technicianName.toLowerCase().contains(query) ||
          record.complaintId.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == null || record.maintenanceStatus == _statusFilter;
      final matchesType = _typeFilter == null || record.maintenanceType == _typeFilter;
      final matchesLab = _labFilter == null || record.labName == _labFilter;
      final matchesAsset = _assetFilter == null || record.assetName == _assetFilter;
      final matchesDate = _dateFilter == null ||
          (record.maintenanceDate.year == _dateFilter!.year &&
              record.maintenanceDate.month == _dateFilter!.month &&
              record.maintenanceDate.day == _dateFilter!.day);

      return matchesSearch && matchesStatus && matchesType && matchesLab && matchesAsset && matchesDate;
    }).toList();
  }

  /// Distinct lab names and asset names present in the currently visible
  /// records — used to populate filter dropdowns dynamically.
  List<String> get availableLabs => _allRecords.map((r) => r.labName).toSet().toList()..sort();
  List<String> get availableAssets => _allRecords.map((r) => r.assetName).toSet().toList()..sort();

  // -----------------------------------------------------------------
  // Stream subscription (role-aware)
  // -----------------------------------------------------------------

  /// Subscribes to the maintenance records visible to the current user.
  /// Safe to call on every build — it only re-subscribes when [role] or
  /// [uid] actually changes (e.g. after login).
  void subscribe({required String role, required String uid}) {
    if (_subscribedRole == role && _subscribedUid == uid && _maintenanceSubscription != null) {
      return;
    }
    _subscribedRole = role;
    _subscribedUid = uid;
    _isLoading = true;
    notifyListeners();

    _complaintsSubscription?.cancel();
    _maintenanceSubscription?.cancel();

    if (role == AppConstants.roleAdmin || role == AppConstants.roleHOD) {
      // Full department-wide visibility — no cross-reference needed.
      _maintenanceSubscription = _maintenanceService.streamAllMaintenance().listen(
        _onRecordsUpdate,
        onError: _onError,
      );
      return;
    }

    // Vice Principal, Principal, Teacher, Student: scope to whichever
    // complaints ComplaintService already allows this role/uid to see.
    _complaintsSubscription = _complaintService.streamComplaints(role: role, uid: uid).listen(
          (complaints) {
        final allowedComplaintIds = complaints.map((c) => c.complaintId).toList();
        _maintenanceSubscription?.cancel();
        _maintenanceSubscription =
            _maintenanceService.streamMaintenanceForComplaintIds(allowedComplaintIds).listen(
              _onRecordsUpdate,
              onError: _onError,
            );
      },
      onError: _onError,
    );
  }

  void _onRecordsUpdate(List<MaintenanceModel> records) {
    _allRecords = records;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _onError(Object error) {
    _isLoading = false;
    if (error is MaintenanceException) {
      _errorMessage = error.message;
    } else if (error is FirebaseException) {
      _errorMessage = error.message ?? 'Firestore error (${error.code}). Please try again.';
    } else {
      _errorMessage = 'Could not load maintenance records. Please check your internet connection.';
    }
    notifyListeners();
  }

  /// Manually re-subscribes — used by pull-to-refresh.
  Future<void> refreshRecords() async {
    final role = _subscribedRole;
    final uid = _subscribedUid;
    if (role != null && uid != null) {
      _subscribedRole = null; // force re-subscribe below
      subscribe(role: role, uid: uid);
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    _maintenanceSubscription?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Search, filter
  // -----------------------------------------------------------------

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void applyFilters({String? status, String? type, String? lab, String? asset, DateTime? date}) {
    _statusFilter = status;
    _typeFilter = type;
    _labFilter = lab;
    _assetFilter = asset;
    _dateFilter = date;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _typeFilter = null;
    _labFilter = null;
    _assetFilter = null;
    _dateFilter = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Create
  // -----------------------------------------------------------------

  /// Creates a new maintenance record for a complaint that has reached
  /// "In Progress". Returns `true` on success; on failure,
  /// [errorMessage] is populated and `false` is returned.
  Future<bool> addMaintenance({
    required String complaintId,
    required String assetId,
    required String assetName,
    required String labName,
    required String technicianName,
    required String maintenanceType,
    required String remarks,
    required double cost,
    required DateTime maintenanceDate,
    required String createdBy,
    required String createdByName,
    required String createdByRole,
  }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _maintenanceService.addMaintenance(
        complaintId: complaintId,
        assetId: assetId,
        assetName: assetName,
        labName: labName,
        technicianName: technicianName,
        maintenanceType: maintenanceType,
        remarks: remarks,
        cost: cost,
        maintenanceDate: maintenanceDate,
        createdBy: createdBy,
        createdByName: createdByName,
        createdByRole: createdByRole,
      );
      return true;
    } on MaintenanceException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // -----------------------------------------------------------------
  // Update
  // -----------------------------------------------------------------

  Future<MaintenanceModel?> updateMaintenance({
    required MaintenanceModel existing,
    required String technicianName,
    required String maintenanceType,
    required String maintenanceStatus,
    required String remarks,
    required double cost,
    required DateTime maintenanceDate,
    required String actorId,
    required String actorName,
    required String actorRole,
    DateTime? completedDate,
  }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      final updated = await _maintenanceService.updateMaintenance(
        existing: existing,
        technicianName: technicianName,
        maintenanceType: maintenanceType,
        maintenanceStatus: maintenanceStatus,
        remarks: remarks,
        cost: cost,
        maintenanceDate: maintenanceDate,
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
        completedDate: completedDate,
      );
      return updated;
    } on MaintenanceException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  // -----------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------

  Future<bool> deleteMaintenance(String maintenanceId) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _maintenanceService.deleteMaintenance(maintenanceId);
      return true;
    } on MaintenanceException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }
}