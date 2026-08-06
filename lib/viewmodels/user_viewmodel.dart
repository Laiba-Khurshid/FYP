import 'dart:async';

import 'package:flutter/material.dart';

import 'package:project/models/user_model.dart';
import 'package:project/services/user_service.dart';

/// The ViewModel for the User Management module (Admin-only).
///
/// Owns all UI-facing state and delegates every Firestore operation to
/// [UserService]. Screens interact with this class exclusively through
/// [Provider] / [Consumer] — no Firebase calls are ever made directly
/// from the UI.
class UserViewModel extends ChangeNotifier {
  final UserService _userService;

  UserViewModel({UserService? userService})
      : _userService = userService ?? UserService();

  // -----------------------------------------------------------------
  // State
  // -----------------------------------------------------------------

  StreamSubscription<List<UserModel>>? _usersSubscription;
  StreamSubscription<List<UserModel>>? _pendingUsersSubscription;

  List<UserModel> _allUsers = [];
  List<UserModel> _pendingUsers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get pendingUsers => _pendingUsers;
  bool get hasPendingUsers => _pendingUsers.isNotEmpty;
  int get pendingUsersCount => _pendingUsers.length;

  // -----------------------------------------------------------------
  // Stream subscriptions
  // -----------------------------------------------------------------

  /// Subscribes to all users stream.
  void subscribeToAllUsers() {
    _isLoading = true;
    _usersSubscription?.cancel();
    _usersSubscription = _userService.streamAllUsers().listen(
          (users) {
        _allUsers = users;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        if (error is UserException) {
          _errorMessage = error.message;
        } else {
          _errorMessage = 'Could not load users. Please check your internet connection.';
        }
        notifyListeners();
      },
    );
  }

  /// Subscribes to pending users stream (Student/Teacher pending approval).
  void subscribeToPendingUsers() {
    _pendingUsersSubscription?.cancel();
    _pendingUsersSubscription = _userService.streamPendingUsers().listen(
          (users) {
        _pendingUsers = users;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        if (error is UserException) {
          _errorMessage = error.message;
        } else {
          _errorMessage = 'Could not load pending users. Please check your internet connection.';
        }
        notifyListeners();
      },
    );
  }

  /// Subscribes to both all users and pending users streams.
  void subscribe() {
    subscribeToAllUsers();
    subscribeToPendingUsers();
  }

  /// Refreshes all data (pull-to-refresh).
  Future<void> refreshUsers() async {
    subscribe();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _pendingUsersSubscription?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Admin Actions
  // -----------------------------------------------------------------

  /// Approves a pending user.
  Future<bool> approveUser(String uid) async {
    _errorMessage = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      await _userService.approveUser(uid);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on UserException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Could not approve the user. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Rejects a pending user.
  Future<bool> rejectUser(String uid) async {
    _errorMessage = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      await _userService.rejectUser(uid);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on UserException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Could not reject the user. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Resets a rejected user back to pending status.
  Future<bool> resetUserToPending(String uid) async {
    _errorMessage = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      await _userService.resetUserToPending(uid);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on UserException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Could not reset the user status. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a user (Admin tool).
  Future<bool> deleteUser(String uid) async {
    _errorMessage = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      await _userService.deleteUser(uid);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on UserException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Could not delete the user. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Checks if there are any pending users.
  Future<bool> checkPendingUsers() async {
    try {
      return await _userService.hasPendingUsers();
    } catch (_) {
      return false;
    }
  }

  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Gets a user by ID from the cached list.
  UserModel? getUserById(String uid) {
    try {
      return _allUsers.firstWhere((user) => user.uid == uid);
    } catch (_) {
      return null;
    }
  }

  /// Gets pending users count.
  int getPendingCount() {
    return _pendingUsers.length;
  }
}