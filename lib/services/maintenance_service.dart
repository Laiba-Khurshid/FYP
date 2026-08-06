import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project/models/maintenance_model.dart';

import 'package:project/core/utils/app_constants.dart';

import 'package:project/services/audit_service.dart';
import 'package:project/services/complaint_service.dart';
import 'package:project/services/notification_service.dart';

class MaintenanceException implements Exception {
  final String message;
  const MaintenanceException(this.message);

  @override
  String toString() => message;
}


class MaintenanceService {
  final FirebaseFirestore _firestore;
  final ComplaintService _complaintService;
  final NotificationService _notificationService;
  final AuditService _auditService;

  MaintenanceService({
    FirebaseFirestore? firestore,
    ComplaintService? complaintService,
    NotificationService? notificationService,
    AuditService? auditService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _complaintService = complaintService ?? ComplaintService(),
        _notificationService = notificationService ?? NotificationService(),
        _auditService = auditService ?? AuditService();

  CollectionReference<Map<String, dynamic>> get _maintenanceRef =>
      _firestore.collection(AppConstants.maintenanceCollection);

  // -----------------------------------------------------------------
  // Read (stream)
  // -----------------------------------------------------------------

  /// Streams every maintenance record, newest first. Used by Admin and
  /// HOD, who have full department-wide visibility.
  Stream<List<MaintenanceModel>> streamAllMaintenance() {
    return _maintenanceRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(MaintenanceModel.fromDocument).toList());
  }


  Stream<List<MaintenanceModel>> streamMaintenanceForComplaintIds(List<String> allowedComplaintIds) {
    if (allowedComplaintIds.isEmpty) {
      return Stream.value(const []);
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < allowedComplaintIds.length; i += 30) {
      final end = i + 30 > allowedComplaintIds.length ? allowedComplaintIds.length : i + 30;
      chunks.add(allowedComplaintIds.sublist(i, end));
    }


    if (chunks.length == 1) {
      return _maintenanceRef.where('complaintId', whereIn: chunks.first).snapshots().map((snapshot) {
        final records = snapshot.docs.map(MaintenanceModel.fromDocument).toList();
        records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return records;
      });
    }


    final streams = chunks.map(
          (chunk) => _maintenanceRef
          .where('complaintId', whereIn: chunk)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(MaintenanceModel.fromDocument).toList()),
    );

    return _mergeStreams(streams.toList());
  }

  Stream<List<MaintenanceModel>> _mergeStreams(List<Stream<List<MaintenanceModel>>> streams) {
    final latest = List<List<MaintenanceModel>>.filled(streams.length, const []);
    late final StreamController<List<MaintenanceModel>> controller;
    final subscriptions = <StreamSubscription>[];

    controller = StreamController<List<MaintenanceModel>>(
      onCancel: () {
        for (final sub in subscriptions) {
          sub.cancel();
        }
      },
    );

    for (var i = 0; i < streams.length; i++) {
      subscriptions.add(streams[i].listen((data) {
        latest[i] = data;
        final merged = latest.expand((e) => e).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(merged);
      }));
    }

    return controller.stream;
  }

  // -----------------------------------------------------------------
  // Create
  // -----------------------------------------------------------------

