import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:project/models/asset_model.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/constants.dart';
import 'package:project/services/audit_service.dart';

class AssetException implements Exception {
  final String message;
  const AssetException(this.message);

  @override
  String toString() => message;
}

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

  Stream<List<AssetModel>> streamAssets() {
    return _assetsRef.orderBy('assetId', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(AssetModel.fromDocument).toList(),
    );
  }

  Stream<List<AssetItemModel>> streamAssetItems(String assetId) {
    return _itemsRef(assetId).orderBy('assetCode').snapshots().map(
          (snapshot) => snapshot.docs.map(AssetItemModel.fromDocument).toList(),
    );
  }

  // -----------------------------------------------------------------
  // Create
  // -----------------------------------------------------------------

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
    try {
      final snapshot = await _itemsRef(assetId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

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
    } catch (_) {}
  }

  // ================================================================
  // GENERATE MISSING ASSET CODES (DELETE KIYE BINA)
  // ================================================================

  Future<void> generateMissingAssetCodes() async {
    try {
      final snapshot = await _assetsRef.get();

      if (snapshot.docs.isEmpty) {
        print('No assets found to generate codes for.');
        return;
      }

      int totalGenerated = 0;
      int totalAssets = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final asset = AssetModel.fromDocument(doc);
        final category = asset.category;

        if (!AssetConstants.isTrackedCategory(category)) {
          continue;
        }

        final existingItems = await _itemsRef(asset.assetId).limit(1).get();

        if (existingItems.docs.isNotEmpty) {
          continue;
        }

        await _generateAssetCodes(
          assetId: asset.assetId,
          category: category,
          startIndex: 1,
          count: asset.quantity,
        );

        totalGenerated++;
        print('Generated ${asset.quantity} codes for ${asset.assetName} (${asset.assetId})');
      }

      print('✅ Total assets checked: $totalAssets');
      print('✅ Total asset codes generated: $totalGenerated');

    } catch (e) {
      print('Error generating asset codes: $e');
      throw AssetException('Could not generate asset codes: $e');
    }
  }

  // ================================================================
  // DEMO DATA - SAB LABS KE COMPLETE ASSETS
  // ================================================================

  Future<void> seedDemoDataIfEmpty() async {
    final existing = await _assetsRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final allAssets = [
      // ============ 1. PROJECT LAB (12 Assets) ============
      {'assetName': 'Smart Interactive Board', 'category': 'Interactive Board', 'labName': 'Project Lab', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Computer System', 'category': 'Computer System', 'labName': 'Project Lab', 'quantity': 1, 'location': 'Teacher Desk'},
      {'assetName': 'Tables', 'category': 'Table', 'labName': 'Project Lab', 'quantity': 15, 'location': 'Throughout Lab'},
      {'assetName': 'Chairs', 'category': 'Chair', 'labName': 'Project Lab', 'quantity': 40, 'location': 'Throughout Lab'},
      {'assetName': 'Chromebooks', 'category': 'Chromebook', 'labName': 'Project Lab', 'quantity': 40, 'location': 'Storage Cabinet'},
      {'assetName': 'HDMI / Chromebook Accessories', 'category': 'Accessory', 'labName': 'Project Lab', 'quantity': 2, 'location': 'Storage Cabinet'},
      {'assetName': 'Fans', 'category': 'Fan', 'labName': 'Project Lab', 'quantity': 4, 'location': 'Ceiling'},
      {'assetName': 'AC', 'category': 'AC', 'labName': 'Project Lab', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Cupboard', 'category': 'Cupboard', 'labName': 'Project Lab', 'quantity': 1, 'location': 'Back Wall'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': 'Project Lab', 'quantity': 2, 'location': 'Ceiling'},
      {'assetName': 'Notice Board', 'category': 'Notice Board', 'labName': 'Project Lab', 'quantity': 2, 'location': 'Side Wall'},
      {'assetName': 'White Board', 'category': 'White Board', 'labName': 'Project Lab', 'quantity': 1, 'location': 'Front Wall'},

      // ============ 2. HIGH IMPACT LAB (17 Assets) ============
      {'assetName': 'Lenovo Computer Systems', 'category': 'Computer System', 'labName': 'High Impact Lab', 'quantity': 18, 'location': 'Row A–C'},
      {'assetName': 'Mouse', 'category': 'Mouse', 'labName': 'High Impact Lab', 'quantity': 18, 'location': 'Row A–C'},
      {'assetName': 'Keyboard', 'category': 'Keyboard', 'labName': 'High Impact Lab', 'quantity': 18, 'location': 'Row A–C'},
      {'assetName': 'Smart Board (ASTOUCH Interactive Flat Panel Display)', 'category': 'Smart Board', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'AC', 'category': 'AC', 'labName': 'High Impact Lab', 'quantity': 4, 'location': 'Side Walls'},
      {'assetName': 'Server Table', 'category': 'Table', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Server Corner'},
      {'assetName': 'Server Chair', 'category': 'Chair', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Server Corner'},
      {'assetName': 'Tables', 'category': 'Table', 'labName': 'High Impact Lab', 'quantity': 17, 'location': 'Throughout Lab'},
      {'assetName': 'Chairs', 'category': 'Chair', 'labName': 'High Impact Lab', 'quantity': 49, 'location': 'Throughout Lab'},
      {'assetName': 'Fans', 'category': 'Fan', 'labName': 'High Impact Lab', 'quantity': 6, 'location': 'Ceiling'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': 'High Impact Lab', 'quantity': 7, 'location': 'Ceiling'},
      {'assetName': 'CCTV Cameras', 'category': 'CCTV Camera', 'labName': 'High Impact Lab', 'quantity': 4, 'location': 'Corners'},
      {'assetName': 'Nayatel Internet (150 Mbps)', 'category': 'Internet', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'Mic', 'category': 'Mic', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'AV Cabinet'},
      {'assetName': 'ePTZ Camera', 'category': 'EPTZ Camera', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Conference Corner'},
      {'assetName': 'Sound Speakers', 'category': 'Sound Speaker', 'labName': 'High Impact Lab', 'quantity': 6, 'location': 'Throughout Lab'},
      {'assetName': 'UPS', 'category': 'UPS', 'labName': 'High Impact Lab', 'quantity': 1, 'location': 'Server Corner'},

      // ============ 3. SMART LAB 1 (12 Assets) ============
      {'assetName': 'VDI Computer Systems', 'category': 'VDI Computer', 'labName': 'Smart Lab 1', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Keyboard', 'category': 'Keyboard', 'labName': 'Smart Lab 1', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Mouse', 'category': 'Mouse', 'labName': 'Smart Lab 1', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Teleconference Screen', 'category': 'Teleconference Screen', 'labName': 'Smart Lab 1', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Tables', 'category': 'Table', 'labName': 'Smart Lab 1', 'quantity': 30, 'location': 'Throughout Lab'},
      {'assetName': 'Chairs', 'category': 'Chair', 'labName': 'Smart Lab 1', 'quantity': 42, 'location': 'Throughout Lab'},
      {'assetName': 'AC/DC', 'category': 'AC', 'labName': 'Smart Lab 1', 'quantity': 2, 'location': 'Side Walls'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': 'Smart Lab 1', 'quantity': 15, 'location': 'Ceiling'},
      {'assetName': 'Sound System', 'category': 'Sound System', 'labName': 'Smart Lab 1', 'quantity': 2, 'location': 'Front & Back'},
      {'assetName': 'Mic', 'category': 'Mic', 'labName': 'Smart Lab 1', 'quantity': 6, 'location': 'AV Cabinet'},
      {'assetName': 'ONT (Nayatel 100 Mbps)', 'category': 'ONT', 'labName': 'Smart Lab 1', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'CCTV Camera Rack', 'category': 'CCTV Camera', 'labName': 'Smart Lab 1', 'quantity': 1, 'location': 'Back Wall'},

      // ============ 4. SMART LAB 2 (11 Assets) ============
      {'assetName': 'Lenovo Computer Systems (Core i7, 8GB RAM, 256GB SSD)', 'category': 'Lenovo Computer System', 'labName': 'Smart Lab 2', 'quantity': 24, 'location': 'Row A–C'},
      {'assetName': 'Keyboard', 'category': 'Keyboard', 'labName': 'Smart Lab 2', 'quantity': 24, 'location': 'Row A–C'},
      {'assetName': 'Mouse', 'category': 'Mouse', 'labName': 'Smart Lab 2', 'quantity': 24, 'location': 'Row A–C'},
      {'assetName': 'Smart Board', 'category': 'Smart Board', 'labName': 'Smart Lab 2', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Tables', 'category': 'Table', 'labName': 'Smart Lab 2', 'quantity': 40, 'location': 'Throughout Lab'},
      {'assetName': 'Chairs', 'category': 'Chair', 'labName': 'Smart Lab 2', 'quantity': 40, 'location': 'Throughout Lab'},
      {'assetName': 'AC/DC', 'category': 'AC', 'labName': 'Smart Lab 2', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Sound System', 'category': 'Sound System', 'labName': 'Smart Lab 2', 'quantity': 2, 'location': 'Front & Back'},
      {'assetName': 'Mic', 'category': 'Mic', 'labName': 'Smart Lab 2', 'quantity': 2, 'location': 'AV Cabinet'},
      {'assetName': 'CCTV Cameras', 'category': 'CCTV Camera', 'labName': 'Smart Lab 2', 'quantity': 2, 'location': 'Corners'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': 'Smart Lab 2', 'quantity': 9, 'location': 'Ceiling'},

      // ============ 5. CODING LAB 1 (15 Assets) ============
      {'assetName': 'Chromebooks', 'category': 'Chromebook', 'labName': 'Coding Lab 1', 'quantity': 23, 'location': 'Storage Cabinet'},
      {'assetName': 'HDMI', 'category': 'Accessory', 'labName': 'Coding Lab 1', 'quantity': 1, 'location': 'AV Cabinet'},
      {'assetName': 'Interactive Board', 'category': 'Interactive Board', 'labName': 'Coding Lab 1', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Teacher Computer System', 'category': 'Computer System', 'labName': 'Coding Lab 1', 'quantity': 1, 'location': 'Teacher Desk'},
      {'assetName': 'HP Computer Systems', 'category': 'HP Computer', 'labName': 'Coding Lab 1', 'quantity': 10, 'location': 'Row D'},
      {'assetName': 'Keyboard', 'category': 'Keyboard', 'labName': 'Coding Lab 1', 'quantity': 10, 'location': 'Row D'},
      {'assetName': 'Mouse', 'category': 'Mouse', 'labName': 'Coding Lab 1', 'quantity': 10, 'location': 'Row D'},
      {'assetName': 'Small Tables', 'category': 'Table', 'labName': 'Coding Lab 1', 'quantity': 10, 'location': 'Row D'},
      {'assetName': 'Small Chairs', 'category': 'Chair', 'labName': 'Coding Lab 1', 'quantity': 10, 'location': 'Row D'},
      {'assetName': 'Bench Tables', 'category': 'Table', 'labName': 'Coding Lab 1', 'quantity': 10, 'location': 'Throughout Lab'},
      {'assetName': 'Fans', 'category': 'Fan', 'labName': 'Coding Lab 1', 'quantity': 6, 'location': 'Ceiling'},
      {'assetName': 'Exhaust Fans', 'category': 'Exhaust Fan', 'labName': 'Coding Lab 1', 'quantity': 2, 'location': 'Back Wall'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': 'Coding Lab 1', 'quantity': 17, 'location': 'Ceiling'},
      {'assetName': 'Sound System', 'category': 'Sound System', 'labName': 'Coding Lab 1', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Reading Table', 'category': 'Table', 'labName': 'Coding Lab 1', 'quantity': 1, 'location': 'Side Corner'},

      // ============ 6. GOOGLE LAB (15 Assets) ============
      {'assetName': 'Chromebooks', 'category': 'Chromebook', 'labName': 'Google Lab', 'quantity': 50, 'location': 'Storage Cabinet'},
      {'assetName': 'Computer Systems', 'category': 'Computer System', 'labName': 'Google Lab', 'quantity': 8, 'location': 'Row A'},
      {'assetName': 'AC', 'category': 'AC', 'labName': 'Google Lab', 'quantity': 3, 'location': 'Side Walls'},
      {'assetName': 'LED Screen', 'category': 'Display Screen', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'White Board', 'category': 'White Board', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Google Boards', 'category': 'Google Board', 'labName': 'Google Lab', 'quantity': 3, 'location': 'Side Walls'},
      {'assetName': 'Green Board', 'category': 'Green Board', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Projection Screen', 'category': 'Projection Screen', 'labName': 'Google Lab', 'quantity': 3, 'location': 'Ceiling Mount'},
      {'assetName': 'Intercom', 'category': 'Intercom', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Teacher Desk'},
      {'assetName': 'Fans', 'category': 'Fan', 'labName': 'Google Lab', 'quantity': 4, 'location': 'Ceiling'},
      {'assetName': 'Hub', 'category': 'Hub', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'ONT', 'category': 'ONT', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'Router', 'category': 'Router', 'labName': 'Google Lab', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'Bench Tables', 'category': 'Table', 'labName': 'Google Lab', 'quantity': 10, 'location': 'Throughout Lab'},
      {'assetName': 'Bench Chairs', 'category': 'Chair', 'labName': 'Google Lab', 'quantity': 10, 'location': 'Throughout Lab'},

      // ============ 7. CODING LAB 2 (22 Assets) ============
      {'assetName': 'Chromebooks', 'category': 'Chromebook', 'labName': 'Coding Lab 2', 'quantity': 94, 'location': 'Storage Cabinet'},
      {'assetName': 'Projector', 'category': 'Projector', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Ceiling Mount'},
      {'assetName': 'Display Screen', 'category': 'Display Screen', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'AC/DC', 'category': 'AC', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Iron Bench Tables', 'category': 'Table', 'labName': 'Coding Lab 2', 'quantity': 27, 'location': 'Throughout Lab'},
      {'assetName': 'Iron Bench Chairs', 'category': 'Chair', 'labName': 'Coding Lab 2', 'quantity': 39, 'location': 'Throughout Lab'},
      {'assetName': 'Fans', 'category': 'Fan', 'labName': 'Coding Lab 2', 'quantity': 6, 'location': 'Ceiling'},
      {'assetName': 'Exhaust Fans', 'category': 'Exhaust Fan', 'labName': 'Coding Lab 2', 'quantity': 2, 'location': 'Back Wall'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': 'Coding Lab 2', 'quantity': 21, 'location': 'Ceiling'},
      {'assetName': 'Hub', 'category': 'Hub', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'Router', 'category': 'Router', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'Fixed Tables', 'category': 'Table', 'labName': 'Coding Lab 2', 'quantity': 26, 'location': 'Throughout Lab'},
      {'assetName': 'Rostrum', 'category': 'Rostrum', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front'},
      {'assetName': 'CCTV Cameras', 'category': 'CCTV Camera', 'labName': 'Coding Lab 2', 'quantity': 2, 'location': 'Corners'},
      {'assetName': 'Portable Cupboard', 'category': 'Cupboard', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Back Wall'},
      {'assetName': 'Wooden Cupboard', 'category': 'Cupboard', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Back Wall'},
      {'assetName': 'White Board', 'category': 'White Board', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Notice Board', 'category': 'Notice Board', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Teacher Tables', 'category': 'Teacher Table', 'labName': 'Coding Lab 2', 'quantity': 4, 'location': 'Teacher Area'},
      {'assetName': 'Teacher Chairs', 'category': 'Teacher Chair', 'labName': 'Coding Lab 2', 'quantity': 4, 'location': 'Teacher Area'},
      {'assetName': 'Acrylic Boards', 'category': 'Acrylic Board', 'labName': 'Coding Lab 2', 'quantity': 6, 'location': 'Walls'},
      {'assetName': 'Sound System', 'category': 'Sound System', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front Wall'},

      // ============ 7. CODING LAB 2 (22 Assets) ============
      {'assetName': 'Chromebooks', 'category': 'Chromebook', 'labName': 'Coding Lab 2', 'quantity': 94, 'location': 'Storage Cabinet'},
      {'assetName': 'Projector', 'category': 'Projector', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Ceiling Mount'},
      {'assetName': 'Display Screen', 'category': 'Display Screen', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'AC/DC', 'category': 'AC', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Iron Bench Tables', 'category': 'Table', 'labName': 'Coding Lab 2', 'quantity': 27, 'location': 'Throughout Lab'},
      {'assetName': 'Iron Bench Chairs', 'category': 'Chair', 'labName': 'Coding Lab 2', 'quantity': 39, 'location': 'Throughout Lab'},
      {'assetName': 'Fans', 'category': 'Fan', 'labName': 'Coding Lab 2', 'quantity': 6, 'location': 'Ceiling'},
      {'assetName': 'Exhaust Fans', 'category': 'Exhaust Fan', 'labName': 'Coding Lab 2', 'quantity': 2, 'location': 'Back Wall'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': 'Coding Lab 2', 'quantity': 21, 'location': 'Ceiling'},
      {'assetName': 'Hub', 'category': 'Hub', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'Router', 'category': 'Router', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Network Rack'},
      {'assetName': 'Fixed Tables', 'category': 'Table', 'labName': 'Coding Lab 2', 'quantity': 26, 'location': 'Throughout Lab'},
      {'assetName': 'Rostrum', 'category': 'Rostrum', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front'},
      {'assetName': 'CCTV Cameras', 'category': 'CCTV Camera', 'labName': 'Coding Lab 2', 'quantity': 2, 'location': 'Corners'},
      {'assetName': 'Portable Cupboard', 'category': 'Cupboard', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Back Wall'},
      {'assetName': 'Wooden Cupboard', 'category': 'Cupboard', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Back Wall'},
      {'assetName': 'White Board', 'category': 'White Board', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Notice Board', 'category': 'Notice Board', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Side Wall'},
      {'assetName': 'Teacher Tables', 'category': 'Teacher Table', 'labName': 'Coding Lab 2', 'quantity': 4, 'location': 'Teacher Area'},
      {'assetName': 'Teacher Chairs', 'category': 'Teacher Chair', 'labName': 'Coding Lab 2', 'quantity': 4, 'location': 'Teacher Area'},
      {'assetName': 'Acrylic Boards', 'category': 'Acrylic Board', 'labName': 'Coding Lab 2', 'quantity': 6, 'location': 'Walls'},
      {'assetName': 'Sound System', 'category': 'Sound System', 'labName': 'Coding Lab 2', 'quantity': 1, 'location': 'Front Wall'},
      // ============ 8. 912 LAB (11 Assets) ============
      {'assetName': 'Mouse', 'category': 'Mouse', 'labName': '912 Lab', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Keyboard', 'category': 'Keyboard', 'labName': '912 Lab', 'quantity': 30, 'location': 'Row A–C'},
      {'assetName': 'Interactive Board', 'category': 'Interactive Board', 'labName': '912 Lab', 'quantity': 1, 'location': 'Front Wall'},
      {'assetName': 'Computer System', 'category': 'Computer System', 'labName': '912 Lab', 'quantity': 1, 'location': 'Teacher Desk'},
      {'assetName': 'Tables', 'category': 'Table', 'labName': '912 Lab', 'quantity': 30, 'location': 'Throughout Lab'},
      {'assetName': 'Printer Table', 'category': 'Table', 'labName': '912 Lab', 'quantity': 1, 'location': 'Printer Area'},
      {'assetName': 'Chairs', 'category': 'Chair', 'labName': '912 Lab', 'quantity': 40, 'location': 'Throughout Lab'},
      {'assetName': 'Fans', 'category': 'Fan', 'labName': '912 Lab', 'quantity': 6, 'location': 'Ceiling'},
      {'assetName': 'Lights', 'category': 'Light', 'labName': '912 Lab', 'quantity': 23, 'location': 'Ceiling'},
      {'assetName': 'UPS', 'category': 'UPS', 'labName': '912 Lab', 'quantity': 2, 'location': 'Server Corner'},
      {'assetName': 'Internal Battery', 'category': 'Accessory', 'labName': '912 Lab', 'quantity': 20, 'location': 'Storage Cabinet'},
    ];

    for (final data in allAssets) {
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

  // -----------------------------------------------------------------
  // Delete All Assets
  // -----------------------------------------------------------------

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