import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:project/core/utils/app_constants.dart';
import 'package:project/services/asset_service.dart';

/// A custom, UI-friendly exception thrown by [AdminToolsService].
class AdminToolsException implements Exception {
  final String message;
  const AdminToolsException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates the Admin-only data-management tools: seeding/resetting
/// demo data and bulk-clearing complaints/maintenance records.
///
/// Reuses [AssetService] for all asset seeding/deletion (so the Asset
/// module's Asset Code generation and `asset_items` handling is never
/// duplicated here) and talks directly to the `complaints` and
/// `maintenance` collections only for their bulk-clear operations.
class AdminToolsService {
  final FirebaseFirestore _firestore;
  final AssetService _assetService;

  AdminToolsService({
    FirebaseFirestore? firestore,
    AssetService? assetService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _assetService = assetService ?? AssetService();

  /// Seeds the department's labs and a demo set of assets into the
  /// existing `assets` collection. Safe to call repeatedly — a no-op if
  /// assets already exist.
  Future<void> seedDemoData() async {
    try {
      await _assetService.seedDemoDataIfEmpty();
    } catch (_) {
      throw const AdminToolsException('Could not seed demo data. Please try again.');
    }
  }

  /// Deletes every existing asset (and its `asset_items`/Storage image)
  /// then re-seeds the demo dataset fresh.
  Future<void> resetDemoData() async {
    try {
      await _assetService.deleteAllAssets();
      await _assetService.seedDemoDataIfEmpty();
    } catch (_) {
      throw const AdminToolsException('Could not reset demo data. Please try again.');
    }
  }

  /// Permanently deletes every complaint document.
  Future<void> clearComplaints() async {
    await _clearCollection(AppConstants.complaintsCollection);
  }

  /// Permanently deletes every maintenance document.
  Future<void> clearMaintenance() async {
    await _clearCollection(AppConstants.maintenanceCollection);
  }

  Future<void> _clearCollection(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      // Firestore batches are capped at 500 writes; chunk accordingly.
      const chunkSize = 450;
      for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
        final chunk = snapshot.docs.sublist(
          i,
          (i + chunkSize > snapshot.docs.length) ? snapshot.docs.length : i + chunkSize,
        );
        final batch = _firestore.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw AdminToolsException(e.message ?? 'Could not clear $collectionName.');
    }
  }
}