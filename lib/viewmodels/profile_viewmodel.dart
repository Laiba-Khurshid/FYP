import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/profile_service.dart';

/// The ViewModel for the Profile Management module.
class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileViewModel({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  UserModel? _profile;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  UserModel? get profile => _profile;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads (or refreshes) the current user's profile from Firestore.
  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _profileService.fetchProfile(uid);
      _errorMessage = null;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not load your profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the current profile. Returns the updated [UserModel] on
  /// success; returns `null` on failure with [errorMessage] populated.
  Future<UserModel?> updateProfile({
    required String fullName,
    String? phoneNumber,
    Uint8List? newProfileImage,
    bool removeProfileImage = false,
  }) async {
    final current = _profile;
    if (current == null) {
      _errorMessage = 'Your profile has not loaded yet. Please try again.';
      notifyListeners();
      return null;
    }

    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      final updated = await _profileService.updateProfile(
        existing: current,
        fullName: fullName,
        phoneNumber: phoneNumber,
        newProfileImage: newProfileImage,
        removeProfileImage: removeProfileImage,
      );
      _profile = updated;
      _isSaving = false;
      notifyListeners();
      return updated;
    } on ProfileException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Could not update your profile. Please try again.';
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }
}