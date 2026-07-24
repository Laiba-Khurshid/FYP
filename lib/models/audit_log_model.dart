import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single audit log entry as stored in the `audit_logs`
/// Firestore collection.
///
/// Audit logs are an append-only record of important system activity
/// (assets, complaints, maintenance, and profile changes) — created
/// automatically by [AuditService] on behalf of the module that
/// triggered the action, never edited or deleted by users.
class AuditLogModel {
  final String logId;
  final String userId;
  final String userName;
  final String role;
  final String action;
  final String module;
  final String referenceId;
  final DateTime timestamp;

  const AuditLogModel({
    required this.logId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.action,
    required this.module,
    required this.referenceId,
    required this.timestamp,
  });

  /// Builds an [AuditLogModel] from a Firestore document map.
  factory AuditLogModel.fromMap(Map<String, dynamic> map, String logId) {
    return AuditLogModel(
      logId: logId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      role: map['role'] as String? ?? '',
      action: map['action'] as String? ?? '',
      module: map['module'] as String? ?? '',
      referenceId: map['referenceId'] as String? ?? '',
      timestamp: _parseDate(map['timestamp']),
    );
  }

  /// Builds an [AuditLogModel] directly from a [DocumentSnapshot].
  factory AuditLogModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Audit log document ${doc.id} has no data.');
    }
    return AuditLogModel.fromMap(data, doc.id);
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Converts this [AuditLogModel] into a Firestore-writable map.
  ///
  /// [logId] is intentionally excluded since it is used as the document
  /// ID rather than stored as a field.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'role': role,
      'action': action,
      'module': module,
      'referenceId': referenceId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  @override
  bool operator ==(Object other) => other is AuditLogModel && other.logId == logId;

  @override
  int get hashCode => logId.hashCode;

  @override
  String toString() => 'AuditLogModel(logId: $logId, action: $action, module: $module)';
}