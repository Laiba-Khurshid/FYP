import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:project/models/asset_model.dart';

import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/constants.dart';

import 'package:project/services/audit_service.dart';

/// A custom, UI-friendly exception thrown by [AssetService].
///
/// Wraps any underlying Firestore/Storage failure into a single
/// human-readable [message] so the ViewModel/UI layer never has to
/// interpret Firebase error codes directly.
class AssetException implements Exception {
  final String message;
  const AssetException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates all Cloud Firestore and Firebase Storage logic for the
/// Asset Management module: asset CRUD, automatic Asset Code
/// generation, `asset_items` subcollection management, and image
/// upload/delete.
///
/// This is the ONLY class in the app allowed to talk directly to the
/// `assets` collection (and its `asset_items` subcollections) or the
/// asset-images Storage bucket. The UI layer never touches Firebase
/// directly — it goes through [AssetViewModel], which in turn calls
/// this service, keeping the project's MVVM separation intact.
///
/// Also holds an [AuditService] so adding, updating, or deleting an
/// asset automatically records the corresponding audit log entry.
class AssetService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AuditService _auditService;

  AssetService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    AuditService? auditService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auditService = auditService ?? AuditService();

  CollectionReference<Map<String, dynamic>> get _assetsRef =>
      _firestore.collection(AppConstants.assetsCollection);

  DocumentReference<Map<String, dynamic>> get _assetCounterRef => _firestore
      .collection(AssetConstants.metaCollection)
      .doc(AssetConstants.assetCounterDoc);

  CollectionReference<Map<String, dynamic>> _itemsRef(String assetId) =>
      _assetsRef.doc(assetId).collection(AssetConstants.assetItemsSubcollection);

  // -----------------------------------------------------------------
  // Read (streams)
  // -----------------------------------------------------------------

  /// Streams every asset in the department, newest asset code first.
  ///
  /// Updates automatically whenever a document changes — whether the
  /// change came from this app or was made directly in the Firebase
  /// Console — since it is backed by a live Firestore snapshot stream.
  /// Search and filtering are performed client-side in [AssetViewModel]
  /// against this single stream.
  Stream<List<AssetModel>> streamAssets() {
    return _assetsRef.orderBy('assetId', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(AssetModel.fromDocument).toList(),
    );
  }

  /// Streams the generated Asset Codes for one individually-tracked
  /// asset's `asset_items` subcollection, ordered by asset code.
  Stream<List<AssetItemModel>> streamAssetItems(String assetId) {
    return _itemsRef(assetId).orderBy('assetCode').snapshots().map(
          (snapshot) => snapshot.docs.map(AssetItemModel.fromDocument).toList(),
    );
  }

  // -----------------------------------------------------------------
  // Create
  // -----------------------------------------------------------------

