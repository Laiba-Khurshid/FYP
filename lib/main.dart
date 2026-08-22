import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:project/firebase_options.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/services/admin_tools_service.dart';
import 'package:project/services/asset_service.dart';
import 'package:project/services/audit_service.dart';
import 'package:project/services/auth_services.dart';
import 'package:project/services/complaint_service.dart';
import 'package:project/services/maintenance_service.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/services/profile_service.dart';
import 'package:project/services/report_service.dart';
import 'package:project/services/user_service.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';

import 'package:project/viewmodels/admin_tools_viewmodel.dart';
import 'package:project/viewmodels/asset_viewmodel.dart';
import 'package:project/viewmodels/audit_viewmodel.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/complaint_viewmodel.dart';
import 'package:project/viewmodels/maintenance_viewmodel.dart';
import 'package:project/viewmodels/notification_viewmodel.dart';
import 'package:project/viewmodels/profile_viewmodel.dart';
import 'package:project/viewmodels/report_viewmodel.dart';
import 'package:project/viewmodels/theme_viewmodel.dart';
import 'package:project/viewmodels/user_viewmodel.dart';

import 'package:project/views/common/error_screen.dart';
import 'package:project/views/common/loading_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AssetFlowBootstrap());
}


class AssetFlowBootstrap extends StatefulWidget {
  const AssetFlowBootstrap({super.key});

  @override
  State<AssetFlowBootstrap> createState() => _AssetFlowBootstrapState();
}

class _AssetFlowBootstrapState extends State<AssetFlowBootstrap> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _retry() {
    setState(() {
      _initialization = _initializeFirebase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: _buildLightTheme(),
      home: FutureBuilder<FirebaseApp>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen(message: 'Starting CS AssetFlow');
          }
          if (snapshot.hasError) {
            return ErrorScreen(
              title: 'Initialization Failed',
              message: 'AssetFlow could not connect to required services. '
                  'Please check your internet connection and try again.',
              onRetry: _retry,
            );
          }
          return const AssetFlowApp();
        },
      ),
    );
  }
}

class AssetFlowApp extends StatelessWidget {
  const AssetFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ============================================================
        // SERVICES
        // ============================================================
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<AssetService>(
          create: (_) => AssetService(),
        ),
        Provider<ComplaintService>(
          create: (_) => ComplaintService(),
        ),
        Provider<MaintenanceService>(
          create: (_) => MaintenanceService(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        Provider<ProfileService>(
          create: (_) => ProfileService(),
        ),
        Provider<ReportService>(
          create: (_) => ReportService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<AdminToolsService>(
          create: (_) => AdminToolsService(),
        ),
        Provider<AuditService>(
          create: (_) => AuditService(),
        ),

        // ============================================================
        // VIEWMODELS
        // ============================================================
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => ThemeViewModel()..loadThemeMode(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<AssetViewModel>(
          create: (context) => AssetViewModel(
            assetService: context.read<AssetService>(),
          ),
        ),
        ChangeNotifierProvider<ComplaintViewModel>(
          create: (context) => ComplaintViewModel(
            complaintService: context.read<ComplaintService>(),
          ),
        ),
        ChangeNotifierProvider<MaintenanceViewModel>(
          create: (context) => MaintenanceViewModel(
            maintenanceService: context.read<MaintenanceService>(),
            complaintService: context.read<ComplaintService>(),
          ),
        ),
        ChangeNotifierProvider<NotificationViewModel>(
          create: (context) => NotificationViewModel(
            notificationService: context.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<ReportViewModel>(
          create: (context) => ReportViewModel(
            reportService: context.read<ReportService>(),
          ),
        ),
        ChangeNotifierProvider<ProfileViewModel>(
          create: (context) => ProfileViewModel(
            profileService: context.read<ProfileService>(),
          ),
        ),
        ChangeNotifierProvider<UserViewModel>(
          create: (context) => UserViewModel(
            userService: context.read<UserService>(),
          ),
        ),
        ChangeNotifierProvider<AuditViewModel>(
          create: (context) => AuditViewModel(
            auditService: context.read<AuditService>(),
          ),
        ),
        ChangeNotifierProvider<AdminToolsViewModel>(
          create: (context) => AdminToolsViewModel(
            adminToolsService: context.read<AdminToolsService>(),
          ),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}

// ================================================================
// LIGHT THEME
// ================================================================
ThemeData _buildLightTheme() {
  final baseTextTheme = GoogleFonts.poppinsTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide.none,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    fontFamily: GoogleFonts.poppins().fontFamily,
  );
}