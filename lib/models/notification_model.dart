import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single notification as stored in the `notifications`
/// Firestore collection.
///
/// A notification is either targeted at one specific person
/// ([userId] set, [role] empty) or broadcast to everyone holding a role
/// (e.g. "whichever HOD is on duty") — in which case [userId] is left
/// empty and [role] holds the target role. [relatedId] points back at
/// the complaint or maintenance record that triggered it, so tapping a
/// notification can deep-link straight to it.
class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final String userId;
  final String role;
  final String relatedId;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.userId,
    required this.role,
    required this.relatedId,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  /// Builds a [NotificationModel] from a Firestore document map.
  factory NotificationModel.fromMap(Map<String, dynamic> map, String notificationId) {
    return NotificationModel(
      notificationId: notificationId,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      role: map['role'] as String? ?? '',
      relatedId: map['relatedId'] as String? ?? '',
      type: map['type'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  /// Builds a [NotificationModel] directly from a [DocumentSnapshot].
  factory NotificationModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Notification document ${doc.id} has no data.');
    }
    return NotificationModel.fromMap(data, doc.id);
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Converts this [NotificationModel] into a Firestore-writable map.
  ///
  /// [notificationId] is intentionally excluded since it is used as the
  /// document ID rather than stored as a field.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'userId': userId,
      'role': role,
      'relatedId': relatedId,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      title: title,
      message: message,
      userId: userId,
      role: role,
      relatedId: relatedId,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is NotificationModel && other.notificationId == notificationId;

  @override
  int get hashCode => notificationId.hashCode;

  @override
  String toString() => 'NotificationModel(notificationId: $notificationId, title: $title, isRead: $isRead)';
}