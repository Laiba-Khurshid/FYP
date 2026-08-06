import 'package:flutter/material.dart';

import 'package:project/models/asset_model.dart';
import 'package:project/models/complaint_model.dart';
import 'package:project/models/maintenance_model.dart';
import 'package:project/models/report_model.dart';

import 'package:project/core/utils/app_constants.dart';

import 'package:project/views/auth/splash_screen.dart';
import 'package:project/views/auth/login_screen.dart';
import 'package:project/views/auth/signup_screen.dart';
import 'package:project/views/auth/forgot_password_screen.dart';

import 'package:project/views/common/error_screen.dart';

import 'package:project/views/dashboards/admin_dashboard.dart';
import 'package:project/views/dashboards/hod_dashboard.dart';
import 'package:project/views/dashboards/vp_dashboard.dart';
import 'package:project/views/dashboards/principal_dashboard.dart';
import 'package:project/views/dashboards/staff_dashboard.dart';
import 'package:project/views/dashboards/student_dashboard.dart';

import 'package:project/views/assets/asset_screen.dart';
import 'package:project/views/assets/add_asset_screen.dart';
import 'package:project/views/assets/edit_asset_screen.dart';
import 'package:project/views/assets/asset_details_screen.dart';

import 'package:project/views/complaints/complaints_screen.dart';
import 'package:project/views/complaints/submit_complaint_screen.dart';
import 'package:project/views/complaints/complaint_details_screen.dart';

import 'package:project/views/maintenance/maintenance_list_screen.dart';
import 'package:project/views/maintenance/add_maintenance_screen.dart';
import 'package:project/views/maintenance/edit_maintenance_screen.dart';
import 'package:project/views/maintenance/maintenance_details_screen.dart';

import 'package:project/views/reports/reports_screen.dart';
import 'package:project/views/reports/report_details_screen.dart';

import 'package:project/views/notifications/notifications_screen.dart';

import 'package:project/views/profile/profile_screen.dart';
import 'package:project/views/profile/edit_profile_screen.dart';

import 'package:project/views/settings/setting_screen.dart';  // FIXED: settings_screen (s ke saath)

import 'package:project/views/audit/audit_history_screen.dart';

import 'package:project/views/asset_manager/verify_user_screen.dart';  // FIXED: verify_users_screen (plural)

class AppRoutes {
  AppRoutes._();

  // ---------------------------------------------------------------------
  // Route name constants
  // ---------------------------------------------------------------------
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  static const String adminDashboard = '/admin-dashboard';
  static const String hodDashboard = '/hod-dashboard';
  static const String vicePrincipalDashboard = '/vice-principal-dashboard';
  static const String principalDashboard = '/principal-dashboard';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String studentDashboard = '/student-dashboard';

  static const String assetsScreen = '/assets';
  static const String addAsset = '/add-asset';
  static const String editAsset = '/edit-asset';
  static const String assetDetails = '/asset-details';

  static const String complaintsScreen = '/complaints';
  static const String addComplaint = '/add-complaint';
  static const String complaintDetails = '/complaint-details';

  static const String maintenanceList = '/maintenance';
  static const String addMaintenance = '/add-maintenance';
  static const String editMaintenance = '/edit-maintenance';
  static const String maintenanceDetails = '/maintenance-details';

  static const String reportsScreen = '/reports';
  static const String reportDetails = '/report-details';

  static const String notificationsScreen = '/notifications';

  static const String profileScreen = '/profile';
  static const String editProfile = '/edit-profile';

  static const String settingsScreen = '/settings';  // ✅ ADDED

  static const String auditHistoryScreen = '/audit-history';

  static const String verifyUsersScreen = '/verify-users';

