import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:project/models/complaint_model.dart';

import 'package:project/core/utils/app_constants.dart';

import 'package:project/services/audit_service.dart';
import 'package:project/services/notification_service.dart';
/// A custom, UI-friendly exception thrown by [ComplaintService].
///
/// Wraps any underlying Firestore/Storage failure into a single
/// human-readable [message] so the ViewModel/UI layer never has to
/// interpret Firebase error codes directly.
class ComplaintException implements Exception {
  final String message;
  const ComplaintException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates all Cloud Firestore and Firebase Storage logic for the
/// Complaint Management module.
///
/// This is the ONLY class in the app allowed to talk directly to the
/// existing `complaints` collection or the complaint-images Storage
/// bucket. The UI layer never touches Firebase directly — it goes
/// through [ComplaintViewModel], which in turn calls this service,
/// keeping the project's MVVM separation intact.
///
/// Also holds a [NotificationService] and [AuditService] instance so
/// that filing, updating, resolving, and escalating a complaint
/// automatically generates the corresponding notification and audit log
/// entry — this is the module's only integration point with those two
/// modules.
class ComplaintService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final NotificationService _notificationService;
  final AuditService _auditService;

  ComplaintService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    NotificationService? notificationService,
    AuditService? auditService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _notificationService = notificationService ?? NotificationService(),
        _auditService = auditService ?? AuditService();

  CollectionReference<Map<String, dynamic>> get _complaintsRef =>
      _firestore.collection(AppConstants.complaintsCollection);

  // -----------------------------------------------------------------
  // Read (stream) — role-based visibility
  // -----------------------------------------------------------------

  /// Streams complaints visible to a user with the given [role] and
  /// [uid], newest first:
  ///
  /// - Admin, HOD: every complaint (full department visibility).
  /// - Vice Principal: only complaints at or above the Vice Principal
  ///   escalation level.
  /// - Principal: only complaints at the final (Principal) escalation
  ///   level.
  /// - Teacher, Student: only complaints they personally reported
  ///   (their own complaint history).
  ///
  /// Vice Principal/Principal filter with an inequality
  /// (`escalationLevel >=`) on a field other than `createdAt`. Firestore
  /// requires a composite index for `inequality filter + orderBy on a
  /// different field` — rather than depending on that index existing
  /// (and surfacing a raw `failed-precondition` exception if it
  /// doesn't), those two roles' queries intentionally omit the
  /// server-side `orderBy` and are sorted by `createdAt` client-side
  /// instead. Admin/HOD (no filter) and Teacher/Student (a single
  /// equality filter) are both automatically indexed by Firestore, so
  /// they keep the more efficient server-side ordering.
  Stream<List<ComplaintModel>> streamComplaints({required String role, required String uid}) {
    Query<Map<String, dynamic>> query = _complaintsRef;
    bool sortClientSide = false;

    switch (role) {
      case AppConstants.roleAdmin:
      case AppConstants.roleHOD:
      // Full visibility — no filter; safe to sort server-side.
        query = query.orderBy('createdAt', descending: true);
        break;
      case AppConstants.roleVicePrincipal:
        query = query.where(
          'escalationLevel',
          isGreaterThanOrEqualTo: AppConstants.escalationLevelVicePrincipal,
        );
        sortClientSide = true;
        break;
      case AppConstants.rolePrincipal:
        query = query.where(
          'escalationLevel',
          isGreaterThanOrEqualTo: AppConstants.escalationLevelPrincipal,
        );
        sortClientSide = true;
        break;
      default:
      // Teacher / Student: only their own submissions — a single
      // equality filter, safe to sort server-side.
        query = query.where('reportedBy', isEqualTo: uid).orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) {
      final complaints = snapshot.docs.map(ComplaintModel.fromDocument).toList();
      if (sortClientSide) {
        complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return complaints;
    });
  }

  /// Fetches a single complaint by [complaintId] (used to refresh a
  /// complaint's details after an update).
  Future<ComplaintModel> fetchComplaintById(String complaintId) async {
    try {
      final doc = await _complaintsRef.doc(complaintId).get();
      if (!doc.exists) {
        throw const ComplaintException('This complaint no longer exists.');
      }
      return ComplaintModel.fromDocument(doc);
    } on FirebaseException {
      throw const ComplaintException(
        'Could not reach the server. Please check your internet connection.',
      );
    }
  }

  // -----------------------------------------------------------------
  // Create
  // -----------------------------------------------------------------

