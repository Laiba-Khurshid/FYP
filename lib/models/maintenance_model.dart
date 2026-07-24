import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single maintenance record as stored in the existing
/// `maintenance` Firestore collection.
///
/// Every maintenance record belongs to exactly one complaint
/// ([complaintId]) — per the module's workflow, a record is only ever
/// created once that complaint has reached "In Progress".
class MaintenanceModel {
  final String maintenanceId;
  final String complaintId;
  final String assetId;
  final String assetName;
  final String labName;
  final String technicianName;
  final String maintenanceType;
  final String maintenanceStatus;
  final String remarks;
  final double cost;
  final DateTime maintenanceDate;
  final DateTime? completedDate;
  final String createdBy;
  final DateTime createdAt;

  const MaintenanceModel({
    required this.maintenanceId,
    required this.complaintId,
    required this.assetId,
    required this.assetName,
    required this.labName,
    required this.technicianName,
    required this.maintenanceType,
    required this.maintenanceStatus,
    required this.remarks,
    required this.cost,
    required this.maintenanceDate,
    required this.createdBy,
    required this.createdAt,
    this.completedDate,
  });

  /// Builds a [MaintenanceModel] from a Firestore document map.
  factory MaintenanceModel.fromMap(Map<String, dynamic> map, String maintenanceId) {
    return MaintenanceModel(
      maintenanceId: maintenanceId,
      complaintId: map['complaintId'] as String? ?? '',
      assetId: map['assetId'] as String? ?? '',
      assetName: map['assetName'] as String? ?? '',
      labName: map['labName'] as String? ?? '',
      technicianName: map['technicianName'] as String? ?? '',
      maintenanceType: map['maintenanceType'] as String? ?? '',
      maintenanceStatus: map['maintenanceStatus'] as String? ?? 'Pending',
      remarks: map['remarks'] as String? ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      maintenanceDate: _parseDate(map['maintenanceDate']) ?? DateTime.now(),
      completedDate: _parseDate(map['completedDate']),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Builds a [MaintenanceModel] directly from a [DocumentSnapshot].
  factory MaintenanceModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Maintenance document ${doc.id} has no data.');
    }
    return MaintenanceModel.fromMap(data, doc.id);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Converts this [MaintenanceModel] into a Firestore-writable map.
  ///
  /// [maintenanceId] is intentionally excluded since it is used as the
  /// document ID rather than stored as a field.
  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'assetId': assetId,
      'assetName': assetName,
      'labName': labName,
      'technicianName': technicianName,
      'maintenanceType': maintenanceType,
      'maintenanceStatus': maintenanceStatus,
      'remarks': remarks,
      'cost': cost,
      'maintenanceDate': Timestamp.fromDate(maintenanceDate),
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MaintenanceModel copyWith({
    String? technicianName,
    String? maintenanceType,
    String? maintenanceStatus,
    String? remarks,
    double? cost,
    DateTime? maintenanceDate,
    DateTime? completedDate,
    bool clearCompletedDate = false,
  }) {
    return MaintenanceModel(
      maintenanceId: maintenanceId,
      complaintId: complaintId,
      assetId: assetId,
      assetName: assetName,
      labName: labName,
      technicianName: technicianName ?? this.technicianName,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      maintenanceStatus: maintenanceStatus ?? this.maintenanceStatus,
      remarks: remarks ?? this.remarks,
      cost: cost ?? this.cost,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      completedDate: clearCompletedDate ? null : (completedDate ?? this.completedDate),
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is MaintenanceModel && other.maintenanceId == maintenanceId;

  @override
  int get hashCode => maintenanceId.hashCode;

  @override
  String toString() =>
      'MaintenanceModel(maintenanceId: $maintenanceId, assetName: $assetName, status: $maintenanceStatus)';
}