import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/models/user_model.dart';
import 'package:project/core/utils/app_constants.dart';
/// A custom, UI-friendly exception thrown by [AuthService].
///
/// Wraps the raw [FirebaseAuthException] (or any other failure) into a
/// single human-readable [message] so the ViewModel/UI layer never has
/// to interpret Firebase error codes directly.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates all Firebase Authentication, Firestore user-document, and
/// local session logic for AssetFlow.
///
/// This is the ONLY class in the app allowed to talk directly to
/// [FirebaseAuth] and the `users` Firestore collection for
/// authentication purposes. The UI layer never touches Firebase
/// directly — it goes through [AuthViewModel], which in turn calls this
/// service, keeping the project's MVVM separation intact.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// The currently authenticated Firebase user, if any.
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Emits whenever the Firebase authentication state changes
  /// (sign-in, sign-out, token refresh on a different user).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  // -----------------------------------------------------------------
  // Sign up
  // -----------------------------------------------------------------

  /// Creates a new Firebase Authentication account and a matching
  /// `users/{uid}` Firestore document, then returns the resulting
  /// [UserModel].
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException('Account creation failed. Please try again.');
      }

      await credential.user?.updateDisplayName(fullName.trim());

      final userModel = UserModel(
        uid: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        role: role,
        department: department,
        createdAt: DateTime.now(),
        profileImage: null,
      );

      await _usersRef.doc(uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthException(
        'Something went wrong while creating your account. Please try again.',
      );
    }
  }

  // -----------------------------------------------------------------
  // Login
  // -----------------------------------------------------------------

  /// Signs the user in with email and password, then loads their
  /// [UserModel] from Firestore.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException('Login failed. Please try again.');
      }

      return await fetchUserData(uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthException('Unable to log in. Please try again.');
    }
  }

  /// Fetches the `users/{uid}` document for an already-authenticated
  /// Firebase user (used both after login and for auto-login).
  Future<UserModel> fetchUserData(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) {
        throw const AuthException(
          'No profile was found for this account. Please contact your administrator.',
        );
      }
      return UserModel.fromDocument(doc);
    } on FirebaseException {
      throw const AuthException(
        'Could not reach the server. Please check your internet connection.',
      );
    }
  }

  /// Re-fetches the Firestore profile of whichever user is currently
  /// signed in to Firebase. Used by dashboard "pull to refresh" so the
  /// UI always reflects the latest name/role/department/profile image
  /// without requiring a full logout/login cycle.
  Future<UserModel> refreshCurrentUserProfile() async {
    final uid = currentFirebaseUser?.uid;
    if (uid == null) {
      throw const AuthException('No signed-in user to refresh.');
    }
    return fetchUserData(uid);
  }

  // -----------------------------------------------------------------
  // Forgot password
  // -----------------------------------------------------------------

  /// Sends a Firebase password-reset email to [email].
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthException(
        'Could not send the reset email. Please try again.',
      );
    }
  }

  // -----------------------------------------------------------------
  // Logout
  // -----------------------------------------------------------------

  /// Signs the current user out of Firebase and clears the local
  /// "remember me" session flag.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await clearSession();
  }

  // -----------------------------------------------------------------
  // Local session ("Remember Me") persistence
  // -----------------------------------------------------------------

  /// Persists a lightweight local session flag so [tryAutoLogin] in the
  /// ViewModel knows whether the last session opted in to "Remember Me".
  /// Firebase itself already persists the auth token between app
  /// launches; this flag lets us decide whether auto-login should be
  /// attempted at all versus always forcing a fresh login.
  Future<void> saveSession({required String uid, required String role, required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyIsLoggedIn, rememberMe);
    await prefs.setString(AppConstants.prefKeyUserId, uid);
    await prefs.setString(AppConstants.prefKeyUserRole, role);
  }

  /// Returns `true` if the last login was performed with "Remember Me"
  /// enabled and a Firebase session still exists.
  Future<bool> hasRememberedSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefKeyIsLoggedIn) ?? false;
  }

  /// Clears the locally persisted session flag (called on logout).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefKeyIsLoggedIn);
    await prefs.remove(AppConstants.prefKeyUserId);
    await prefs.remove(AppConstants.prefKeyUserRole);
  }

  // -----------------------------------------------------------------
  // Error mapping
  // -----------------------------------------------------------------

  /// Converts a [FirebaseAuthException] into a friendly, user-facing
  /// message so the UI never needs to know Firebase error codes.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact your administrator.';
      case 'user-not-found':
        return 'No account was found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is currently disabled. Please contact your administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}