  /// Files a new complaint against an asset.
  ///
  /// Defaults, per the module's design: `status` = Pending,
  /// `escalationLevel` = 0, `assignedTo` = HOD.
  Future<ComplaintModel> addComplaint({
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
    Uint8List? imageBytes,
  }) async {
    try {
      final docRef = _complaintsRef.doc();
      final now = DateTime.now();

      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await _uploadImage(imageBytes, docRef.id);
      }

      final complaint = ComplaintModel(
        complaintId: docRef.id,
        assetId: assetId,
        assetCode: assetCode,
        assetName: assetName,
        category: category,
        labName: labName,
        reportedBy: reportedBy,
        userRole: userRole,
        description: description.trim(),
        priority: priority,
        status: AppConstants.statusPending,
        createdAt: now,
        updatedAt: now,
        assignedTo: AppConstants.roleHOD,
        escalationLevel: AppConstants.escalationLevelNone,
        imageUrl: imageUrl,
      );

      await docRef.set(complaint.toMap());

      await _notificationService.notify(
        title: 'New Complaint Filed',
        message: '${complaint.assetName} in ${complaint.labName} has a new complaint.',
        type: AppConstants.notificationTypeComplaintSubmitted,
        role: AppConstants.roleHOD,
        relatedId: complaint.complaintId,
      );

      await _auditService.record(
        userId: reportedBy,
        userName: reportedByName,
        role: userRole,
        action: AppConstants.auditActionComplaintSubmitted,
        module: AppConstants.auditModuleComplaint,
        referenceId: complaint.complaintId,
      );

      return complaint;
    } on FirebaseException catch (e) {
      throw ComplaintException(_mapFirebaseError(e));
    } on ComplaintException {
      rethrow;
    } catch (_) {
      throw const ComplaintException('Could not submit the complaint. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Update
  // -----------------------------------------------------------------

  /// Updates a complaint's status (Pending / In Progress / Resolved).
  /// Use [escalateComplaint] to move a complaint to Escalated, since
  /// that also advances the escalation level and reassignment.
  ///
  /// Notifies the original reporter: "Complaint Resolved" if [status] is
  /// Resolved, otherwise a generic "Complaint Updated" notification.
  Future<void> updateStatus(
      ComplaintModel complaint,
      String status, {
        required String actorId,
        required String actorName,
        required String actorRole,
      }) async {
    try {
      await _complaintsRef.doc(complaint.complaintId).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final isResolved = status == AppConstants.statusResolved;
      await _notificationService.notify(
        title: isResolved ? 'Complaint Resolved' : 'Complaint Updated',
        message: isResolved
            ? 'Your complaint about ${complaint.assetName} has been resolved.'
            : 'Your complaint about ${complaint.assetName} is now "$status".',
        type: isResolved ? AppConstants.notificationTypeComplaintResolved : AppConstants.notificationTypeComplaintUpdated,
        userId: complaint.reportedBy,
        relatedId: complaint.complaintId,
      );

      await _auditService.record(
        userId: actorId,
        userName: actorName,
        role: actorRole,
        action: isResolved ? AppConstants.auditActionComplaintResolved : AppConstants.auditActionComplaintUpdated,
        module: AppConstants.auditModuleComplaint,
        referenceId: complaint.complaintId,
      );
    } on FirebaseException catch (e) {
      throw ComplaintException(_mapFirebaseError(e));
    }
  }

  /// Escalates a complaint one level up the chain:
  /// 0 (HOD) → 1 (Vice Principal) → 2 (Principal, final).
  ///
  /// Sets `status` to Escalated and reassigns `assignedTo` to the next
  /// role in the chain. No-ops if already at the final escalation level.
  Future<void> escalateComplaint(
      ComplaintModel complaint, {
        required String actorId,
        required String actorName,
        required String actorRole,
      }) async {
    if (complaint.escalationLevel >= AppConstants.escalationLevelPrincipal) return;

    final nextLevel = complaint.escalationLevel + 1;
    final nextAssignee = nextLevel == AppConstants.escalationLevelVicePrincipal
        ? AppConstants.roleVicePrincipal
        : AppConstants.rolePrincipal;

    try {
      await _complaintsRef.doc(complaint.complaintId).update({
        'status': AppConstants.statusEscalated,
        'escalationLevel': nextLevel,
        'assignedTo': nextAssignee,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await _notificationService.notify(
        title: 'Complaint Escalated to You',
        message: '${complaint.assetName} in ${complaint.labName} has been escalated to you.',
        type: AppConstants.notificationTypeComplaintEscalated,
        role: nextAssignee,
        relatedId: complaint.complaintId,
      );
      await _notificationService.notify(
        title: 'Complaint Escalated',
        message: 'Your complaint about ${complaint.assetName} has been escalated for further review.',
        type: AppConstants.notificationTypeComplaintEscalated,
        userId: complaint.reportedBy,
        relatedId: complaint.complaintId,
      );

      await _auditService.record(
        userId: actorId,
        userName: actorName,
        role: actorRole,
        action: AppConstants.auditActionComplaintEscalated,
        module: AppConstants.auditModuleComplaint,
        referenceId: complaint.complaintId,
      );
    } on FirebaseException catch (e) {
      throw ComplaintException(_mapFirebaseError(e));
    }
  }

  // -----------------------------------------------------------------
  // Firebase Storage helpers
  // -----------------------------------------------------------------

  Future<String> _uploadImage(Uint8List imageBytes, String complaintId) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.complaintImagesStoragePath)
          .child('$complaintId.jpg');
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException {
      throw const ComplaintException('Could not upload the complaint image. Please try again.');
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
        return 'This complaint no longer exists.';
      case 'failed-precondition':
        return 'The server needs a moment to prepare this query. Please try again shortly.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}