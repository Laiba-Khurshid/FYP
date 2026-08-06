import 'package:cloud_firestore/cloud_firestore.dart';
class AssetModel {
  final String assetId;
  final String assetName;
  final String category;
  final String labName;
  final int quantity;
  final DateTime purchaseDate;
  final String location;
  final String? imageUrl;

  const AssetModel({
    required this.assetId,
    required this.assetName,
    required this.category,
    required this.labName,
    required this.quantity,
    required this.purchaseDate,
    required this.location,
    this.imageUrl,
  });

  /// Builds an [AssetModel] from a Firestore document map.
  factory AssetModel.fromMap(Map<String, dynamic> map, String assetId) {
    return AssetModel(
      assetId: assetId,
      assetName: map['assetName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      labName: map['labName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      purchaseDate: _parseDate(map['purchaseDate']),
      location: map['location'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }

  /// Builds an [AssetModel] directly from a [DocumentSnapshot].
  factory AssetModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Asset document ${doc.id} has no data.');
    }
    return AssetModel.fromMap(data, doc.id);
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Converts this [AssetModel] into a Firestore-writable map.
  ///
  /// [assetId] is intentionally excluded since it is used as the
  /// document ID rather than stored as a field.
  Map<String, dynamic> toMap() {
    return {
      'assetId': assetId,
      'assetName': assetName,
      'category': category,
      'labName': labName,
      'quantity': quantity,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'location': location,
      'imageUrl': imageUrl,
    };
  }

  AssetModel copyWith({
    String? assetName,
    String? category,
    String? labName,
    int? quantity,
    DateTime? purchaseDate,
    String? location,
    String? imageUrl,
  }) {
    return AssetModel(
      assetId: assetId,
      assetName: assetName ?? this.assetName,
      category: category ?? this.category,
      labName: labName ?? this.labName,
      quantity: quantity ?? this.quantity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) => other is AssetModel && other.assetId == assetId;

  @override
  int get hashCode => assetId.hashCode;

  @override
  String toString() => 'AssetModel(assetId: $assetId, assetName: $assetName, lab: $labName)';
}

/// Represents a single physically-tracked unit of an individually
/// tracked asset (e.g. one specific Chromebook), stored as a document
/// inside `assets/{assetId}/asset_items`.
///
/// Only created for categories where
/// `AssetConstants.isTrackedCategory(category)` is `true` (Computer
/// Systems, Chromebooks, Projectors, Routers, UPS, Interactive Boards,
/// Smart Boards, Display Screens, Teleconference Screens, EPTZ
/// Cameras). Bulk categories (chairs, tables, mice, etc.) never get
/// asset_items documents — only their [AssetModel.quantity] is stored.
class AssetItemModel {
  final String assetCode;
  final String status;
  final String remarks;

  const AssetItemModel({
    required this.assetCode,
    required this.status,
    required this.remarks,
  });

  factory AssetItemModel.fromMap(Map<String, dynamic> map, String assetCode) {
    return AssetItemModel(
      assetCode: assetCode,
      status: map['status'] as String? ?? 'Available',
      remarks: map['remarks'] as String? ?? '',
    );
  }

  factory AssetItemModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Asset item document ${doc.id} has no data.');
    }
    return AssetItemModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'assetCode': assetCode,
      'status': status,
      'remarks': remarks,
    };
  }

  @override
  bool operator ==(Object other) => other is AssetItemModel && other.assetCode == assetCode;

  @override
  int get hashCode => assetCode.hashCode;

  @override
  String toString() => 'AssetItemModel(assetCode: $assetCode, status: $status)';
}
