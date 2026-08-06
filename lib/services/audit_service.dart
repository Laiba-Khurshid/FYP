import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project/models/audit_log_model.dart';

import 'package:project/core/utils/app_constants.dart';

class AuditException implements Exception {
  final String message;
  const AuditException(this.message);

  @override
  String toString() => message;
}


class AuditService {
  final FirebaseFirestore _firestore;

  AuditService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _auditLogsRef =>
      _firestore.collection(AppConstants.auditLogsCollection);


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


  Stream<List<AuditLogModel>> streamAuditLogs() {
    return _auditLogsRef
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AuditLogModel.fromDocument).toList());
  }
}