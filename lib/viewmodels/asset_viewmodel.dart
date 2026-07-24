import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/asset_model.dart';
import '../services/asset_service.dart';

/// Sort options available on the Assets screen.
enum AssetSortOption { nameAscending, nameDescending, newestFirst, oldestFirst }

/// The ViewModel for the entire Asset Management module (list, search,
/// filter, sort, add, edit, delete, and the per-asset Asset Code list).
///
/// Owns all UI-facing state and delegates every Firestore/Storage
/// operation to [AssetService]. Screens interact with this class
/// exclusively through [Provider] / [Consumer] — no Firebase calls are
/// ever made directly from the UI.
class AssetViewModel extends ChangeNotifier {
  final AssetService _assetService;

  AssetViewModel({AssetService? assetService}) : _assetService = assetService ?? AssetService() {
    _subscribeToAssets();
  }

  // -----------------------------------------------------------------
  // State
  // -----------------------------------------------------------------

  StreamSubscription<List<AssetModel>>? _assetsSubscription;

  List<AssetModel> _allAssets = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _categoryFilter;
  String? _labFilter;
  AssetSortOption _sortOption = AssetSortOption.newestFirst;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  String? get labFilter => _labFilter;
  AssetSortOption get sortOption => _sortOption;
  int get totalAssetCount => _allAssets.length;
  bool get hasActiveFilters => _categoryFilter != null || _labFilter != null;

  /// The complete, unfiltered asset list — independent of this
  /// ViewModel's own search/filter/sort state (which only applies to
  /// [assets]). Used by other modules, such as the Complaint module's
  /// asset picker, that need every asset regardless of what's currently
  /// typed into the Assets screen's search bar.
  List<AssetModel> get allAssets => List.unmodifiable(_allAssets);

  /// The list of assets after search, filter, and sort have been
  /// applied — what the Assets screen should actually render.
  List<AssetModel> get assets {
    var result = _allAssets.where((asset) {
      final matchesSearch = _searchQuery.isEmpty ||
          asset.assetName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          asset.assetId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          asset.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          asset.labName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _categoryFilter == null || asset.category == _categoryFilter;
      final matchesLab = _labFilter == null || asset.labName == _labFilter;

      return matchesSearch && matchesCategory && matchesLab;
    }).toList();

    switch (_sortOption) {
      case AssetSortOption.nameAscending:
        result.sort((a, b) => a.assetName.toLowerCase().compareTo(b.assetName.toLowerCase()));
        break;
      case AssetSortOption.nameDescending:
        result.sort((a, b) => b.assetName.toLowerCase().compareTo(a.assetName.toLowerCase()));
        break;
      case AssetSortOption.newestFirst:
        result.sort((a, b) => b.assetId.compareTo(a.assetId));
        break;
      case AssetSortOption.oldestFirst:
        result.sort((a, b) => a.assetId.compareTo(b.assetId));
        break;
    }

    return result;
  }

  // -----------------------------------------------------------------
  // Stream subscription
  // -----------------------------------------------------------------

  void _subscribeToAssets() {
    _isLoading = true;
    _assetsSubscription?.cancel();
    _assetsSubscription = _assetService.streamAssets().listen(
          (assets) {
        _allAssets = assets;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error is AssetException
            ? error.message
            : 'Could not load assets. Please check your internet connection.';
        notifyListeners();
      },
    );
  }

  /// Manually re-subscribes to the asset stream — used by
  /// pull-to-refresh. Firestore streams already push live updates, so
  /// this mainly exists to give the user visible refresh feedback and
  /// to recover after a stream error.
  Future<void> refreshAssets() async {
    _subscribeToAssets();
    // Give the RefreshIndicator a brief, visible spin even on a fast
    // local cache hit.
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Streams the Asset Codes generated for one individually-tracked
  /// asset, for the Asset Details screen.
  Stream<List<AssetItemModel>> streamAssetItems(String assetId) {
    return _assetService.streamAssetItems(assetId);
  }

  @override
  void dispose() {
    _assetsSubscription?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Search, filter, sort
  // -----------------------------------------------------------------

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void applyFilters({String? category, String? lab}) {
    _categoryFilter = category;
    _labFilter = lab;
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = null;
    _labFilter = null;
    notifyListeners();
  }

  void setSortOption(AssetSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Create
  // -----------------------------------------------------------------

  /// Adds a new asset. Returns `true` on success; on failure,
  /// [errorMessage] is populated and `false` is returned.
  Future<bool> addAsset({
    required String assetName,
    required String category,
    required String labName,
    required int quantity,
    required DateTime purchaseDate,
    required String location,
    required String actorId,
    required String actorName,
    required String actorRole,
    File? imageFile,
  }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _assetService.addAsset(
        assetName: assetName,
        category: category,
        labName: labName,
        quantity: quantity,
        purchaseDate: purchaseDate,
        location: location,
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
        imageFile: imageFile,
      );
      return true;
    } on AssetException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // -----------------------------------------------------------------
  // Update
  // -----------------------------------------------------------------

  /// Updates an existing asset. Returns `true` on success.
  Future<bool> updateAsset({
    required AssetModel existingAsset,
    required String assetName,
    required int quantity,
    required DateTime purchaseDate,
    required String location,
    required String actorId,
    required String actorName,
    required String actorRole,
    File? newImageFile,
    bool removeImage = false,
  }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _assetService.updateAsset(
        existingAsset: existingAsset,
        assetName: assetName,
        quantity: quantity,
        purchaseDate: purchaseDate,
        location: location,
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
        newImageFile: newImageFile,
        removeImage: removeImage,
      );
      return true;
    } on AssetException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // -----------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------

  /// Deletes an asset. Returns `true` on success. The caller must have
  /// already shown a confirmation dialog before calling this.
  Future<bool> deleteAsset(
      AssetModel asset, {
        required String actorId,
        required String actorName,
        required String actorRole,
      }) async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _assetService.deleteAsset(asset, actorId: actorId, actorName: actorName, actorRole: actorRole);
      return true;
    } on AssetException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // -----------------------------------------------------------------
  // Demo data
  // -----------------------------------------------------------------

  /// Seeds a small representative demo dataset (no-op if the `assets`
  /// collection already has data). Returns `true` on success.
  Future<bool> seedDemoData() async {
    _errorMessage = null;
    _setSubmitting(true);
    try {
      await _assetService.seedDemoDataIfEmpty();
      return true;
    } on AssetException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not load demo data. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }
}