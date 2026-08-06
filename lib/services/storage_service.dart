import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload asset image
  Future<String> uploadAssetImage(File imageFile, String assetId) async {
    try {
      final ref = _storage.ref().child('assets/$assetId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload asset image: ${e.toString()}');
    }
  }

  // Upload complaint image
  Future<String> uploadComplaintImage(File imageFile, String complaintId) async {
    try {
      final ref = _storage.ref().child('complaints/$complaintId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload complaint image: ${e.toString()}');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final ref = _storage.ref().child('profiles/$userId/profile.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: ${e.toString()}');
    }
  }
}