  static String dashboardForRole(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return adminDashboard;
      case AppConstants.roleHOD:
        return hodDashboard;
      case AppConstants.roleVicePrincipal:
        return vicePrincipalDashboard;
      case AppConstants.rolePrincipal:
        return principalDashboard;
      case AppConstants.roleTeacher:
        return teacherDashboard;
      case AppConstants.roleStudent:
        return studentDashboard;
      default:
        return studentDashboard;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case signup:
        return _buildRoute(const SignupScreen(), settings);

      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      case adminDashboard:
        return _buildRoute(const AdminDashboard(), settings);

      case hodDashboard:
        return _buildRoute(const HodDashboard(), settings);

      case vicePrincipalDashboard:
        return _buildRoute(const VicePrincipalDashboard(), settings);

      case principalDashboard:
        return _buildRoute(const PrincipalDashboard(), settings);

      case teacherDashboard:
        return _buildRoute(const TeacherDashboard(), settings);

      case studentDashboard:
        return _buildRoute(const StudentDashboard(), settings);

      case assetsScreen:
        return _buildRoute(const AssetsScreen(), settings);

      case addAsset:
        return _buildRoute(const AddAssetScreen(), settings);

      case editAsset:
        return _buildAssetArgumentRoute(
          settings,
          builder: (asset) => EditAssetScreen(asset: asset),
        );

      case assetDetails:
        return _buildAssetArgumentRoute(
          settings,
          builder: (asset) => AssetDetailsScreen(asset: asset),
        );

      case complaintsScreen:
        return _buildRoute(const ComplaintsScreen(), settings);

      case addComplaint:
        return _buildRoute(const AddComplaintScreen(), settings);

      case complaintDetails:
        return _buildComplaintArgumentRoute(
          settings,
          builder: (complaint) => ComplaintDetailsScreen(complaint: complaint),
        );

      case maintenanceList:
        return _buildRoute(const MaintenanceListScreen(), settings);

      case addMaintenance:
        final complaint = settings.arguments;
        if (complaint is! ComplaintModel) {
          return _buildRoute(
            const ErrorScreen(
              title: 'Complaint Not Found',
              message: 'No complaint was provided to create a maintenance record for.',
              icon: Icons.search_off_rounded,
            ),
            settings,
          );
        }
        return _buildRoute(AddMaintenanceScreen(complaint: complaint), settings);

      case editMaintenance:
        return _buildMaintenanceArgumentRoute(
          settings,
          builder: (record) => EditMaintenanceScreen(record: record),
        );

      case maintenanceDetails:
        return _buildMaintenanceArgumentRoute(
          settings,
          builder: (record) => MaintenanceDetailsScreen(record: record),
        );

      case reportsScreen:
        return _buildRoute(const ReportsScreen(), settings);

      case reportDetails:
        final report = settings.arguments;
        if (report is! ReportModel) {
          return _buildRoute(
            const ErrorScreen(
              title: 'Report Not Found',
              message: 'No report was provided for this screen.',
              icon: Icons.search_off_rounded,
            ),
            settings,
          );
        }
        return _buildRoute(ReportDetailsScreen(report: report), settings);

      case notificationsScreen:
        return _buildRoute(const NotificationScreen(), settings);

      case profileScreen:
        return _buildRoute(const ProfileScreen(), settings);

      case editProfile:
        return _buildRoute(const EditProfileScreen(), settings);

    // ============================================================
    // SETTINGS SCREEN ROUTE - YEH HONA CHAHIYE
    // ============================================================
      case settingsScreen:
        return _buildRoute(const SettingsScreen(), settings);

      case auditHistoryScreen:
        return _buildRoute(const AuditHistoryScreen(), settings);

      case verifyUsersScreen:
        return _buildRoute(const VerifyUsersScreen(), settings);

      default:
        return _buildRoute(
          ErrorScreen(
            title: 'Page Not Found',
            message: 'The route "${settings.name}" does not exist.',
            icon: Icons.search_off_rounded,
          ),
          settings,
        );
    }
  }

  static PageRoute<dynamic> _buildRoute(Widget screen, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => screen,
      settings: settings,
    );
  }

  static PageRoute<dynamic> _buildAssetArgumentRoute(
      RouteSettings settings, {
        required Widget Function(AssetModel asset) builder,
      }) {
    final asset = settings.arguments;
    if (asset is! AssetModel) {
      return _buildRoute(
        const ErrorScreen(
          title: 'Asset Not Found',
          message: 'No asset was provided for this screen.',
          icon: Icons.search_off_rounded,
        ),
        settings,
      );
    }
    return _buildRoute(builder(asset), settings);
  }

  static PageRoute<dynamic> _buildComplaintArgumentRoute(
      RouteSettings settings, {
        required Widget Function(ComplaintModel complaint) builder,
      }) {
    final complaint = settings.arguments;
    if (complaint is! ComplaintModel) {
      return _buildRoute(
        const ErrorScreen(
          title: 'Complaint Not Found',
          message: 'No complaint was provided for this screen.',
          icon: Icons.search_off_rounded,
        ),
        settings,
      );
    }
    return _buildRoute(builder(complaint), settings);
  }

  static PageRoute<dynamic> _buildMaintenanceArgumentRoute(
      RouteSettings settings, {
        required Widget Function(MaintenanceModel record) builder,
      }) {
    final record = settings.arguments;
    if (record is! MaintenanceModel) {
      return _buildRoute(
        const ErrorScreen(
          title: 'Maintenance Record Not Found',
          message: 'No maintenance record was provided for this screen.',
          icon: Icons.search_off_rounded,
        ),
        settings,
      );
    }
    return _buildRoute(builder(record), settings);
  }
}