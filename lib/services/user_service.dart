import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project/models/user_model.dart';

/// A custom, UI-friendly exception thrown by [UserService].
class UserException implements Exception {
  final String message;
  const UserException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates all Cloud Firestore logic for the User Management module.
class UserService {
  final FirebaseFirestore _firestore;

  // ================================================================
  // CONSTANTS (LOCALLY DEFINED - APP_CONSTANTS PAR DEPEND NAHI)
  // ================================================================
  static const String _usersCollection = 'users';
  static const String _roleStudent = 'student';
  static const String _roleTeacher = 'teacher';
  static const String _userStatusPending = 'pending';
  static const String _userStatusApproved = 'approved';
  static const String _userStatusRejected = 'rejected';

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  // -----------------------------------------------------------------
  // Read
  // -----------------------------------------------------------------

  /// Fetches a single user by their [uid].
  Future<UserModel> getUserById(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) {
        throw const UserException('User not found.');
      }
      return UserModel.fromDocument(doc);
    } on FirebaseException {
      throw const UserException(
        'Could not reach the server. Please check your internet connection.',
      );
    }
  }

  /// Streams all users in the department, newest first.
  Stream<List<UserModel>> streamAllUsers() {
    return _usersRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(UserModel.fromDocument).toList(),
    );
  }

  /// Streams only pending (unapproved) users — Student and Teacher
  /// accounts that were created but not yet verified by an Admin.
  Stream<List<UserModel>> streamPendingUsers() {
    return _usersRef
        .where('status', isEqualTo: _userStatusPending)
        .where('role', whereIn: [
      _roleStudent,
      _roleTeacher,
    ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserModel.fromDocument).toList());
  }

  // -----------------------------------------------------------------
  // Update (Admin-only operations)
  // -----------------------------------------------------------------

  /// Approves a pending user account (sets status to Approved).
  Future<void> approveUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'status': _userStatusApproved,
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw UserException(_mapFirebaseError(e));
    } catch (_) {
      throw const UserException('Could not approve the user. Please try again.');
    }
  }

  /// Rejects a pending user account (sets status to Rejected).
  Future<void> rejectUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'status': _userStatusRejected,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw UserException(_mapFirebaseError(e));
    } catch (_) {
      throw const UserException('Could not reject the user. Please try again.');
    }
  }

  /// Resets a pending user back to Pending status.
  Future<void> resetUserToPending(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'status': _userStatusPending,
        'rejectedAt': null,
      });
    } on FirebaseException catch (e) {
      throw UserException(_mapFirebaseError(e));
    } catch (_) {
      throw const UserException('Could not reset the user status. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Admin Tools
  // -----------------------------------------------------------------

  /// Checks whether any users with the pending status currently exist.
  Future<bool> hasPendingUsers() async {
    try {
      final snapshot = await _usersRef
          .where('status', isEqualTo: _userStatusPending)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // -----------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------

  /// Deletes a user from Firestore entirely.
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
    } on FirebaseException catch (e) {
      throw UserException(_mapFirebaseError(e));
    } catch (_) {
      throw const UserException('Could not delete the user. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Error mapping
  // -----------------------------------------------------------------

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'not-found':
        return 'This user no longer exists.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}