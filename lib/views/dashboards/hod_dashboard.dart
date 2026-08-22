import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/notification_viewmodel.dart';

import 'package:project/widgets/bottom_navbar.dart';
import 'package:project/widgets/custom_drawer.dart';
import 'package:project/widgets/quick_action_card.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  int _bottomNavIndex = 0;

  static const List<BottomNavItem> _bottomNavItems = [
    BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    BottomNavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Assets'),
    BottomNavItem(icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem_rounded, label: 'Complaints'),
    BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<NotificationViewModel>().subscribe(uid: user.uid, role: user.role);
      }
    });
  }

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
      Navigator.of(context).pushNamed(AppRoutes.assetsScreen);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed(AppRoutes.complaintsScreen);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.profileScreen);
      return;
    }
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
        title: Text('HOD Dashboard', style: AppStyles.heading4()),
        actions: [
          // ============================================================
          // NOTIFICATION ICON WITH GREEN BADGE
          // ============================================================
          Consumer<NotificationViewModel>(
            builder: (context, notificationVM, child) {
              final unreadCount = notificationVM.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.notificationsScreen),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: AppConstants.paddingSmall),
        ],
      ),
      drawer: CustomDrawer(
        userName: user?.fullName ?? 'HOD',
        userRole: 'Head of Department',
        userEmail: user?.email,
        onLogout: () => _handleLogout(authViewModel),
        menuItems: [
          DrawerMenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard', onTap: () => Navigator.of(context).pop()),
          DrawerMenuItem(icon: Icons.inventory_2_outlined, label: 'Department Assets', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.assetsScreen);
          }),
          DrawerMenuItem(icon: Icons.report_problem_outlined, label: 'Department Complaints', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.complaintsScreen);
          }),
          DrawerMenuItem(icon: Icons.build_outlined, label: 'Maintenance', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.maintenanceList);
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
            _HodWelcomeHeader(user: user),
            const SizedBox(height: AppConstants.paddingLarge),
            // ============================================================
            // DEPARTMENT OVERVIEW REMOVED
            // ============================================================
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

  Widget _buildQuickActionsGrid(AuthViewModel authViewModel) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppConstants.paddingMedium,
      mainAxisSpacing: AppConstants.paddingMedium,
      childAspectRatio: 1.3,
      children: [
        QuickActionCard(
          icon: Icons.inventory_2_rounded,
          title: 'Department Assets',
          color: AppColors.primary,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.assetsScreen),
        ),
        QuickActionCard(
          icon: Icons.report_problem_rounded,
          title: 'Complaints',
          color: AppColors.statusPending,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.complaintsScreen),
        ),
        QuickActionCard(
          icon: Icons.build_rounded,
          title: 'Maintenance',
          color: AppColors.statusInProgress,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.maintenanceList),
        ),
        QuickActionCard(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          color: AppColors.accent,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.notificationsScreen),
        ),
        QuickActionCard(
          icon: Icons.person_rounded,
          title: 'Profile',
          color: AppColors.info,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileScreen),
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

/// Welcome section shown at the top of the HOD dashboard: avatar, name,
/// today's date, and department.
class _HodWelcomeHeader extends StatelessWidget {
  final dynamic user;

  const _HodWelcomeHeader({required this.user});

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
            backgroundColor: AppColors.textOnPrimary.withValues(alpha: 0.2),
            backgroundImage: (user.profileImage != null && (user.profileImage as String).isNotEmpty)
                ? NetworkImage(user.profileImage as String)
                : null,
            child: (user.profileImage == null || (user.profileImage as String).isEmpty)
                ? Text(
              (user.fullName as String).isNotEmpty ? (user.fullName as String)[0].toUpperCase() : 'H',
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
                  style: AppStyles.bodySmall(color: AppColors.textOnPrimary.withValues(alpha: 0.9)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textOnPrimary.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        todayLabel,
                        style: AppStyles.caption(color: AppColors.textOnPrimary.withValues(alpha: 0.85)),
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