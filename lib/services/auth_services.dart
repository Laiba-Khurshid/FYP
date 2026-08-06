import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project/models/user_model.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/services/notification_service.dart';

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
  final NotificationService _notificationService;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService();

  /// The currently authenticated Firebase user, if any.
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Emits whenever the Firebase authentication state changes
  /// (sign-in, sign-out, token refresh on a different user).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _authorizedUsersRef =>
      _firestore.collection(AppConstants.authenticatedUsersCollection);

  // -----------------------------------------------------------------
  // Sign up
  // -----------------------------------------------------------------

  /// Creates a new Firebase Authentication account and a matching
  /// `users/{uid}` Firestore document, then returns the resulting
  /// [UserModel].
  ///
  /// Only **Student** (via [rollNumber]) and **Teacher** (via
  /// [employeeId]) registrations are gated: the identifier must exist in
  /// the `authenticated_users` allow-list, or registration is refused
  /// with "You are not authorized to register," and the new account
  /// starts with `verificationStatus` = Pending until an Admin approves
  /// it (via the Verify Users screen). HOD, Vice Principal, Principal,
  /// and Admin accounts don't require a roll number/employee ID or an
  /// allow-list entry — they're created with `verificationStatus` =
  /// Approved immediately and can log in right away.
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String department,
    String? rollNumber,
    String? employeeId,
  }) async {
    try {
      final requiresApproval = role == AppConstants.roleStudent || role == AppConstants.roleTeacher;
      final isStudent = role == AppConstants.roleStudent;
      String? identifier;
      DocumentSnapshot<Map<String, dynamic>>? authorizedDoc;

      if (requiresApproval) {
        identifier = isStudent ? rollNumber?.trim() : employeeId?.trim();

        if (identifier == null || identifier.isEmpty) {
          throw AuthException(
            isStudent ? 'Roll number is required to register.' : 'Employee ID is required to register.',
          );
        }

        final authorizedQuery = await _authorizedUsersRef
            .where(isStudent ? 'rollNumber' : 'employeeId', isEqualTo: identifier)
            .where('role', isEqualTo: role)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (authorizedQuery.docs.isEmpty) {
          throw const AuthException('You are not authorized to register.');
        }
        authorizedDoc = authorizedQuery.docs.first;
      }

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
        rollNumber: isStudent ? identifier : null,
        employeeId: (requiresApproval && !isStudent) ? identifier : null,
        verificationStatus: requiresApproval ? AppConstants.verificationPending : AppConstants.verificationApproved,
      );

      await _usersRef.doc(uid).set(userModel.toMap());

      // Link the authorized-users record to the account that used it,
      // so it can't be reused for a second registration.
      if (authorizedDoc != null) {
        await authorizedDoc.reference.update({'uid': uid});
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on AuthException {
      rethrow;
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
  ///
  /// If the account's `verificationStatus` is not Approved, the sign-in
  /// is reversed immediately (the user is signed back out) and a clear
  /// explanation is thrown — Pending or Rejected accounts must never
  /// reach the rest of the app.
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

      final user = await fetchUserData(uid);

      if (user.isPending) {
        await _firebaseAuth.signOut();
        throw const AuthException(
          'Your account is pending admin approval. Please check back soon.',
        );
      }
      if (user.isRejected) {
        await _firebaseAuth.signOut();
        throw const AuthException(
          'Your registration was not approved. Please contact your administrator.',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on AuthException {
      rethrow;
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

  /// Adds a new entry to the `authenticated_users` allow-list, so
  /// someone with this [rollNumber] (Students) or [employeeId] (every
  /// other role) is permitted to register. Used by the Admin-only
  /// "Add Authorized User" action on the Verify Users screen.
  Future<void> addAuthorizedUser({
    String? rollNumber,
    String? employeeId,
    required String role,
    required String department,
  }) async {
    final isStudent = role == AppConstants.roleStudent;
    final identifier = isStudent ? rollNumber?.trim() : employeeId?.trim();
    if (identifier == null || identifier.isEmpty) {
      throw const AuthException('An identifier is required.');
    }
    try {
      await _authorizedUsersRef.add({
        'uid': '',
        'rollNumber': isStudent ? identifier : null,
        'employeeId': isStudent ? null : identifier,
        'role': role,
        'department': department,
        'isActive': true,
      });
    } on FirebaseException catch (e) {
      throw AuthException(e.message ?? 'Could not add the authorized user.');
    }
  }

  // -----------------------------------------------------------------
  // User verification (Admin)
  // -----------------------------------------------------------------

  /// Streams every account currently awaiting approval, newest first.
  Stream<List<UserModel>> streamPendingUsers() {
    return _usersRef
        .where('verificationStatus', isEqualTo: AppConstants.verificationPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserModel.fromDocument).toList());
  }

  /// ✅ FIX: Added this method – streams approved users, newest first.
  Stream<List<UserModel>> streamApprovedUsers() {
    return _usersRef
        .where('verificationStatus', isEqualTo: AppConstants.verificationApproved)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserModel.fromDocument).toList());
  }

  /// Approves a pending account, allowing it to log in.
  Future<void> approveUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({'verificationStatus': AppConstants.verificationApproved});
      await _notificationService.notify(
        title: 'Account Approved',
        message: 'Your account has been approved. You can now log in.',
        type: AppConstants.notificationTypeAccountApproved,
        userId: uid,
        relatedId: uid,
      );
    } on FirebaseException catch (e) {
      throw AuthException(e.message ?? 'Could not approve this account.');
    }
  }

  /// Rejects a pending account, permanently blocking it from logging in.
  Future<void> rejectUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({'verificationStatus': AppConstants.verificationRejected});
      await _notificationService.notify(
        title: 'Registration Not Approved',
        message: 'Your registration was not approved. Please contact your administrator.',
        type: AppConstants.notificationTypeAccountRejected,
        userId: uid,
        relatedId: uid,
      );
    } on FirebaseException catch (e) {
      throw AuthException(e.message ?? 'Could not reject this account.');
    }
  }

  // -----------------------------------------------------------------
  // Forgot password
  // -----------------------------------------------------------------


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

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await clearSession();
  }

  // -----------------------------------------------------------------
  // Local session ("Remember Me") persistence
  // -----------------------------------------------------------------

  Future<void> saveSession({required String uid, required String role, required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyIsLoggedIn, rememberMe);
    await prefs.setString(AppConstants.prefKeyUserId, uid);
    await prefs.setString(AppConstants.prefKeyUserRole, role);
  }


  Future<bool> hasRememberedSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefKeyIsLoggedIn) ?? false;
  }


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