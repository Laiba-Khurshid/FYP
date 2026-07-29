import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

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

  /// Updates the editable fields of a user's profile.
  Future<UserModel> updateProfile({
    required UserModel existing,
    required String fullName,
    String? phoneNumber,
    Uint8List? newProfileImage,
    bool removeProfileImage = false,
  }) async {
    try {
      String? profileImage = existing.profileImage;

      // Handle image upload/removal
      if (newProfileImage != null) {
        // Compress image before upload
        final compressedImage = await _compressImage(newProfileImage);
        profileImage = await _uploadProfileImage(compressedImage, existing.uid);
      } else if (removeProfileImage) {
        profileImage = null;
      }

      final updated = existing.copyWith(
        fullName: fullName.trim(),
        phoneNumber: phoneNumber?.trim(),
        profileImage: profileImage,
      );

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

  /// Upload profile image to Firebase Storage
  Future<String> _uploadProfileImage(Uint8List imageBytes, String uid) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'compressed': 'true'},
        ),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException {
      throw const ProfileException('Could not upload your profile picture. Please try again.');
    }
  }

  /// Compress image to reduce upload time (from ~2-3MB to ~200-300KB)
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Resize to max 500px (maintain aspect ratio)
      final resized = img.copyResize(
        image,
        width: 500,
        height: 500,
        interpolation: img.Interpolation.average,
      );

      // Compress to 70% quality
      return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
    } catch (_) {
      return bytes; // If compression fails, return original
    }
  }
}