  /// Creates a new asset document (auto-assigning a sequential, friendly
  /// [AssetModel.assetId] such as "AST001"), uploading [imageBytes] first
  /// (if provided), and — if [category] is individually tracked —
  /// generating `quantity` Asset Code documents in the `asset_items`
  /// subcollection.
  Future<AssetModel> addAsset({
    required String assetName,
    required String category,
    required String labName,
    required int quantity,
    required DateTime purchaseDate,
    required String location,
    required String actorId,
    required String actorName,
    required String actorRole,
    Uint8List? imageBytes,
  }) async {
    try {
      final assetId = await _generateNextAssetId();

      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await _uploadImage(imageBytes, assetId);
      }

      final asset = AssetModel(
        assetId: assetId,
        assetName: assetName.trim(),
        category: category,
        labName: labName,
        quantity: quantity,
        purchaseDate: purchaseDate,
        location: location.trim(),
        imageUrl: imageUrl,
      );

      await _assetsRef.doc(assetId).set(asset.toMap());

      if (AssetConstants.isTrackedCategory(category)) {
        await _generateAssetCodes(
          assetId: assetId,
          category: category,
          startIndex: 1,
          count: quantity,
        );
      }

      await _auditService.record(
        userId: actorId,
        userName: actorName,
        role: actorRole,
        action: AppConstants.auditActionAssetAdded,
        module: AppConstants.auditModuleAsset,
        referenceId: assetId,
      );

      return asset;
    } on FirebaseException catch (e) {
      throw AssetException(_mapFirebaseError(e));
    } on AssetException {
      rethrow;
    } catch (_) {
      throw const AssetException('Could not add the asset. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Update
  // -----------------------------------------------------------------

  /// Updates an existing asset.
  ///
  /// If [existingAsset.category] is individually tracked and [quantity]
  /// increased, new Asset Codes are automatically generated for the
  /// added units (continuing the numbering from the current highest
  /// code). If quantity decreased, existing Asset Codes are left
  /// untouched — they may already carry maintenance or complaint
  /// history — per the module's design.
  Future<AssetModel> updateAsset({
    required AssetModel existingAsset,
    required String assetName,
    required int quantity,
    required DateTime purchaseDate,
    required String location,
    required String actorId,
    required String actorName,
    required String actorRole,
    Uint8List? newImageBytes,
    bool removeImage = false,
  }) async {
    try {
      String? imageUrl = existingAsset.imageUrl;

      if (newImageBytes != null) {
        if (existingAsset.imageUrl != null) {
          await _deleteImage(existingAsset.imageUrl!);
        }
        imageUrl = await _uploadImage(newImageBytes, existingAsset.assetId);
      } else if (removeImage && existingAsset.imageUrl != null) {
        await _deleteImage(existingAsset.imageUrl!);
        imageUrl = null;
      }

      final updated = existingAsset.copyWith(
        assetName: assetName.trim(),
        quantity: quantity,
        purchaseDate: purchaseDate,
        location: location.trim(),
        imageUrl: imageUrl,
      );

      await _assetsRef.doc(existingAsset.assetId).update(updated.toMap());

      if (AssetConstants.isTrackedCategory(existingAsset.category) &&
          quantity > existingAsset.quantity) {
        final currentItemCount = await _currentItemCount(existingAsset.assetId);
        await _generateAssetCodes(
          assetId: existingAsset.assetId,
          category: existingAsset.category,
          startIndex: currentItemCount + 1,
          count: quantity - existingAsset.quantity,
        );
      }

      await _auditService.record(
        userId: actorId,
        userName: actorName,
        role: actorRole,
        action: AppConstants.auditActionAssetUpdated,
        module: AppConstants.auditModuleAsset,
        referenceId: existingAsset.assetId,
      );

      return updated;
    } on FirebaseException catch (e) {
      throw AssetException(_mapFirebaseError(e));
    } on AssetException {
      rethrow;
    } catch (_) {
      throw const AssetException('Could not update the asset. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------

  /// Deletes an asset's Firestore record, its `asset_items`
  /// subcollection (if any), and its Storage image (if any). The caller
  /// is responsible for showing a confirmation dialog before calling
  /// this — this service performs the deletion unconditionally.
  Future<void> deleteAsset(
      AssetModel asset, {
        required String actorId,
        required String actorName,
        required String actorRole,
      }) async {
    try {
      if (asset.imageUrl != null) {
        await _deleteImage(asset.imageUrl!);
      }

      if (AssetConstants.isTrackedCategory(asset.category)) {
        final items = await _itemsRef(asset.assetId).get();
        for (final doc in items.docs) {
          await doc.reference.delete();
        }
      }

      await _assetsRef.doc(asset.assetId).delete();

      await _auditService.record(
        userId: actorId,
        userName: actorName,
        role: actorRole,
        action: AppConstants.auditActionAssetDeleted,
        module: AppConstants.auditModuleAsset,
        referenceId: asset.assetId,
      );
    } on FirebaseException catch (e) {
      throw AssetException(_mapFirebaseError(e));
    } catch (_) {
      throw const AssetException('Could not delete the asset. Please try again.');
    }
  }

  // -----------------------------------------------------------------
  // Asset Code / asset_items generation
  // -----------------------------------------------------------------

  Future<int> _currentItemCount(String assetId) async {
    final snapshot = await _itemsRef(assetId).count().get();
    return snapshot.count ?? 0;
  }

  /// Generates [count] sequential Asset Code documents for [assetId],
  /// starting at [startIndex] (1-based), using the prefix registered for
  /// [category] in [AssetConstants.trackedCategoryPrefixes].
  ///
  /// Example: category "Chromebook" (prefix "CB"), startIndex 51,
  /// count 2 → creates "CB051" and "CB052".
  Future<void> _generateAssetCodes({
    required String assetId,
    required String category,
    required int startIndex,
    required int count,
  }) async {
    final prefix = AssetConstants.prefixForCategory(category);
    if (prefix == null || count <= 0) return;

    final batch = _firestore.batch();
    for (int i = 0; i < count; i++) {
      final number = startIndex + i;
      final code = '$prefix${number.toString().padLeft(3, '0')}';
      final itemRef = _itemsRef(assetId).doc(code);
      batch.set(
        itemRef,
        AssetItemModel(
          assetCode: code,
          status: AssetConstants.defaultItemStatus,
          remarks: AssetConstants.defaultItemRemarks,
        ).toMap(),
      );
    }
    await batch.commit();
  }

  /// Atomically generates the next sequential, friendly asset document
  /// ID (e.g. "AST001", "AST002", ...) using a Firestore transaction on
  /// a small counter document, so concurrent adds never collide.
  Future<String> _generateNextAssetId() async {
    return _firestore.runTransaction<String>((transaction) async {
      final counterSnapshot = await transaction.get(_assetCounterRef);
      final currentValue = (counterSnapshot.data()?['value'] as num?)?.toInt() ?? 0;
      final nextValue = currentValue + 1;

      transaction.set(_assetCounterRef, {'value': nextValue});

      return '${AssetConstants.assetIdPrefix}${nextValue.toString().padLeft(3, '0')}';
    });
  }

  // -----------------------------------------------------------------
  // Firebase Storage helpers
  // -----------------------------------------------------------------

  Future<String> _uploadImage(Uint8List imageBytes, String assetId) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.assetImagesStoragePath)
          .child('$assetId.jpg');
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException {
      throw const AssetException('Could not upload the asset image. Please try again.');
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (_) {
      // Non-fatal: the Firestore record is the source of truth. If the
      // Storage object was already removed or the URL is stale, we
      // silently continue rather than blocking the caller's CRUD flow.
    }
  }

  // -----------------------------------------------------------------
  // Demo data
  // -----------------------------------------------------------------

  /// Seeds a small (~20 item) representative demo dataset using the
  /// department's real lab names, for demonstration purposes only.
  ///
  /// Safe to call repeatedly — if the `assets` collection already
  /// contains any documents, this is a no-op, so it never overwrites
  /// or duplicates data the Admin has added or modified.
  Future<void> seedDemoDataIfEmpty() async {
    final existing = await _assetsRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final demoAssets = <Map<String, dynamic>>[
      {'assetName': 'Dell OptiPlex Desktop', 'category': 'Computer System', 'labName': 'Coding Lab 1', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Dell OptiPlex Desktop', 'category': 'Computer System', 'labName': 'Coding Lab 2', 'quantity': 28, 'location': 'Row A–C'},
      {'assetName': 'Acer Chromebook', 'category': 'Chromebook', 'labName': 'Smart Lab 1', 'quantity': 25, 'location': 'Storage Cabinet 1'},
      {'assetName': 'Acer Chromebook', 'category': 'Chromebook', 'labName': 'Smart Lab 2', 'quantity': 20, 'location': 'Storage Cabinet 1'},
      {'assetName': 'HP VDI Terminal', 'category': 'VDI Computer', 'labName': 'Google Lab', 'quantity': 15, 'location': 'Row D'},
      {'assetName': 'HP ProDesk', 'category': 'HP Computer', 'labName': 'Project Lab', 'quantity': 10, 'location': 'Row A'},
      {'assetName': 'Logitech Keyboard', 'category': 'Keyboard', 'labName': 'Coding Lab 1', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Logitech Mouse', 'category': 'Mouse', 'labName': 'Coding Lab 1', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Collar Mic', 'category': 'Mic', 'labName': 'High Impact Lab', 'quantity': 4, 'location': 'AV Cabinet'},
      {'assetName': 'Promethean Interactive Board', 'category': 'Interactive Board', 'labName': 'High Impact Lab', 'quantity': 2, 'location': 'Front Wall'},
      {'assetName': 'Samsung Smart Board', 'category': 'Smart Board', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Google Jamboard', 'category': 'Google Board', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Classroom Whiteboard', 'category': 'White Board', 'labName': '912 Lab', 'quantity': 2, 'location': 'Front Wall'},
      {'assetName': 'Classroom Greenboard', 'category': 'Green Board', 'labName': '912 Lab', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Epson Projector', 'category': 'Projector', 'labName': 'Smart Lab 1', 'quantity': 1, 'location': 'Ceiling Mount'},
      {'assetName': 'Epson Projector', 'category': 'Projector', 'labName': 'Smart Lab 2', 'quantity': 1, 'location': 'Ceiling Mount'},
      {'assetName': 'LG Display Screen', 'category': 'Display Screen', 'labName': 'Project Lab', 'quantity': 1, 'location': 'Reception Wall'},
      {'assetName': 'Poly Teleconference Screen', 'category': 'Teleconference Screen', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Conference Corner'},
      {'assetName': 'TP-Link Router', 'category': 'Router', 'labName': 'Coding Lab 1', 'quantity': 2, 'location': 'Network Rack'},
      {'assetName': 'Netgear Hub', 'category': 'Hub', 'labName': 'Coding Lab 2', 'quantity': 2, 'location': 'Network Rack'},
      {'assetName': 'PTZ Conference Camera', 'category': 'EPTZ Camera', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Conference Corner'},
      {'assetName': 'Student Chair', 'category': 'Chair', 'labName': 'Coding Lab 1', 'quantity': 40, 'location': 'Throughout Lab'},
      {'assetName': 'Student Table', 'category': 'Table', 'labName': 'Coding Lab 1', 'quantity': 20, 'location': 'Throughout Lab'},
      {'assetName': 'APC UPS', 'category': 'UPS', 'labName': 'Coding Lab 1', 'quantity': 2, 'location': 'Server Corner'},
      {'assetName': 'Split AC Unit', 'category': 'AC', 'labName': 'Smart Lab 1', 'quantity': 2, 'location': 'Side Wall'},
    ];

    for (final data in demoAssets) {
      final assetId = await _generateNextAssetId();
      final category = data['category'] as String;
      final quantity = data['quantity'] as int;

      final asset = AssetModel(
        assetId: assetId,
        assetName: data['assetName'] as String,
        category: category,
        labName: data['labName'] as String,
        quantity: quantity,
        purchaseDate: DateTime.now().subtract(const Duration(days: 240)),
        location: data['location'] as String,
      );

      await _assetsRef.doc(assetId).set(asset.toMap());

      if (AssetConstants.isTrackedCategory(category)) {
        await _generateAssetCodes(
          assetId: assetId,
          category: category,
          startIndex: 1,
          count: quantity,
        );
      }
    }
  }

  /// Deletes every asset document (and each one's `asset_items`
  /// subcollection and Storage image, if any). Used by the "Reset Demo
  /// Data" admin tool before re-seeding — never called from ordinary
  /// asset-management flows.
  Future<void> deleteAllAssets() async {
    final snapshot = await _assetsRef.get();
    for (final doc in snapshot.docs) {
      final asset = AssetModel.fromDocument(doc);
      if (asset.imageUrl != null) {
        await _deleteImage(asset.imageUrl!);
      }
      if (AssetConstants.isTrackedCategory(asset.category)) {
        final items = await _itemsRef(asset.assetId).get();
        for (final itemDoc in items.docs) {
          await itemDoc.reference.delete();
        }
      }
      await doc.reference.delete();
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
        return 'This asset no longer exists.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}