  /// Creates a new maintenance record for a complaint. Defaults:
  /// `maintenanceStatus` = Pending, `completedDate` = null.
  Future<MaintenanceModel> addMaintenance({
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
    try {
      final docRef = _maintenanceRef.doc();
      final now = DateTime.now();

      final record = MaintenanceModel(
        maintenanceId: docRef.id,
        complaintId: complaintId,
        assetId: assetId,
        assetName: assetName,
        labName: labName,
        technicianName: technicianName.trim(),
        maintenanceType: maintenanceType,
        maintenanceStatus: AppConstants.maintenanceStatusPending,
        remarks: remarks.trim(),
        cost: cost,
        maintenanceDate: maintenanceDate,
        completedDate: null,
        createdBy: createdBy,
        createdAt: now,
      );

      await docRef.set(record.toMap());

      await _notifyComplaintReporter(
        complaintId: complaintId,
        title: 'Maintenance Scheduled',
        message: 'Maintenance work has started on $assetName in $labName.',
        type: AppConstants.notificationTypeMaintenanceCreated,
        relatedId: record.maintenanceId,
      );

      await _auditService.record(
        userId: createdBy,
        userName: createdByName,
        role: createdByRole,
        action: AppConstants.auditActionMaintenanceAdded,
        module: AppConstants.auditModuleMaintenance,
        referenceId: record.maintenanceId,
      );

      return record;
    } on FirebaseException catch (e) {
      throw MaintenanceException(_mapFirebaseError(e));
    } catch (_) {
      throw const MaintenanceException('Could not create the maintenance record. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Update
  // -----------------------------------------------------------------

  /// Updates an existing maintenance record. If [maintenanceStatus] is
  /// being set to Completed and no [completedDate] is supplied, the
  /// completed date is automatically set to now. Moving away from
  /// Completed clears the completed date.
  Future<MaintenanceModel> updateMaintenance({
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
    try {
      DateTime? resolvedCompletedDate = completedDate ?? existing.completedDate;
      if (maintenanceStatus == AppConstants.maintenanceStatusCompleted && resolvedCompletedDate == null) {
        resolvedCompletedDate = DateTime.now();
      }
      if (maintenanceStatus != AppConstants.maintenanceStatusCompleted) {
        resolvedCompletedDate = null;
      }

      final updated = existing.copyWith(
        technicianName: technicianName.trim(),
        maintenanceType: maintenanceType,
        maintenanceStatus: maintenanceStatus,
        remarks: remarks.trim(),
        cost: cost,
        maintenanceDate: maintenanceDate,
        completedDate: resolvedCompletedDate,
        clearCompletedDate: resolvedCompletedDate == null,
      );

      await _maintenanceRef.doc(existing.maintenanceId).update(updated.toMap());

      final justCompleted = maintenanceStatus == AppConstants.maintenanceStatusCompleted &&
          existing.maintenanceStatus != AppConstants.maintenanceStatusCompleted;
      if (justCompleted) {
        await _notifyComplaintReporter(
          complaintId: existing.complaintId,
          title: 'Maintenance Completed',
          message: 'Maintenance work on ${existing.assetName} in ${existing.labName} has been completed.',
          type: AppConstants.notificationTypeMaintenanceCompleted,
          relatedId: existing.maintenanceId,
        );
      }

      await _auditService.record(
        userId: actorId,
        userName: actorName,
        role: actorRole,
        action: justCompleted ? AppConstants.auditActionMaintenanceCompleted : AppConstants.auditActionMaintenanceUpdated,
        module: AppConstants.auditModuleMaintenance,
        referenceId: existing.maintenanceId,
      );

      return updated;
    } on FirebaseException catch (e) {
      throw MaintenanceException(_mapFirebaseError(e));
    } catch (_) {
      throw const MaintenanceException('Could not update the maintenance record. Please try again.');
    }
  }

  /// Looks up who reported the complaint behind a maintenance record and
  /// sends them a notification. Failures here (e.g. the complaint was
  /// since deleted) are swallowed — notifications are a best-effort side
  /// effect and must never block the primary maintenance CRUD action.
  Future<void> _notifyComplaintReporter({
    required String complaintId,
    required String title,
    required String message,
    required String type,
    required String relatedId,
  }) async {
    try {
      final complaint = await _complaintService.fetchComplaintById(complaintId);
      await _notificationService.notify(
        title: title,
        message: message,
        type: type,
        userId: complaint.reportedBy,
        relatedId: relatedId,
      );
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }

  // -----------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------

  /// Deletes a maintenance record. The caller is responsible for
  /// showing a confirmation dialog before calling this.
  Future<void> deleteMaintenance(String maintenanceId) async {
    try {
      await _maintenanceRef.doc(maintenanceId).delete();
    } on FirebaseException catch (e) {
      throw MaintenanceException(_mapFirebaseError(e));
    } catch (_) {
      throw const MaintenanceException('Could not delete the maintenance record. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Error mapping
  // -----------------------------------------------------------------

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'not-found':
        return 'This maintenance record no longer exists.';
      case 'failed-precondition':
        return 'The server needs a moment to prepare this query. Please try again shortly.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}