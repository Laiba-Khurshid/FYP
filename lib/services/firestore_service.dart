// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'package:project/core/utils/app_constants.dart';
// import 'package:project/models/asset_model.dart';
// import 'package:project/models/complaint_model.dart';
// import 'package:project/models/maintenance_model.dart';
//
// /// Firestore service for CRUD operations
// class FirestoreService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // ========== ASSET OPERATIONS ==========
//
//   // Add new asset
//   Future<String> addAsset(AssetModel asset) async {
//     try {
//       final docRef = await _firestore
//           .collection(AppConstants.assetsCollection)
//           .add(asset.toMap());
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Failed to add asset: ${e.toString()}');
//     }
//   }
//
//   // Update asset
//   Future<void> updateAsset(AssetModel asset) async {
//     try {
//       await _firestore
//           .collection(AppConstants.assetsCollection)
//           .doc(asset.assetId)
//           .update(asset.toMap());
//     } catch (e) {
//       throw Exception('Failed to update asset: ${e.toString()}');
//     }
//   }
//
//   // Delete asset
//   Future<void> deleteAsset(String assetId) async {
//     try {
//       await _firestore
//           .collection(AppConstants.assetsCollection)
//           .doc(assetId)
//           .delete();
//     } catch (e) {
//       throw Exception('Failed to delete asset: ${e.toString()}');
//     }
//   }
//
//   // Get all assets
//   Stream<List<AssetModel>> getAllAssets() {
//     return _firestore
//         .collection(AppConstants.assetsCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => AssetModel.fromMap(doc.data(), doc.id))
//         .toList());
//   }
//
//   // Get assets by department
//   Stream<List<AssetModel>> getAssetsByDepartment(String department) {
//     return _firestore
//         .collection(AppConstants.assetsCollection)
//         .where('department', isEqualTo: department)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => AssetModel.fromMap(doc.data(), doc.id))
//         .toList());
//   }
//
//   // Get asset by ID
//   Future<AssetModel?> getAssetById(String assetId) async {
//     try {
//       final doc = await _firestore
//           .collection(AppConstants.assetsCollection)
//           .doc(assetId)
//           .get();
//
//       if (doc.exists) {
//         return AssetModel.fromMap(doc.data()!, doc.id);
//       }
//       return null;
//     } catch (e) {
//       throw Exception('Failed to get asset: ${e.toString()}');
//     }
//   }
//
//   // ========== COMPLAINT OPERATIONS ==========
//
//   // Submit new complaint
//   Future<String> submitComplaint(ComplaintModel complaint) async {
//     try {
//       final docRef = await _firestore
//           .collection(AppConstants.complaintsCollection)
//           .add(complaint.toMap());
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Failed to submit complaint: ${e.toString()}');
//     }
//   }
//
//   // Update complaint
//   Future<void> updateComplaint(ComplaintModel complaint) async {
//     try {
//       await _firestore
//           .collection(AppConstants.complaintsCollection)
//           .doc(complaint.complaintId)
//           .update(complaint.toMap());
//     } catch (e) {
//       throw Exception('Failed to update complaint: ${e.toString()}');
//     }
//   }
//
//   // Get all complaints
//   Stream<List<ComplaintModel>> getAllComplaints() {
//     return _firestore
//         .collection(AppConstants.complaintsCollection)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
//         .toList());
//   }
//
//   // Get complaints by user
//   Stream<List<ComplaintModel>> getComplaintsByUser(String userId) {
//     return _firestore
//         .collection(AppConstants.complaintsCollection)
//         .where('userId', isEqualTo: userId)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
//         .toList());
//   }
//
//   // Get complaints by status
//   Stream<List<ComplaintModel>> getComplaintsByStatus(String status) {
//     return _firestore
//         .collection(AppConstants.complaintsCollection)
//         .where('status', isEqualTo: status)
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
//         .toList());
//   }
//
//   // Escalate complaint
//   Future<void> escalateComplaint(ComplaintModel complaint) async {
//     try {
//       final updatedComplaint = complaint.copyWith(
//         escalationLevel: complaint.escalationLevel + 1,
//         lastEscalatedAt: DateTime.now(),
//         status: AppConstants.statusEscalated,
//         escalationHistory: [
//           ...complaint.escalationHistory,
//           EscalationHistory(
//             escalatedAt: DateTime.now(),
//             fromLevel: complaint.escalationLevel,
//             toLevel: complaint.escalationLevel + 1,
//             reason: 'Auto-escalation after 10 days',
//           ),
//         ],
//       );
//
//       await updateComplaint(updatedComplaint);
//     } catch (e) {
//       throw Exception('Failed to escalate complaint: ${e.toString()}');
//     }
//   }
//
//   // ========== MAINTENANCE OPERATIONS ==========
//
//   // Add maintenance record
//   Future<String> addMaintenance(MaintenanceModel maintenance) async {
//     try {
//       final docRef = await _firestore
//           .collection(AppConstants.maintenanceCollection)
//           .add(maintenance.toMap());
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Failed to add maintenance: ${e.toString()}');
//     }
//   }
//
//   // Update maintenance
//   Future<void> updateMaintenance(MaintenanceModel maintenance) async {
//     try {
//       await _firestore
//           .collection(AppConstants.maintenanceCollection)
//           .doc(maintenance.maintenanceId)
//           .update(maintenance.toMap());
//     } catch (e) {
//       throw Exception('Failed to update maintenance: ${e.toString()}');
//     }
//   }
//
//   // Get maintenance records by asset
//   Stream<List<MaintenanceModel>> getMaintenanceByAsset(String assetId) {
//     return _firestore
//         .collection(AppConstants.maintenanceCollection)
//         .where('assetId', isEqualTo: assetId)
//         .orderBy('maintenanceDate', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => MaintenanceModel.fromMap(doc.data(), doc.id))
//         .toList());
//   }
//
//   // Get all maintenance records
//   Stream<List<MaintenanceModel>> getAllMaintenance() {
//     return _firestore
//         .collection(AppConstants.maintenanceCollection)
//         .orderBy('maintenanceDate', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//         .map((doc) => MaintenanceModel.fromMap(doc.data(), doc.id))
//         .toList());
//   }
// }
