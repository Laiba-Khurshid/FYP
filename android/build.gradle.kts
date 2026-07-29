import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});

    @override
    State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
    late final AnimationController _controller;
    late final Animation<double> _fadeAnimation;
    late final Animation<double> _scaleAnimation;
    late final Animation<double> _logoScaleAnimation;
    late final Animation<double> _rotationAnimation;
    late final Animation<Offset> _slideAnimation;

    @override
    void initState() {
        super.initState();

        _controller = AnimationController(
            vsync: this,
        duration: const Duration(milliseconds: 2000),
        );

        _fadeAnimation = CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
        );

        _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
        ),
        );

        _logoScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
        ),
        );

        _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
        ),
        );

        _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
        ).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
        ),
        );

        _controller.forward();
        _resolveInitialRoute();
    }

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
        decoration: const BoxDecoration(
        gradient: AppColors.splashGradient,
        ),
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
        const Spacer(flex: 2),
        _buildLogo(),
        const SizedBox(height: AppConstants.paddingLarge),
        SlideTransition(
            position: _slideAnimation,
            child: Column(
                    children: [
            Text(
                'CS',
                style: AppStyles.splashTitle().copyWith(
                fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        ),
        ),
        const SizedBox(height: 4),
        Text(
            'AssetFlow',
            style: AppStyles.splashTitle().copyWith(
            fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        ),
        ),
        ],
        ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        SlideTransition(
            position: _slideAnimation,
            child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXLarge),
        child: Text(
        'SMART DEPARTMENT ASSET MANAGEMENT SYSTEM',
        textAlign: TextAlign.center,
        style: AppStyles.splashSubtitle().copyWith(
        letterSpacing: 2,
        fontSize: 14,
        ),
        ),
        ),
        ),
        const Spacer(flex: 3),
        Container(
            decoration: BoxDecoration(
                    shape: BoxShape.circle,
        boxShadow: [
        BoxShadow(
            color: AppColors.textOnPrimary.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 5,
        ),
        ],
        ),
        child: const SizedBox(
        height: 30,
        width: 30,
        child: CircularProgressIndicator(
        strokeWidth: 2.6,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
        ),
        ),
        ),
        const SizedBox(height: AppConstants.paddingXLarge),
        FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: Text(
        'CS AssetFlow v1.0',
        textAlign: TextAlign.center,
        style: AppStyles.splashFooter().copyWith(
        letterSpacing: 1,
        ),
        ),
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

    /// CS AssetFlow Logo with your custom logo image
    Widget _buildLogo() {
        return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
            return Transform.scale(
                scale: _logoScaleAnimation.value,
            child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
            ),
            );
        },
        child: Container(
        height: 140,
        width: 140,
        decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
        color: AppColors.textOnPrimary.withValues(alpha: 0.25),
        width: 2,
        ),
        ),
        child: Center(
        child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
        'assets/images/logo.png',   // <--- APNI LOGO YAHAN
        height: 90,
        width: 90,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
        // Agar image load na ho toh fallback (text logo)
        return Container(
            height: 90,
        width: 90,
        decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Text(
            'CS',
            style: TextStyle(
                    fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 1,
        ),
        ),
        Text(
            'AssetFlow',
            style: TextStyle(
                    fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.5,
        ),
        ),
        Container(
            height: 2,
        width: 30,
        decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2),
        ),
        ),
        ],
        ),
        );
    },
        ),
        ),
        ),
        ),
        );
    }
}