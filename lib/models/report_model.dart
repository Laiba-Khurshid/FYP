
class ReportModel {
  final String reportType;
  final DateTime generatedAt;

  // --- Assets report ---
  final int totalAssets;
  final Map<String, int> assetsByLab;
  final Map<String, int> assetsByCategory;

  // --- Complaints report ---
  final int totalComplaints;
  final Map<String, int> complaintsByStatus;
  final Map<String, int> complaintsByLab;
  final Map<String, int> complaintsByPriority;

  // --- Maintenance report ---
  final int totalMaintenanceRecords;
  final Map<String, int> maintenanceByStatus;
  final Map<String, double> maintenanceCostByType;
  final double totalMaintenanceCost;

  // --- Users report ---
  final int totalUsers;
  final Map<String, int> usersByRole;

  const ReportModel({
    required this.reportType,
    required this.generatedAt,
    this.totalAssets = 0,
    this.assetsByLab = const {},
    this.assetsByCategory = const {},
    this.totalComplaints = 0,
    this.complaintsByStatus = const {},
    this.complaintsByLab = const {},
    this.complaintsByPriority = const {},
    this.totalMaintenanceRecords = 0,
    this.maintenanceByStatus = const {},
    this.maintenanceCostByType = const {},
    this.totalMaintenanceCost = 0,
    this.totalUsers = 0,
    this.usersByRole = const {},
  });
}