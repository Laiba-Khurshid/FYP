import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:project/models/user_model.dart';

import 'package:project/core/utils/app_constants.dart';

import 'package:project/services/audit_service.dart';
/// A custom, UI-friendly exception thrown by [ProfileService].
class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates all Cloud Firestore and Firebase Storage logic for the
/// Profile Management module.
///
/// Reuses the existing `users` collection (the same one Authentication
/// writes to) — this is simply a second, focused entry point for a user
/// updating their own record. Only `fullName`, `phoneNumber`, and
/// `profileImage` are ever written here; `email`, `role`, and
/// `department` remain read-only, enforced by never accepting them as
/// parameters in [updateProfile].
///
/// Also holds an [AuditService] so every successful profile update
/// automatically writes a "User Profile Updated" audit log entry.
class ProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AuditService _auditService;

  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    AuditService? auditService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auditService = auditService ?? AuditService();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Fetches the current profile for [uid] fresh from Firestore.
  Future<UserModel> fetchProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) {
        throw const ProfileException('Your profile could not be found.');
      }
      return UserModel.fromDocument(doc);
    } on FirebaseException {
      throw const ProfileException('Could not reach the server. Please check your internet connection.');
    }
  }

  /// Updates the editable fields of a user's profile: full name, phone
  /// number, and (optionally) a new profile picture. `email`, `role`,
  /// and `department` are never touched here.
  Future<UserModel> updateProfile({
    required UserModel existing,
    required String fullName,
    String? phoneNumber,
    File? newProfileImage,
    bool removeProfileImage = false,
  }) async {
    try {
      String? profileImage = existing.profileImage;

      if (newProfileImage != null) {
        profileImage = await _uploadProfileImage(newProfileImage, existing.uid);
      } else if (removeProfileImage) {
        profileImage = null;
      }

      final updated = existing.copyWith(
        fullName: fullName.trim(),
        phoneNumber: phoneNumber?.trim(),
        profileImage: profileImage,
      );

      // Only the editable fields are written, leaving email/role/
      // department untouched even though toMap() includes them (they
      // are simply re-written with their existing, unchanged values).
      await _usersRef.doc(existing.uid).update({
        'fullName': updated.fullName,
        'phoneNumber': updated.phoneNumber,
        'profileImage': updated.profileImage,
      });

      await _auditService.record(
        userId: existing.uid,
        userName: updated.fullName,
        role: existing.role,
        action: AppConstants.auditActionUserProfileUpdated,
        module: AppConstants.auditModuleProfile,
        referenceId: existing.uid,
      );

      return updated;
    } on FirebaseException catch (e) {
      throw ProfileException(e.message ?? 'Could not update your profile. Please try again.');
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw const ProfileException('Could not update your profile. Please try again.');
    }
  }

  Future<String> _uploadProfileImage(File imageFile, String uid) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      final uploadTask = await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException {
      throw const ProfileException('Could not upload your profile picture. Please try again.');
    }
  }
}