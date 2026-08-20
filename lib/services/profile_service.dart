import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:project/models/user_model.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/services/audit_service.dart';

class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);

  @override
  String toString() => message;
}

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

  Future<UserModel> updateProfile({
    required UserModel existing,
    required String fullName,
    String? phoneNumber,
    Uint8List? newProfileImage,
    bool removeProfileImage = false,
  }) async {
    try {
      String? profileImage = existing.profileImage;

      if (newProfileImage != null) {
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

  // ================================================================
  // FASTEST COMPRESSION - 852KB → 100KB
  // ================================================================
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Resize to max 300px (profile picture ke liye kaafi hai)
      final resized = img.copyResize(
        image,
        width: 300,
        height: 300,
        interpolation: img.Interpolation.average,
      );

      // Compress to 50% quality
      return Uint8List.fromList(img.encodeJpg(resized, quality: 50));
    } catch (_) {
      return bytes;
    }
  }
}