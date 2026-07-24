import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
/// Premium animated splash screen shown when AssetFlow launches.
///
/// Displays the app identity (name, tagline, organization) with a
/// combined fade + scale animation for at least [AppConstants.splashDuration],
/// while [AuthViewModel.tryAutoLogin] checks for a remembered session in
/// the background. Navigates to a role-based dashboard if a session was
/// restored, or to the login screen otherwise.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _logoRotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.fadeAnimationDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _resolveInitialRoute();
  }

  /// Waits for both the minimum splash duration and the auto-login
  /// check to complete (whichever takes longer), then routes to the
  /// appropriate screen.
  Future<void> _resolveInitialRoute() async {
    final authViewModel = context.read<AuthViewModel>();

    await Future.wait<void>([
      Future.delayed(AppConstants.splashDuration),
      authViewModel.tryAutoLogin(),
    ]);

    if (!mounted) return;

    if (authViewModel.isAuthenticated && authViewModel.currentUser != null) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.dashboardForRole(authViewModel.currentUser!.role),
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                _buildLogo(),
                const SizedBox(height: AppConstants.paddingLarge),
                Text(
                  AppConstants.appName,
                  style: AppStyles.splashTitle(),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXLarge),
                  child: Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: AppStyles.splashSubtitle(),
                  ),
                ),
                const Spacer(flex: 3),
                const SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXLarge),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                  child: Text(
                    AppConstants.organizationName,
                    textAlign: TextAlign.center,
                    style: AppStyles.splashFooter(),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Professional logo placeholder built purely from shapes/icons.
  ///
  /// Will be replaced with the department's official branded logo asset
  /// once supplied; kept as a vector-based placeholder so the splash
  /// screen renders correctly without depending on external image files.
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _logoRotation.value,
          child: child,
        );
      },
      child: Container(
        height: 110,
        width: 110,
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textOnPrimary.withOpacity(0.4), width: 1.5),
        ),
        child: Center(
          child: Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textOnPrimary.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
