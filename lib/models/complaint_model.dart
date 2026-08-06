import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String assetId;
  final String? assetCode;
  final String assetName;
  final String category;
  final String labName;
  final String reportedBy;
  final String userRole;
  final String description;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String assignedTo;
  final String? imageUrl;
  final int escalationLevel;

  const ComplaintModel({
    required this.complaintId,
    required this.assetId,
    required this.assetName,
    required this.category,
    required this.labName,
    required this.reportedBy,
    required this.userRole,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedTo,
    required this.escalationLevel,
    this.assetCode,
    this.imageUrl,
  });

  /// Builds a [ComplaintModel] from a Firestore document map.
  factory ComplaintModel.fromMap(Map<String, dynamic> map, String complaintId) {
    return ComplaintModel(
      complaintId: complaintId,
      assetId: map['assetId'] as String? ?? '',
      assetCode: map['assetCode'] as String?,
      assetName: map['assetName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      labName: map['labName'] as String? ?? '',
      reportedBy: map['reportedBy'] as String? ?? '',
      userRole: map['userRole'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'pending',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      assignedTo: map['assignedTo'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      escalationLevel: (map['escalationLevel'] as num?)?.toInt() ?? 0,
    );
  }

  /// Builds a [ComplaintModel] directly from a [DocumentSnapshot].
  factory ComplaintModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Complaint document ${doc.id} has no data.');
    }
    return ComplaintModel.fromMap(data, doc.id);
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Converts this [ComplaintModel] into a Firestore-writable map.
  ///
  /// [complaintId] is intentionally excluded since it is used as the
  /// document ID rather than stored as a field.
  Map<String, dynamic> toMap() {
    return {
      'assetId': assetId,
      'assetCode': assetCode,
      'assetName': assetName,
      'category': category,
      'labName': labName,
      'reportedBy': reportedBy,
      'userRole': userRole,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedTo': assignedTo,
      'imageUrl': imageUrl,
      'escalationLevel': escalationLevel,
    };
  }

  ComplaintModel copyWith({
    String? status,
    DateTime? updatedAt,
    String? assignedTo,
    int? escalationLevel,
    String? imageUrl,
  }) {
    return ComplaintModel(
      complaintId: complaintId,
      assetId: assetId,
      assetCode: assetCode,
      assetName: assetName,
      category: category,
      labName: labName,
      reportedBy: reportedBy,
      userRole: userRole,
      description: description,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) => other is ComplaintModel && other.complaintId == complaintId;

  @override
  int get hashCode => complaintId.hashCode;

  @override
  String toString() => 'ComplaintModel(complaintId: $complaintId, assetName: $assetName, status: $status)';
}
