import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:project/models/report_model.dart';

import 'package:project/core/utils/app_constants.dart';
/// A custom, UI-friendly exception thrown by [ReportService].
class ReportException implements Exception {
  final String message;
  const ReportException(this.message);

  @override
  String toString() => message;
}

/// Encapsulates all report-generation logic for AssetFlow.
///
/// Reports are never stored — this service reads a one-time snapshot of
/// the existing `assets`, `complaints`, `maintenance`, and `users`
/// collections, aggregates them into a [ReportModel], and (optionally)
/// renders that model into a downloadable/shareable PDF using the `pdf`
/// package. No UI code lives here, and no other service's collection
/// structure is modified — this is purely a read-only aggregator.
class ReportService {
  final FirebaseFirestore _firestore;

  ReportService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  // -----------------------------------------------------------------
  // Assets report
  // -----------------------------------------------------------------

  Future<ReportModel> generateAssetsReport() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.assetsCollection).get();

      final byLab = <String, int>{};
      final byCategory = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lab = data['labName'] as String? ?? 'Unknown';
        final category = data['category'] as String? ?? 'Unknown';
        final quantity = (data['quantity'] as num?)?.toInt() ?? 0;

        byLab[lab] = (byLab[lab] ?? 0) + quantity;
        byCategory[category] = (byCategory[category] ?? 0) + quantity;
      }

      final total = byLab.values.fold<int>(0, (sum, v) => sum + v);

      return ReportModel(
        reportType: AppConstants.reportTypeAssets,
        generatedAt: DateTime.now(),
        totalAssets: total,
        assetsByLab: byLab,
        assetsByCategory: byCategory,
      );
    } on FirebaseException catch (e) {
      throw ReportException(e.message ?? 'Could not generate the assets report.');
    }
  }

  // -----------------------------------------------------------------
  // Complaints report
  // -----------------------------------------------------------------

  Future<ReportModel> generateComplaintsReport() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.complaintsCollection).get();

      final byStatus = <String, int>{
        AppConstants.statusPending: 0,
        AppConstants.statusInProgress: 0,
        AppConstants.statusResolved: 0,
        AppConstants.statusEscalated: 0,
      };
      final byLab = <String, int>{};
      final byPriority = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? AppConstants.statusPending;
        final lab = data['labName'] as String? ?? 'Unknown';
        final priority = data['priority'] as String? ?? AppConstants.priorityMedium;

        byStatus[status] = (byStatus[status] ?? 0) + 1;
        byLab[lab] = (byLab[lab] ?? 0) + 1;
        byPriority[priority] = (byPriority[priority] ?? 0) + 1;
      }

      return ReportModel(
        reportType: AppConstants.reportTypeComplaints,
        generatedAt: DateTime.now(),
        totalComplaints: snapshot.docs.length,
        complaintsByStatus: byStatus,
        complaintsByLab: byLab,
        complaintsByPriority: byPriority,
      );
    } on FirebaseException catch (e) {
      throw ReportException(e.message ?? 'Could not generate the complaints report.');
    }
  }

  // -----------------------------------------------------------------
  // Maintenance report
  // -----------------------------------------------------------------

  Future<ReportModel> generateMaintenanceReport() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.maintenanceCollection).get();

      final byStatus = <String, int>{for (final s in AppConstants.maintenanceStatuses) s: 0};
      final costByType = <String, double>{for (final t in AppConstants.maintenanceTypes) t: 0};
      double totalCost = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['maintenanceStatus'] as String? ?? AppConstants.maintenanceStatusPending;
        final type = data['maintenanceType'] as String? ?? AppConstants.maintenanceTypeRepair;
        final cost = (data['cost'] as num?)?.toDouble() ?? 0;

        byStatus[status] = (byStatus[status] ?? 0) + 1;
        costByType[type] = (costByType[type] ?? 0) + cost;
        totalCost += cost;
      }

      return ReportModel(
        reportType: AppConstants.reportTypeMaintenance,
        generatedAt: DateTime.now(),
        totalMaintenanceRecords: snapshot.docs.length,
        maintenanceByStatus: byStatus,
        maintenanceCostByType: costByType,
        totalMaintenanceCost: totalCost,
      );
    } on FirebaseException catch (e) {
      throw ReportException(e.message ?? 'Could not generate the maintenance report.');
    }
  }

  // -----------------------------------------------------------------
  // Users report
  // -----------------------------------------------------------------

  Future<ReportModel> generateUsersReport() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.usersCollection).get();

      final byRole = <String, int>{for (final r in AppConstants.allRoles) r: 0};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String? ?? AppConstants.roleStudent;
        byRole[role] = (byRole[role] ?? 0) + 1;
      }

      return ReportModel(
        reportType: AppConstants.reportTypeUsers,
        generatedAt: DateTime.now(),
        totalUsers: snapshot.docs.length,
        usersByRole: byRole,
      );
    } on FirebaseException catch (e) {
      throw ReportException(e.message ?? 'Could not generate the users report.');
    }
  }

  // -----------------------------------------------------------------
  // Lightweight dashboard analytics
  // -----------------------------------------------------------------

  /// A lighter-weight aggregation than the full reports above, used by
  /// the Admin Dashboard's analytics section. Reads all three
  /// collections once and returns the specific counts the dashboard
  /// needs, including a count of assets currently tied to an active
  /// (non-completed, non-cancelled) maintenance record — used in place
  /// of "Assets in Poor Condition," since the Asset model intentionally
  /// does not track a `condition` field.
  Future<Map<String, dynamic>> generateDashboardStats() async {
    try {
      final assetsSnapshot = await _firestore.collection(AppConstants.assetsCollection).get();
      final complaintsSnapshot = await _firestore.collection(AppConstants.complaintsCollection).get();
      final maintenanceSnapshot = await _firestore.collection(AppConstants.maintenanceCollection).get();

      var totalAssets = 0;
      for (final doc in assetsSnapshot.docs) {
        totalAssets += ((doc.data()['quantity'] as num?)?.toInt() ?? 0);
      }

      var open = 0, resolved = 0, escalated = 0;
      for (final doc in complaintsSnapshot.docs) {
        final status = doc.data()['status'] as String? ?? AppConstants.statusPending;
        if (status == AppConstants.statusResolved) {
          resolved++;
        } else if (status == AppConstants.statusEscalated) {
          escalated++;
        } else {
          open++;
        }
      }

      final assetsUnderMaintenance = <String>{};
      for (final doc in maintenanceSnapshot.docs) {
        final status = doc.data()['maintenanceStatus'] as String? ?? '';
        if (status != AppConstants.maintenanceStatusCompleted && status != AppConstants.maintenanceStatusCancelled) {
          assetsUnderMaintenance.add(doc.data()['assetId'] as String? ?? doc.id);
        }
      }

      // A genuine 7-day complaint-volume trend, derived from each
      // complaint's real `createdAt` timestamp (oldest to newest) —
      // used by the dashboard's line chart.
      final today = DateTime.now();
      final last7Days = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
      final complaintsPerDay = List<int>.filled(7, 0);
      for (final doc in complaintsSnapshot.docs) {
        final createdAt = doc.data()['createdAt'];
        if (createdAt is! Timestamp) continue;
        final date = createdAt.toDate();
        final dayOnly = DateTime(date.year, date.month, date.day);
        final index = last7Days.indexWhere((d) => d == dayOnly);
        if (index != -1) complaintsPerDay[index]++;
      }

      return {
        'totalAssets': totalAssets,
        'totalComplaints': complaintsSnapshot.docs.length,
        'openComplaints': open,
        'resolvedComplaints': resolved,
        'escalatedComplaints': escalated,
        'maintenanceRecords': maintenanceSnapshot.docs.length,
        'assetsUnderMaintenance': assetsUnderMaintenance.length,
        'complaintsByStatus': {
          'Pending/In Progress': open,
          'Resolved': resolved,
          'Escalated': escalated,
        },
        'complaintsLast7Days': complaintsPerDay,
        'last7DayLabels': last7Days.map((d) => DateFormat('E').format(d)).toList(),
      };
    } on FirebaseException catch (e) {
      throw ReportException(e.message ?? 'Could not load dashboard statistics.');
    }
  }

  // -----------------------------------------------------------------
  // PDF generation
  // -----------------------------------------------------------------

  /// Renders [report] into a PDF document (college name, department,
  /// generated date, and a summary table matching the report type) and
  /// returns the raw bytes, ready to be shared/printed/saved via the
  /// `printing` package.
  Future<Uint8List> generatePdf(ReportModel report) async {
    final doc = pw.Document();
    final dateLabel = DateFormat('MMMM d, y • h:mm a').format(report.generatedAt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(AppConstants.organizationName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(AppConstants.departmentName, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 2),
                pw.Text('Generated: $dateLabel', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(_titleFor(report.reportType), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          ..._sectionsFor(report),
        ],
      ),
    );

    return doc.save();
  }

  String _titleFor(String type) {
    switch (type) {
      case AppConstants.reportTypeAssets:
        return 'Assets Report';
      case AppConstants.reportTypeComplaints:
        return 'Complaints Report';
      case AppConstants.reportTypeMaintenance:
        return 'Maintenance Report';
      case AppConstants.reportTypeUsers:
        return 'Users Report';
      default:
        return 'Report';
    }
  }

  List<pw.Widget> _sectionsFor(ReportModel report) {
    switch (report.reportType) {
      case AppConstants.reportTypeAssets:
        return [
          _summaryLine('Total Assets', report.totalAssets.toString()),
          pw.SizedBox(height: 12),
          _table('Assets by Lab', report.assetsByLab),
          pw.SizedBox(height: 12),
          _table('Assets by Category', report.assetsByCategory),
        ];
      case AppConstants.reportTypeComplaints:
        return [
          _summaryLine('Total Complaints', report.totalComplaints.toString()),
          pw.SizedBox(height: 12),
          _table('Complaint Summary', report.complaintsByStatus),
          pw.SizedBox(height: 12),
          _table('Complaints by Lab', report.complaintsByLab),
          pw.SizedBox(height: 12),
          _table('Complaints by Priority', report.complaintsByPriority),
        ];
      case AppConstants.reportTypeMaintenance:
        return [
          _summaryLine('Total Maintenance Records', report.totalMaintenanceRecords.toString()),
          _summaryLine('Total Maintenance Cost', 'PKR ${report.totalMaintenanceCost.toStringAsFixed(0)}'),
          pw.SizedBox(height: 12),
          _table('Maintenance Summary', report.maintenanceByStatus),
          pw.SizedBox(height: 12),
          _tableDouble('Maintenance Cost by Type (PKR)', report.maintenanceCostByType),
        ];
      case AppConstants.reportTypeUsers:
        return [
          _summaryLine('Total Users', report.totalUsers.toString()),
          pw.SizedBox(height: 12),
          _table('Users by Role', report.usersByRole),
        ];
      default:
        return [];
    }
  }

  pw.Widget _summaryLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _table(String title, Map<String, int> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Category', 'Count'],
          data: data.entries.map((e) => [e.key, e.value.toString()]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    );
  }

  pw.Widget _tableDouble(String title, Map<String, double> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Type', 'Cost (PKR)'],
          data: data.entries.map((e) => [e.key, e.value.toStringAsFixed(0)]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    );
  }
}