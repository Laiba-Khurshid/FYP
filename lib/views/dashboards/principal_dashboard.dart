import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';

import 'package:project/widgets/bottom_navbar.dart';
import 'package:project/widgets/custom_drawer.dart';
import 'package:project/widgets/quick_action_card.dart';
import 'package:project/widgets/summary_card.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  int _bottomNavIndex = 0;

  static const List<BottomNavItem> _bottomNavItems = [
    BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    BottomNavItem(icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem_rounded, label: 'Escalations'),
    BottomNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reports'),
    BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  Future<void> _handleRefresh(BuildContext context) {
    return context.read<AuthViewModel>().refreshUserProfile();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature will be available in a future update.',
            style: AppStyles.bodyMedium(color: AppColors.textOnPrimary),
          ),
          backgroundColor: AppColors.textPrimary,
          duration: AppConstants.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
        ),
      );
  }

  Future<void> _handleLogout(AuthViewModel authViewModel) async {
    await authViewModel.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      setState(() => _bottomNavIndex = index);
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed(AppRoutes.complaintsScreen);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.reportsScreen);
      return;
    }
    if (_bottomNavItems[index].label == 'Profile') {
      Navigator.of(context).pushNamed(AppRoutes.profileScreen);
      return;
    }
    _showComingSoon(_bottomNavItems[index].label);
  }

  void _closeDrawerThen(String feature) {
    Navigator.of(context).pop();
    _showComingSoon(feature);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Principal Dashboard', style: AppStyles.heading4()),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notificationsScreen),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
        ],
      ),
      drawer: CustomDrawer(
        userName: user?.fullName ?? 'Principal',
        userRole: 'Principal',
        userEmail: user?.email,
        onLogout: () => _handleLogout(authViewModel),
        menuItems: [
          DrawerMenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard', onTap: () => Navigator.of(context).pop()),
          DrawerMenuItem(icon: Icons.report_problem_outlined, label: 'Final Escalations', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.complaintsScreen);
          }),
          DrawerMenuItem(icon: Icons.bar_chart_outlined, label: 'Reports', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.reportsScreen);
          }),
          DrawerMenuItem(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.notificationsScreen);
          }),
          DrawerMenuItem(icon: Icons.person_outline_rounded, label: 'Profile', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.profileScreen);
          }),
          DrawerMenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.settingsScreen);
          }),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _handleRefresh(context),
        child: user == null
            ? _buildLoadingState()
            : ListView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          children: [
            _PrincipalWelcomeHeader(user: user),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Overview', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildStatsGrid(),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Quick Actions', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildQuickActionsGrid(authViewModel),
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _bottomNavIndex,
        items: _bottomNavItems,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppConstants.paddingMedium,
      mainAxisSpacing: AppConstants.paddingMedium,
      childAspectRatio: 1.35,
      children: const [
        SummaryCard(
          icon: Icons.priority_high_rounded,
          title: 'Final Escalations',
          count: '—',
          accentColor: AppColors.statusEscalated,
        ),
        SummaryCard(
          icon: Icons.bar_chart_rounded,
          title: 'Reports',
          count: '—',
          accentColor: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(AuthViewModel authViewModel) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppConstants.paddingMedium,
      mainAxisSpacing: AppConstants.paddingMedium,
      childAspectRatio: 1.15,
      children: [
        QuickActionCard(
          icon: Icons.report_problem_rounded,
          title: 'Final Escalations',
          color: AppColors.statusEscalated,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.complaintsScreen),
        ),
        QuickActionCard(
          icon: Icons.bar_chart_rounded,
          title: 'Reports',
          color: AppColors.secondary,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.reportsScreen),
        ),
        QuickActionCard(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          color: AppColors.accent,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.notificationsScreen),
        ),
        QuickActionCard(
          icon: Icons.logout_rounded,
          title: 'Logout',
          color: AppColors.error,
          onTap: () => _handleLogout(authViewModel),
        ),
      ],
    );
  }
}

/// Welcome section shown at the top of the Principal dashboard: avatar,
/// name, today's date, and department.
class _PrincipalWelcomeHeader extends StatelessWidget {
  final dynamic user;

  const _PrincipalWelcomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final todayLabel = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.textOnPrimary.withOpacity(0.2),
            backgroundImage: (user.profileImage != null && (user.profileImage as String).isNotEmpty)
                ? NetworkImage(user.profileImage as String)
                : null,
            child: (user.profileImage == null || (user.profileImage as String).isEmpty)
                ? Text(
              (user.fullName as String).isNotEmpty ? (user.fullName as String)[0].toUpperCase() : 'P',
              style: AppStyles.heading2(color: AppColors.textOnPrimary),
            )
                : null,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.fullName}',
                  style: AppStyles.heading4(color: AppColors.textOnPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.department}',
                  style: AppStyles.bodySmall(color: AppColors.textOnPrimary.withOpacity(0.9)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textOnPrimary.withOpacity(0.85)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        todayLabel,
                        style: AppStyles.caption(color: AppColors.textOnPrimary.withOpacity(0.85)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}