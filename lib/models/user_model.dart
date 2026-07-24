import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an AssetFlow user as stored in the `users` Firestore
/// collection and mirrored locally after authentication.
///
/// Used across the authentication module and, later, by the profile,
/// dashboard, and complaint modules wherever the identity of the
/// currently signed-in user (or another user, e.g. an assignee) is
/// needed.
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String department;
  final DateTime createdAt;
  final String? profileImage;
  final String? rollNumber;
  final String? employeeId;
  final String? phoneNumber;
  final String verificationStatus;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.department,
    required this.createdAt,
    this.profileImage,
    this.rollNumber,
    this.employeeId,
    this.phoneNumber,
    this.verificationStatus = 'approved',
  });

  /// Builds a [UserModel] from a Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? '',
      department: map['department'] as String? ?? '',
      createdAt: _parseCreatedAt(map['createdAt']),
      profileImage: map['profileImage'] as String?,
      rollNumber: map['rollNumber'] as String?,
      employeeId: map['employeeId'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      // Accounts created before the verification feature existed have
      // no stored status; treat them as already approved so nobody is
      // retroactively locked out.
      verificationStatus: map['verificationStatus'] as String? ?? 'approved',
    );
  }

  /// Builds a [UserModel] directly from a [DocumentSnapshot].
  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('User document ${doc.id} has no data.');
    }
    return UserModel.fromMap(data, doc.id);
  }

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Converts this [UserModel] into a Firestore-writable map.
  ///
  /// [uid] is intentionally excluded since it is used as the document ID
  /// rather than stored as a field.
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'department': department,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImage': profileImage,
      'rollNumber': rollNumber,
      'employeeId': employeeId,
      'phoneNumber': phoneNumber,
      'verificationStatus': verificationStatus,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? role,
    String? department,
    DateTime? createdAt,
    String? profileImage,
    String? rollNumber,
    String? employeeId,
    String? phoneNumber,
    String? verificationStatus,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      profileImage: profileImage ?? this.profileImage,
      rollNumber: rollNumber ?? this.rollNumber,
      employeeId: employeeId ?? this.employeeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  /// Whether this role should show a Roll Number field on the profile
  /// (Students) as opposed to an Employee ID (Faculty/Admin/staff).
  bool get isStudent => role == 'student';

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  @override
  bool operator ==(Object other) => other is UserModel && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserModel(uid: $uid, fullName: $fullName, role: $role)';
}