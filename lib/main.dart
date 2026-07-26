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

import 'package:project/views/common/error_screen.dart';
import 'package:project/views/common/loading_screen.dart';

/// Entry point of the AssetFlow application.
///
/// Responsible for:
/// - Ensuring Flutter bindings are initialized before any async work.
/// - Initializing Firebase using the platform-specific options.
/// - Bootstrapping the app's [MultiProvider] tree (empty for now; state
///   management providers for auth, assets, complaints, etc. will be
///   registered here as each module is implemented).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AssetFlowBootstrap());
}

/// Handles asynchronous Firebase initialization and shows a loading or
/// error screen while that initialization is in progress, before
/// mounting the real [AssetFlowApp].
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
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: FutureBuilder<FirebaseApp>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen(message: 'Starting AssetFlow...');
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

/// The root widget of AssetFlow once Firebase has initialized
/// successfully. Configures the [MultiProvider] tree, MD3 theming, and
/// named-route based navigation.
class AssetFlowApp extends StatelessWidget {
  const AssetFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(authService: AuthService()),
        ),
        ChangeNotifierProvider<AssetViewModel>(
          create: (_) => AssetViewModel(assetService: AssetService()),
        ),
        ChangeNotifierProvider<ComplaintViewModel>(
          create: (_) => ComplaintViewModel(complaintService: ComplaintService()),
        ),
        ChangeNotifierProvider<MaintenanceViewModel>(
          create: (_) => MaintenanceViewModel(
            maintenanceService: MaintenanceService(),
            complaintService: ComplaintService(),
          ),
        ),
        ChangeNotifierProvider<NotificationViewModel>(
          create: (_) => NotificationViewModel(notificationService: NotificationService()),
        ),
        ChangeNotifierProvider<ReportViewModel>(
          create: (_) => ReportViewModel(reportService: ReportService()),
        ),
        ChangeNotifierProvider<ProfileViewModel>(
          create: (_) => ProfileViewModel(profileService: ProfileService()),
        ),
        ChangeNotifierProvider<AuditViewModel>(
          create: (_) => AuditViewModel(auditService: AuditService()),
        ),
        ChangeNotifierProvider<AdminToolsViewModel>(
          create: (_) => AdminToolsViewModel(adminToolsService: AdminToolsService()),
        ),
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => ThemeViewModel()..loadThemeMode(),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeViewModel.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}

/// Builds the light [ThemeData] for AssetFlow using Material Design 3.
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

/// Builds the "dark" [ThemeData] for AssetFlow.
///
/// Currently identical to [_buildLightTheme]. The custom widget library
/// throughout this app (cards, dropdowns, chips, dialogs, etc.) is
/// built on fixed [AppColors] brand constants rather than
/// [Theme.of(context).colorScheme], so a genuinely divergent dark theme
/// would leave Flutter's built-in chrome (Scaffold, AppBar) dark while
/// every custom surface stayed light-colored — exactly the "black,
/// unreadable text" bug this was causing. Keeping both themes identical
/// removes that mismatch entirely (regardless of device system theme or
/// the in-app Settings selection) until the design system is refactored
/// to be theme-aware.
ThemeData _buildDarkTheme() => _buildLightTheme();