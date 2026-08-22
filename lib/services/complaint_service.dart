import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:project/models/complaint_model.dart';

import 'package:project/core/utils/app_constants.dart';

import 'package:project/services/audit_service.dart';
import 'package:project/services/notification_service.dart';

class ComplaintException implements Exception {
  final String message;
  const ComplaintException(this.message);

  @override
  String toString() => message;
}

class ComplaintService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final NotificationService _notificationService;
  final AuditService _auditService;

  // ================================================================
  // ESCALATION TIMELINE (DAYS)
  // ================================================================
  static const int escalationDaysToHOD = 10;
  static const int escalationDaysToVP = 20;
  static const int escalationDaysToPrincipal = 30;

  Timer? _escalationTimer;

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

  // ================================================================
  // START ESCALATION MONITORING
  // ================================================================
  void startEscalationMonitoring() {
    _escalationTimer?.cancel();
    _escalationTimer = Timer.periodic(
      const Duration(minutes: 1), // Testing: 1 minute (production mein hours/ days karein)
          (_) => _checkAndEscalateComplaints(),
    );
  }

  Future<void> _checkAndEscalateComplaints() async {
    try {

      final snapshot = await _complaintsRef
          .where('status', isEqualTo: AppConstants.statusPending)
          .get();

      if (snapshot.docs.isEmpty) return;

      for (final doc in snapshot.docs) {
        final complaint = ComplaintModel.fromDocument(doc);
        await _checkAndEscalateSingleComplaint(complaint);
      }
    } catch (e) {
      print('Escalation check error: $e');
    }
  }

  Future<void> _checkAndEscalateSingleComplaint(ComplaintModel complaint) async {
    final now = DateTime.now();
    final daysSinceCreation = now.difference(complaint.createdAt).inDays;

    // ================================================================
    // ESCALATION LOGIC
    // ================================================================

    // 30+ days → Principal (Final)
    if (daysSinceCreation >= escalationDaysToPrincipal &&
        complaint.escalationLevel < AppConstants.escalationLevelPrincipal) {
      await _escalateComplaint(complaint, AppConstants.rolePrincipal);
      return;
    }

    // 20+ days → VP
    if (daysSinceCreation >= escalationDaysToVP &&
        complaint.escalationLevel < AppConstants.escalationLevelVicePrincipal) {
      await _escalateComplaint(complaint, AppConstants.roleVicePrincipal);
      return;
    }

    // 10+ days → HOD
    if (daysSinceCreation >= escalationDaysToHOD &&
        complaint.escalationLevel < AppConstants.escalationLevelVicePrincipal) {
      await _escalateComplaint(complaint, AppConstants.roleHOD);
      return;
    }
  }

  // ================================================================
  // PRIVATE ESCALATION METHOD
  // ================================================================
  Future<void> _escalateComplaint(ComplaintModel complaint, String nextAssignee) async {
    final nextLevel = complaint.escalationLevel + 1;

    try {
      await _complaintsRef.doc(complaint.complaintId).update({
        'status': AppConstants.statusEscalated,
        'escalationLevel': nextLevel,
        'assignedTo': nextAssignee,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // ============================================================
      // NOTIFICATION: Escalated User ko
      // ============================================================
      await _notificationService.notify(
        title: 'Complaint Escalated to You',
        message: '${complaint.assetName} in ${complaint.labName} has been escalated to you.',
        type: AppConstants.notificationTypeComplaintEscalated,
        role: nextAssignee,
        relatedId: complaint.complaintId,
      );

      // ============================================================
      // NOTIFICATION: Reporter ko
      // ============================================================
      await _notificationService.notify(
        title: 'Complaint Escalated',
        message: 'Your complaint about ${complaint.assetName} has been escalated for further review.',
        type: AppConstants.notificationTypeComplaintEscalated,
        userId: complaint.reportedBy,
        relatedId: complaint.complaintId,
      );

      // ============================================================
      // AUDIT LOG
      // ============================================================
      await _auditService.record(
        userId: 'system',
        userName: 'System',
        role: 'system',
        action: AppConstants.auditActionComplaintEscalated,
        module: AppConstants.auditModuleComplaint,
        referenceId: complaint.complaintId,
      );

      print('✅ Complaint ${complaint.complaintId} escalated to $nextAssignee');
    } catch (e) {
      print('❌ Escalation failed for ${complaint.complaintId}: $e');
    }
  }

  // ================================================================
  // PUBLIC ESCALATION METHOD (Manual)
  // ================================================================
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
  // Read (stream) — role-based visibility
  // -----------------------------------------------------------------

  Stream<List<ComplaintModel>> streamComplaints({required String role, required String uid}) {
    Query<Map<String, dynamic>> query = _complaintsRef;
    bool sortClientSide = false;

    switch (role) {
      case AppConstants.roleAdmin:
      case AppConstants.roleHOD:
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
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      final docRef = _complaintsRef.doc();
      final now = DateTime.now();

      String? imageUrl;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        imageUrl = await _uploadImage(bytes, docRef.id);
      } else if (imageBytes != null) {
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
        assignedTo: AppConstants.roleAdmin,
        escalationLevel: AppConstants.escalationLevelNone,
        imageUrl: imageUrl,
      );

      await docRef.set(complaint.toMap());

      // ============================================================
      // NOTIFICATION 1: Asset Manager ko
      // ============================================================
      await _notificationService.notify(
        title: 'New Complaint Filed',
        message: '${complaint.assetName} in ${complaint.labName} has a new complaint.',
        type: AppConstants.notificationTypeComplaintSubmitted,
        role: AppConstants.roleAdmin,
        relatedId: complaint.complaintId,
      );

      // ============================================================
      // NOTIFICATION 2: Student/Reporter ko
      // ============================================================
      await _notificationService.notify(
        title: 'Complaint Submitted Successfully',
        message: 'Your complaint about ${complaint.assetName} has been submitted and is pending review.',
        type: AppConstants.notificationTypeComplaintSubmitted,
        userId: reportedBy,
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