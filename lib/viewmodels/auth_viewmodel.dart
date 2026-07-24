import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_services.dart';

/// The various states the authentication flow can be in.
///
/// Consumed by the splash screen and route guards to decide whether to
/// show the login screen or route straight to a role-based dashboard.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// The ViewModel for the entire authentication module (login, signup,
/// forgot password, logout, and session restoration).
///
/// Owns all UI-facing state (loading flags, error messages, the current
/// [UserModel]) and delegates every Firebase operation to [AuthService].
/// Screens interact with this class exclusively through [Provider] /
/// [Consumer] — no Firebase calls are ever made directly from the UI.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel({AuthService? authService}) : _authService = authService ?? AuthService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = true;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void toggleRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Auto login / session restoration
  // -----------------------------------------------------------------

  /// Attempts to restore a previous session on app start.
  ///
  /// Called once by the splash screen. If a Firebase user is already
  /// signed in AND the last session opted in to "Remember Me", their
  /// profile is fetched and [status] becomes [AuthStatus.authenticated].
  /// Otherwise the user is signed out (if needed) and routed to login.
  Future<void> tryAutoLogin() async {
    _setLoading(true);
    try {
      final firebaseUser = _authService.currentFirebaseUser;
      final remembered = await _authService.hasRememberedSession();

      if (firebaseUser != null && remembered) {
        _currentUser = await _authService.fetchUserData(firebaseUser.uid);
        _status = AuthStatus.authenticated;
      } else {
        if (firebaseUser != null && !remembered) {
          await _authService.signOut();
        }
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------------
  // Login
  // -----------------------------------------------------------------

  /// Logs the user in with [email]/[password]. Returns `true` on
  /// success so the calling screen can navigate; on failure,
  /// [errorMessage] is populated and `false` is returned.
  Future<bool> login({required String email, required String password}) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      final user = await _authService.signIn(email: email, password: password);
      await _authService.saveSession(uid: user.uid, role: user.role, rememberMe: _rememberMe);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------------
  // Signup
  // -----------------------------------------------------------------

  /// Registers a new account and Firestore profile. Returns `true` on
  /// success so the calling screen can navigate to the correct
  /// role-based dashboard.
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      final user = await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        department: department,
      );
      await _authService.saveSession(uid: user.uid, role: user.role, rememberMe: true);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------------
  // Forgot password
  // -----------------------------------------------------------------

  /// Sends a password-reset email. Returns `true` on success.
  Future<bool> forgotPassword(String email) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------------
  // Profile refresh (used by dashboard pull-to-refresh)
  // -----------------------------------------------------------------

  /// Re-fetches the current user's Firestore profile without affecting
  /// the overall [status]. Intended for dashboard "pull to refresh"
  /// gestures so name/role/department/profile image stay current.
  /// Silently keeps the existing [currentUser] if the refresh fails
  /// (e.g. transient network issue) so the dashboard doesn't flicker
  /// into an error state on every failed refresh.
  Future<void> refreshUserProfile() async {
    try {
      final refreshed = await _authService.refreshCurrentUserProfile();
      _currentUser = refreshed;
      notifyListeners();
    } catch (_) {
      // Keep showing the last known profile; the pull-to-refresh
      // indicator simply completes without visible error.
    }
  }

  // -----------------------------------------------------------------
  // Logout
  // -----------------------------------------------------------------

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
    }
  }
}
