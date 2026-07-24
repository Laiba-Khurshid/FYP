import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project/models/audit_log_model.dart';

import 'package:project/core/utils/app_constants.dart';
/// A custom, UI-friendly exception thrown by [AuditService].
class AuditException implements Exception {
  final String message;
  const AuditException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates all Cloud Firestore logic for the Audit History module.
///
/// This is the ONLY class in the app allowed to talk directly to the
/// `audit_logs` Firestore collection. Besides serving the Audit History
/// screen (via [AuditViewModel]), the Asset, Complaint, Maintenance, and
/// Profile services each hold a write-only instance of this class purely
/// to call [record] whenever a triggering action happens — they never
/// touch Firestore's `audit_logs` collection directly.
class AuditService {
  final FirebaseFirestore _firestore;

  AuditService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _auditLogsRef =>
      _firestore.collection(AppConstants.auditLogsCollection);

  // -----------------------------------------------------------------
  // Create (used internally by other services)
  // -----------------------------------------------------------------

  /// Records a new audit log entry.
  Future<void> record({
    required String userId,
    required String userName,
    required String role,
    required String action,
    required String module,
    required String referenceId,
  }) async {
    try {
      final docRef = _auditLogsRef.doc();
      final log = AuditLogModel(
        logId: docRef.id,
        userId: userId,
        userName: userName,
        role: role,
        action: action,
        module: module,
        referenceId: referenceId,
        timestamp: DateTime.now(),
      );
      await docRef.set(log.toMap());
    } catch (_) {
      // Audit logging is a best-effort side effect of a CRUD action. A
      // failure here must never block or roll back the primary action,
      // so it's swallowed rather than rethrown.
    }
  }

  // -----------------------------------------------------------------
  // Read (stream)
  // -----------------------------------------------------------------

  /// Streams every audit log entry, newest first. Audit History is an
  /// administrative view — only Admin should be routed to this screen
  /// (enforced by the UI/routing layer, consistent with how other
  /// admin-only screens in this app are gated).
  Stream<List<AuditLogModel>> streamAuditLogs() {
    return _auditLogsRef
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AuditLogModel.fromDocument).toList());
  }
}