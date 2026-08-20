import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:project/routes/app_routes.dart';
import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';
import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/user_viewmodel.dart';
import 'package:project/widgets/bottom_navbar.dart';
import 'package:project/widgets/custom_drawer.dart';
import 'package:project/widgets/dashboard_card.dart';
import 'package:project/widgets/quick_action_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _bottomNavIndex = 0;

  static const List<BottomNavItem> _bottomNavItems = [
    BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    BottomNavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Assets'),
    BottomNavItem(icon: Icons.assessment_outlined, activeIcon: Icons.assessment_rounded, label: 'Reports'),
    BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userViewModel = context.read<UserViewModel>();
      userViewModel.subscribe();
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
          backgroundColor: AppColors.primary,
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
      Navigator.of(context).pushNamed(AppRoutes.reportsScreen);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed(AppRoutes.profileScreen);
      return;
    }
  }

  void _navigateToRoute(String routeName, String featureName) {
    try {
      Navigator.of(context).pushNamed(routeName);
    } catch (e) {
      _showComingSoon(featureName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final userViewModel = context.watch<UserViewModel>();
    final pendingCount = userViewModel.pendingUsersCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Asset Manager Dashboard', style: AppStyles.heading4()),
        actions: [
          // ============================================================
          // NOTIFICATION ICON - ADDED
          // ============================================================
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notificationsScreen),
          ),
          // ============================================================
          // PENDING USERS BADGE
          // ============================================================
          if (pendingCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.verified_user_outlined),
                  onPressed: () => _navigateToRoute(
                    AppRoutes.verifyUsersScreen,
                    'Verify Users',
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.verified_user_outlined),
              onPressed: () => _navigateToRoute(
                AppRoutes.verifyUsersScreen,
                'Verify Users',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () => _navigateToRoute(
              AppRoutes.reportsScreen,
              'Reports',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigateToRoute(
              AppRoutes.settingsScreen,
              'Settings',
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
        ],
      ),
      drawer: CustomDrawer(
        userName: user?.fullName ?? 'Asset Manager',
        userRole: 'Asset Manager',
        userEmail: user?.email,
        onLogout: () => _handleLogout(authViewModel),
        menuItems: [
          DrawerMenuItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          DrawerMenuItem(
            icon: Icons.verified_user_outlined,
            label: 'Verify Users',
            onTap: () {
              Navigator.of(context).pop();
              _navigateToRoute(AppRoutes.verifyUsersScreen, 'Verify Users');
            },
          ),
          DrawerMenuItem(
            icon: Icons.history_rounded,
            label: 'Audit History',
            onTap: () {
              Navigator.of(context).pop();
              _navigateToRoute(AppRoutes.auditHistoryScreen, 'Audit History');
            },
          ),
          DrawerMenuItem(
            icon: Icons.assessment_outlined,
            label: 'Reports',
            onTap: () {
              Navigator.of(context).pop();
              _navigateToRoute(AppRoutes.reportsScreen, 'Reports');
            },
          ),
          DrawerMenuItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () {
              Navigator.of(context).pop();
              _navigateToRoute(AppRoutes.profileScreen, 'Profile');
            },
          ),
          DrawerMenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).pop();
              _navigateToRoute(AppRoutes.settingsScreen, 'Settings');
            },
          ),
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
            _AdminWelcomeHeader(user: user),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Quick Actions', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildQuickActionsGrid(),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Management', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingMedium),
            DashboardCard(
              icon: Icons.verified_user_outlined,
              title: 'Verify Users',
              subtitle: pendingCount > 0
                  ? '$pendingCount pending registration${
                  pendingCount > 1 ? 's' : ''
              } waiting for approval'
                  : 'Approve or reject pending registrations',
              iconColor: pendingCount > 0 ? AppColors.error : AppColors.info,
              onTap: () => _navigateToRoute(
                AppRoutes.verifyUsersScreen,
                'Verify Users',
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            DashboardCard(
              icon: Icons.assessment_outlined,
              title: 'Reports',
              subtitle: 'View detailed reports and analytics',
              iconColor: AppColors.secondary,
              onTap: () => _navigateToRoute(
                AppRoutes.reportsScreen,
                'Reports',
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            DashboardCard(
              icon: Icons.history_rounded,
              title: 'Audit History',
              subtitle: 'View a log of important system activity',
              iconColor: AppColors.info,
              onTap: () => _navigateToRoute(
                AppRoutes.auditHistoryScreen,
                'Audit History',
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            DashboardCard(
              icon: Icons.person_outline_rounded,
              title: 'Profile',
              subtitle: 'View and edit your account details',
              iconColor: AppColors.primary,
              onTap: () => _navigateToRoute(
                AppRoutes.profileScreen,
                'Profile',
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            DashboardCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'App settings, theme, and about',
              iconColor: AppColors.accent,
              onTap: () => _navigateToRoute(
                AppRoutes.settingsScreen,
                'Settings',
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            DashboardCard(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              iconColor: AppColors.error,
              onTap: () => _handleLogout(authViewModel),
            ),
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

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppConstants.paddingMedium,
      mainAxisSpacing: AppConstants.paddingMedium,
      childAspectRatio: 1.15,
      children: [
        QuickActionCard(
          icon: Icons.inventory_2_rounded,
          title: 'View Assets',
          subtitle: 'Browse all assets',
          color: AppColors.primary,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.assetsScreen),
        ),
        QuickActionCard(
          icon: Icons.verified_user_outlined,
          title: 'Verify Users',
          subtitle: 'Approve registrations',
          color: AppColors.secondary,
          onTap: () => _navigateToRoute(
            AppRoutes.verifyUsersScreen,
            'Verify Users',
          ),
        ),
        QuickActionCard(
          icon: Icons.assessment_outlined,
          title: 'Reports',
          subtitle: 'View analytics',
          color: AppColors.info,
          onTap: () => _navigateToRoute(
            AppRoutes.reportsScreen,
            'Reports',
          ),
        ),
        QuickActionCard(
          icon: Icons.history_rounded,
          title: 'Audit History',
          subtitle: 'View system logs',
          color: AppColors.accent,
          onTap: () => _navigateToRoute(
            AppRoutes.auditHistoryScreen,
            'Audit History',
          ),
        ),
        QuickActionCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App settings',
          color: AppColors.primary,
          onTap: () => _navigateToRoute(
            AppRoutes.settingsScreen,
            'Settings',
          ),
        ),
      ],
    );
  }
}

/// Welcome section shown at the top of the Admin dashboard.
class _AdminWelcomeHeader extends StatelessWidget {
  final dynamic user;

  const _AdminWelcomeHeader({required this.user});

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
            backgroundImage: (user.profileImage != null &&
                (user.profileImage as String).isNotEmpty)
                ? NetworkImage(user.profileImage as String)
                : null,
            child: (user.profileImage == null ||
                (user.profileImage as String).isEmpty)
                ? Text(
              (user.fullName as String).isNotEmpty
                  ? (user.fullName as String)[0].toUpperCase()
                  : 'A',
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
                  'Asset Manager • ${user.department}',
                  style: AppStyles.bodySmall(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        todayLabel,
                        style: AppStyles.caption(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                        ),
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