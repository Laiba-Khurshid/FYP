import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/routes/app_routes.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/core/utils/app_constants.dart';
import 'package:project/core/utils/app_styles.dart';

import 'package:project/viewmodels/auth_viewmodel.dart';
import 'package:project/viewmodels/report_viewmodel.dart';

import 'package:project/widgets/bottom_navbar.dart';
import 'package:project/widgets/custom_drawer.dart';
import 'package:project/widgets/dashboard_stat_card.dart';
import 'package:project/widgets/quick_action_card.dart';
/// The Admin Dashboard for AssetFlow.
///
/// Gives the Admin an at-a-glance overview of the department (total
/// assets, pending complaints, maintenance requests, resolved
/// complaints) and quick access to every module. The statistics shown
/// here are placeholders — this phase only prepares the dashboard shell;
/// real counts will be wired in once the Assets and Complaints modules
/// are implemented.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReportViewModel>().loadDashboardStats();
    });
  }

  static const List<BottomNavItem> _bottomNavItems = [
    BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    BottomNavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Assets'),
    BottomNavItem(icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem_rounded, label: 'Complaints'),
    BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  Future<void> _handleRefresh(BuildContext context) {
    return Future.wait([
      context.read<AuthViewModel>().refreshUserProfile(),
      context.read<ReportViewModel>().loadDashboardStats(),
    ]);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature will be available in a future update.', style: AppStyles.bodyMedium(color: AppColors.textOnPrimary)),
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
    _showComingSoon(_bottomNavItems[index].label);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final reportViewModel = context.watch<ReportViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: AppStyles.heading4()),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notificationsScreen),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
        ],
      ),
      drawer: CustomDrawer(
        userName: user?.fullName ?? 'Admin',
        userRole: 'Administrator',
        userEmail: user?.email,
        onLogout: () => _handleLogout(authViewModel),
        menuItems: [
          DrawerMenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard', onTap: () => Navigator.of(context).pop()),
          DrawerMenuItem(icon: Icons.inventory_2_outlined, label: 'Manage Assets', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.assetsScreen);
          }),
          DrawerMenuItem(icon: Icons.report_problem_outlined, label: 'Complaints', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.complaintsScreen);
          }),
          DrawerMenuItem(icon: Icons.build_outlined, label: 'Maintenance', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.maintenanceList);
          }),
          DrawerMenuItem(icon: Icons.bar_chart_outlined, label: 'Reports', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.reportsScreen);
          }),
          DrawerMenuItem(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(AppRoutes.notificationsScreen);
          }),
          DrawerMenuItem(icon: Icons.person_outline_rounded, label: 'Profile', onTap: () => _closeDrawerThen('Profile')),
          DrawerMenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => _closeDrawerThen('Settings')),
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
            _WelcomeHeader(user: user, roleLabel: 'Administrator'),
            const SizedBox(height: AppConstants.paddingLarge),
            Text('Analytics', style: AppStyles.heading4()),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildAnalyticsGrid(reportViewModel),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildCharts(reportViewModel),
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

  void _closeDrawerThen(String feature) {
    Navigator.of(context).pop();
    _showComingSoon(feature);
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

  Widget _buildAnalyticsGrid(ReportViewModel reportViewModel) {
    final stats = reportViewModel.dashboardStats;

    if (reportViewModel.isLoadingStats && stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    String v(String key) => stats == null ? '—' : (stats[key] as int).toString();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppConstants.paddingSmall,
      mainAxisSpacing: AppConstants.paddingSmall,
      childAspectRatio: 2.4,
      children: [
        DashboardStatCard(icon: Icons.inventory_2_rounded, label: 'Total Assets', value: v('totalAssets'), color: AppColors.primary),
        DashboardStatCard(
          icon: Icons.report_problem_rounded,
          label: 'Total Complaints',
          value: v('totalComplaints'),
          color: AppColors.secondary,
        ),
        DashboardStatCard(icon: Icons.pending_actions_rounded, label: 'Open Complaints', value: v('openComplaints'), color: AppColors.statusPending),
        DashboardStatCard(
          icon: Icons.check_circle_rounded,
          label: 'Resolved Complaints',
          value: v('resolvedComplaints'),
          color: AppColors.statusResolved,
        ),
        DashboardStatCard(
          icon: Icons.priority_high_rounded,
          label: 'Escalated Complaints',
          value: v('escalatedComplaints'),
          color: AppColors.statusEscalated,
        ),
        DashboardStatCard(icon: Icons.build_rounded, label: 'Maintenance Records', value: v('maintenanceRecords'), color: AppColors.statusInProgress),
        DashboardStatCard(
          icon: Icons.handyman_rounded,
          label: 'Assets Under Maintenance',
          value: v('assetsUnderMaintenance'),
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildCharts(ReportViewModel reportViewModel) {
    final stats = reportViewModel.dashboardStats;
    if (stats == null) return const SizedBox.shrink();

    final byStatus = Map<String, int>.from(stats['complaintsByStatus'] as Map);
    final last7Days = List<int>.from(stats['complaintsLast7Days'] as List);
    final last7Labels = List<String>.from(stats['last7DayLabels'] as List);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Complaints by Status', style: AppStyles.heading4()),
        const SizedBox(height: AppConstants.paddingMedium),
        _chartCard(height: 220, child: _buildBarChart(byStatus)),
        const SizedBox(height: AppConstants.paddingLarge),
        Text('Complaint Status Distribution', style: AppStyles.heading4()),
        const SizedBox(height: AppConstants.paddingMedium),
        _chartCard(height: 220, child: _buildPieChart(byStatus)),
        const SizedBox(height: AppConstants.paddingLarge),
        Text('Complaints Filed — Last 7 Days', style: AppStyles.heading4()),
        const SizedBox(height: AppConstants.paddingMedium),
        _chartCard(height: 200, child: _buildLineChart(last7Days, last7Labels)),
      ],
    );
  }

  Widget _chartCard({required double height, required Widget child}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        AppConstants.paddingLarge,
        AppConstants.paddingLarge,
        AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildBarChart(Map<String, int> byStatus) {
    final entries = byStatus.entries.toList();
    final maxY = (entries.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b) + 1).toDouble();
    final colors = [AppColors.statusPending, AppColors.statusResolved, AppColors.statusEscalated];

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(entries[index].key, style: AppStyles.caption()),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(entries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: colors[i % colors.length],
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> byStatus) {
    final entries = byStatus.entries.where((e) => e.value > 0).toList();
    final colors = {
      'Pending/In Progress': AppColors.statusPending,
      'Resolved': AppColors.statusResolved,
      'Escalated': AppColors.statusEscalated,
    };

    if (entries.isEmpty) {
      return Center(child: Text('No complaints yet.', style: AppStyles.bodySmall(color: AppColors.textSecondary)));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 32,
              sections: entries.map((e) {
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: colors[e.key] ?? AppColors.primary,
                  title: e.value.toString(),
                  radius: 50,
                  titleStyle: AppStyles.caption(color: AppColors.textOnPrimary).copyWith(fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(height: 10, width: 10, decoration: BoxDecoration(color: colors[e.key] ?? AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(e.key, style: AppStyles.caption()),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<int> values, List<String> labels) {
    final maxY = (values.fold<int>(0, (a, b) => a > b ? a : b) + 1).toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[index], style: AppStyles.caption()),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i].toDouble())),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
          ),
        ],
      ),
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
          icon: Icons.inventory_2_rounded,
          title: 'Manage Assets',
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
          icon: Icons.person_rounded,
          title: 'Profile',
          color: AppColors.info,
          onTap: () => _showComingSoon('Profile'),
        ),
        QuickActionCard(
          icon: Icons.settings_rounded,
          title: 'Settings',
          color: AppColors.textSecondary,
          onTap: () => _showComingSoon('Settings'),
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

/// Welcome section shown at the top of every dashboard: avatar, name,
/// role, today's date, and department. Kept private to this file since
/// each dashboard's welcome copy differs slightly by [roleLabel]; the
/// visual shell is otherwise identical across Admin/HOD/Student.
class _WelcomeHeader extends StatelessWidget {
  final dynamic user;
  final String roleLabel;

  const _WelcomeHeader({required this.user, required this.roleLabel});

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
              (user.fullName as String).isNotEmpty ? (user.fullName as String)[0].toUpperCase() : 'A',
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