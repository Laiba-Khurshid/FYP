import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/complaint_model.dart';
import '../services/complaint_service.dart';

class ComplaintViewModel extends ChangeNotifier {
  final ComplaintService _complaintService;

  ComplaintViewModel({ComplaintService? complaintService})
      : _complaintService = complaintService ?? ComplaintService();

  // -----------------------------------------------------------------
  // State
  // -----------------------------------------------------------------

  StreamSubscription<List<ComplaintModel>>? _complaintsSubscription;
  String? _subscribedRole;
  String? _subscribedUid;

  List<ComplaintModel> _allComplaints = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _statusFilter;
  String? _priorityFilter;
  String? _labFilter;
  String? _categoryFilter;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;
  String? get labFilter => _labFilter;
  String? get categoryFilter => _categoryFilter;
  int get totalComplaintCount => _allComplaints.length;
  bool get hasActiveFilters =>
      _statusFilter != null || _priorityFilter != null || _labFilter != null || _categoryFilter != null;

  List<ComplaintModel> get complaints {
    return _allComplaints.where((complaint) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          complaint.complaintId.toLowerCase().contains(query) ||
          complaint.assetName.toLowerCase().contains(query) ||
          (complaint.assetCode?.toLowerCase().contains(query) ?? false) ||
          complaint.labName.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == null || complaint.status == _statusFilter;
      final matchesPriority = _priorityFilter == null || complaint.priority == _priorityFilter;
      final matchesLab = _labFilter == null || complaint.labName == _labFilter;
      final matchesCategory = _categoryFilter == null || complaint.category == _categoryFilter;

      return matchesSearch && matchesStatus && matchesPriority && matchesLab && matchesCategory;
    }).toList();
  }

  // -----------------------------------------------------------------
  // Stream subscription (role-aware)
  // -----------------------------------------------------------------

  void subscribe({required String role, required String uid}) {
    if (_subscribedRole == role && _subscribedUid == uid && _complaintsSubscription != null) {
      return;
    }
    _subscribedRole = role;
    _subscribedUid = uid;
    _isLoading = true;
    _complaintsSubscription?.cancel();
    _complaintsSubscription = _complaintService.streamComplaints(role: role, uid: uid).listen(
          (complaints) {
        _allComplaints = complaints;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        if (error is ComplaintException) {
          _errorMessage = error.message;
        } else if (error is FirebaseException) {
          _errorMessage = error.message ?? 'Firestore error (${error.code}). Please try again.';
        } else {
          _errorMessage = 'Could not load complaints. Please check your internet connection.';
        }
        notifyListeners();
      },
    );
  }

  Future<void> refreshComplaints() async {
    final role = _subscribedRole;
    final uid = _subscribedUid;
    if (role != null && uid != null) {
      _subscribedRole = null;
      subscribe(role: role, uid: uid);
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Search, filter
  // -----------------------------------------------------------------

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void applyFilters({String? status, String? priority, String? lab, String? category}) {
    _statusFilter = status;
    _priorityFilter = priority;
    _labFilter = lab;
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    _labFilter = null;
    _categoryFilter = null;
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

  Future<bool> addComplaint({
    required String assetId,
    String? assetCode,
    required String assetName,
    required String category,
    required String labName,
    required String reportedBy,
    required String reportedByName,
    required String userRole,
    required String description,
    required String priority,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _complaintService.addComplaint(
        assetId: assetId,
        assetCode: assetCode,
        assetName: assetName,
        category: category,
        labName: labName,
        reportedBy: reportedBy,
        reportedByName: reportedByName,
        userRole: userRole,
        description: description,
        priority: priority,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      return true;
    } on ComplaintException catch (e) {
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

  Future<bool> updateStatus(
      ComplaintModel complaint,
      String status, {
        required String actorId,
        required String actorName,
        required String actorRole,
      }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _complaintService.updateStatus(
        complaint,
        status,
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
      );
      return true;
    } on ComplaintException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> escalateComplaint(
      ComplaintModel complaint, {
        required String actorId,
        required String actorName,
        required String actorRole,
      }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _complaintService.escalateComplaint(
        complaint,
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
      );
      return true;
    } on ComplaintException catch (e) {
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