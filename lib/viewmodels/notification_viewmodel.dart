import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationViewModel({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  StreamSubscription<List<NotificationModel>>? _subscription;
  String? _subscribedUid;
  String? _subscribedRole;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ================================================================
  // UNREAD COUNT - ADDED FOR BADGE
  // ================================================================
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Subscribes to the notifications visible to the current user. Safe
  /// to call on every build — it only re-subscribes when [uid] or
  /// [role] actually changes (e.g. after login).
  void subscribe({required String uid, required String role}) {
    if (_subscribedUid == uid && _subscribedRole == role && _subscription != null) {
      return;
    }
    _subscribedUid = uid;
    _subscribedRole = role;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _notificationService.streamNotifications(uid: uid, role: role).listen(
          (notifications) {
        _notifications = notifications;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error is FirebaseException
            ? (error.message ?? 'Firestore error (${error.code}). Please try again.')
            : 'Could not load notifications. Please check your internet connection.';
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    try {
      await _notificationService.markAsRead(notification.notificationId);
    } on NotificationException {
      // Non-critical — leave the item as unread in the UI on failure.
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead(_notifications);
    } on NotificationException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } on NotificationException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}