/// Centralized application constants for AssetFlow.
///
/// Grouping constants here avoids magic numbers/strings scattered across
/// the codebase and gives a single source of truth for values that are
/// reused by multiple modules (auth, assets, complaints, maintenance,
/// reports, notifications, profile).
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------
  // App metadata
  // ---------------------------------------------------------------------
  static const String appName = 'AssetFlow';
  static const String appTagline = 'Smart Department Asset Management System';
  static const String organizationName =
      'IMCG F/6-2 Islamabad Model College for Girls';
  static const String departmentName = 'BS Computer Science Department';
  static const int totalLabs = 10;
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 1200);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 1000);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration debounceDuration = Duration(milliseconds: 500);

  // ---------------------------------------------------------------------
  // Spacing & sizing
  // ---------------------------------------------------------------------
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  static const double buttonHeight = 52.0;
  static const double textFieldHeight = 56.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // ---------------------------------------------------------------------
  // Firestore collection names (referenced by future services)
  // ---------------------------------------------------------------------
  static const String usersCollection = 'users';
  static const String assetsCollection = 'assets';
  static const String complaintsCollection = 'complaints';
  static const String maintenanceCollection = 'maintenance';
  static const String reportsCollection = 'reports';
  static const String notificationsCollection = 'notifications';
  static const String escalationsCollection = 'escalations';
  static const String auditLogsCollection = 'audit_logs';
  static const String authenticatedUsersCollection = 'authenticated_users';

  // ---------------------------------------------------------------------
  // Account verification status
  // ---------------------------------------------------------------------
  // New signups start Pending and cannot log in until an Admin approves
  // them via the Verify Users screen. Accounts created before this
  // feature existed have no stored status and are treated as Approved
  // (see UserModel.fromMap) so existing users are never locked out.
  static const String verificationPending = 'pending';
  static const String verificationApproved = 'approved';
  static const String verificationRejected = 'rejected';

  // ---------------------------------------------------------------------
  // Shared preferences keys
  // ---------------------------------------------------------------------
  static const String prefKeyIsLoggedIn = 'is_logged_in';
  static const String prefKeyUserRole = 'user_role';
  static const String prefKeyUserId = 'user_id';
  static const String prefKeyThemeMode = 'theme_mode';

  // ---------------------------------------------------------------------
  // User roles
  // ---------------------------------------------------------------------
  static const String roleAdmin = 'admin';
  static const String roleHOD = 'hod';
  static const String roleVicePrincipal = 'vice_principal';
  static const String rolePrincipal = 'principal';
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';
  static const List<String> allRoles = [
    roleAdmin,
    roleHOD,
    roleVicePrincipal,
    rolePrincipal,
    roleTeacher,
    roleStudent,
  ];

  // ---------------------------------------------------------------------
  // Complaint status values
  // ---------------------------------------------------------------------
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';
  static const String statusEscalated = 'escalated';

  // ---------------------------------------------------------------------
  // Complaint priority values
  // ---------------------------------------------------------------------
  static const String priorityLow = 'Low';
  static const String priorityMedium = 'Medium';
  static const String priorityHigh = 'High';
  static const List<String> complaintPriorities = [priorityLow, priorityMedium, priorityHigh];

  // ---------------------------------------------------------------------
  // Escalation levels
  // ---------------------------------------------------------------------
  // 0 = newly filed, assigned to HOD.
  // 1 = HOD did not resolve in time / escalated to Vice Principal.
  // 2 = final escalation, visible to the Principal.
  static const int escalationLevelNone = 0;
  static const int escalationLevelVicePrincipal = 1;
  static const int escalationLevelPrincipal = 2;

  // ---------------------------------------------------------------------
  // Maintenance status values
  // ---------------------------------------------------------------------
  static const String maintenanceStatusPending = 'Pending';
  static const String maintenanceStatusAssigned = 'Assigned';
  static const String maintenanceStatusInProgress = 'In Progress';
  static const String maintenanceStatusCompleted = 'Completed';
  static const String maintenanceStatusCancelled = 'Cancelled';
  static const List<String> maintenanceStatuses = [
    maintenanceStatusPending,
    maintenanceStatusAssigned,
    maintenanceStatusInProgress,
    maintenanceStatusCompleted,
    maintenanceStatusCancelled,
  ];

  // ---------------------------------------------------------------------
  // Maintenance types
  // ---------------------------------------------------------------------
  static const String maintenanceTypeRepair = 'Repair';
  static const String maintenanceTypeReplacement = 'Replacement';
  static const String maintenanceTypeInspection = 'Inspection';
  static const String maintenanceTypeCleaning = 'Cleaning';
  static const String maintenanceTypeSoftwareInstallation = 'Software Installation';
  static const String maintenanceTypeHardwareUpgrade = 'Hardware Upgrade';
  static const List<String> maintenanceTypes = [
    maintenanceTypeRepair,
    maintenanceTypeReplacement,
    maintenanceTypeInspection,
    maintenanceTypeCleaning,
    maintenanceTypeSoftwareInstallation,
    maintenanceTypeHardwareUpgrade,
  ];

  // ---------------------------------------------------------------------
  // Firebase Storage paths
  // ---------------------------------------------------------------------
  static const String assetImagesStoragePath = 'asset_images';
  static const String complaintImagesStoragePath = 'complaint_images';

  // ---------------------------------------------------------------------
  // Notification types
  // ---------------------------------------------------------------------
  static const String notificationTypeComplaintSubmitted = 'complaint_submitted';
  static const String notificationTypeComplaintUpdated = 'complaint_updated';
  static const String notificationTypeComplaintResolved = 'complaint_resolved';
  static const String notificationTypeComplaintEscalated = 'complaint_escalated';
  static const String notificationTypeMaintenanceCreated = 'maintenance_created';
  static const String notificationTypeMaintenanceCompleted = 'maintenance_completed';

  // ---------------------------------------------------------------------
  // Audit log modules and actions
  // ---------------------------------------------------------------------
  static const String auditModuleAsset = 'Asset';
  static const String auditModuleComplaint = 'Complaint';
  static const String auditModuleMaintenance = 'Maintenance';
  static const String auditModuleProfile = 'Profile';

  static const String auditActionAssetAdded = 'Asset Added';
  static const String auditActionAssetUpdated = 'Asset Updated';
  static const String auditActionAssetDeleted = 'Asset Deleted';
  static const String auditActionComplaintSubmitted = 'Complaint Submitted';
  static const String auditActionComplaintUpdated = 'Complaint Updated';
  static const String auditActionComplaintResolved = 'Complaint Resolved';
  static const String auditActionComplaintEscalated = 'Complaint Escalated';
  static const String auditActionMaintenanceAdded = 'Maintenance Added';
  static const String auditActionMaintenanceUpdated = 'Maintenance Updated';
  static const String auditActionMaintenanceCompleted = 'Maintenance Completed';
  static const String auditActionUserProfileUpdated = 'User Profile Updated';

  // ---------------------------------------------------------------------
  // Report types
  // ---------------------------------------------------------------------
  static const String reportTypeAssets = 'assets';
  static const String reportTypeComplaints = 'complaints';
  static const String reportTypeMaintenance = 'maintenance';
  static const String reportTypeUsers = 'users';

  // ---------------------------------------------------------------------
  // Validation limits
  // ---------------------------------------------------------------------
  static const int minPasswordLength = 8;
  static const int maxNameLength = 60;
  static const int maxDescriptionLength = 500;
}