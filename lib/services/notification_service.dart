import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project/models/notification_model.dart';

import 'package:project/core/utils/app_constants.dart';

class NotificationException implements Exception {
  final String message;
  const NotificationException(this.message);

  @override
  String toString() => message;
}


class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection(AppConstants.notificationsCollection);

  // -----------------------------------------------------------------
  // Create (used internally by other services + directly for tests)
  // -----------------------------------------------------------------

  /// Creates a notification. Pass a specific [userId] to target one
  /// person, or leave [userId] empty and pass a [role] to broadcast to
  /// everyone holding that role (e.g. "whichever HOD is on duty").
  Future<void> notify({
    required String title,
    required String message,
    required String type,
    String userId = '',
    String role = '',
    String relatedId = '',
  }) async {
    try {
      final docRef = _notificationsRef.doc();
      final notification = NotificationModel(
        notificationId: docRef.id,
        title: title,
        message: message,
        userId: userId,
        role: role,
        relatedId: relatedId,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await docRef.set(notification.toMap());
    } catch (_) {
      // Notifications are a best-effort side effect of a CRUD action
      // (e.g. filing a complaint). A failure here must never block or
      // roll back the primary action, so it's swallowed rather than
      // rethrown.
    }
  }

  Stream<List<NotificationModel>> streamNotifications({required String uid, required String role}) {
    final personalStream = _notificationsRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map(NotificationModel.fromDocument).toList());

    final broadcastStream = _notificationsRef
        .where('role', isEqualTo: role)
        .where('userId', isEqualTo: '')
        .snapshots()
        .map((s) => s.docs.map(NotificationModel.fromDocument).toList());

    return _mergeStreams([personalStream, broadcastStream]);
  }

  Stream<List<NotificationModel>> _mergeStreams(List<Stream<List<NotificationModel>>> streams) {
    final latest = List<List<NotificationModel>>.filled(streams.length, const []);
    late final StreamController<List<NotificationModel>> controller;
    final subscriptions = <StreamSubscription>[];

    controller = StreamController<List<NotificationModel>>(
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
  // Update
  // -----------------------------------------------------------------

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } on FirebaseException catch (e) {
      throw NotificationException(e.message ?? 'Could not update the notification.');
    }
  }

  /// Marks every currently-unread notification in [notifications] as
  /// read using a single batched write.
  Future<void> markAllAsRead(List<NotificationModel> notifications) async {
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final notification in unread) {
        batch.update(_notificationsRef.doc(notification.notificationId), {'isRead': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw NotificationException(e.message ?? 'Could not update notifications.');
    }
  }

  // -----------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } on FirebaseException catch (e) {
      throw NotificationException(e.message ?? 'Could not delete the notification.');
    }
  }
}