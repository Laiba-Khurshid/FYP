// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../viewmodels/maintenance_viewmodel.dart';
// import '../../widgets/loading_widget.dart';
// import '/core/utils/app_colors.dart';
// import '/core/utils/app_styles.dart';
//
// /// Maintenance screen
// class MaintenanceScreen extends StatefulWidget {
//   const MaintenanceScreen({Key? key}) : super(key: key);
//
//   @override
//   State<MaintenanceScreen> createState() => _MaintenanceScreenState();
// }
//
// class _MaintenanceScreenState extends State<MaintenanceScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<MaintenanceViewModel>(context, listen: false).getAllMaintenance();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final maintenanceViewModel = Provider.of<MaintenanceViewModel>(context);
//
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: AppBar(
//         title: const Text('Maintenance Records'),
//         backgroundColor: AppColors.primaryBlue,
//         foregroundColor: Colors.white,
//       ),
//       body: maintenanceViewModel.isLoading
//           ? const LoadingWidget(message: 'Loading maintenance records...')
//           : maintenanceViewModel.maintenanceRecords.isEmpty
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.build, size: 64, color: AppColors.textLight),
//             const SizedBox(height: 16),
//             Text(
//               'No maintenance records found',
//               style: AppStyles.bodyLarge.copyWith(
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//       )
//           : ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: maintenanceViewModel.maintenanceRecords.length,
//         itemBuilder: (context, index) {
//           final record = maintenanceViewModel.maintenanceRecords[index];
//           return Container(
//             margin: const EdgeInsets.only(bottom: 12),
//             padding: const EdgeInsets.all(16),
//             decoration: AppStyles.cardDecoration,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(record.assetName, style: AppStyles.heading3),
//                 const SizedBox(height: 8),
//                 Text('Technician: ${record.technicianName}'),
//                 Text('Status: ${record.status}'),
//                 Text('Type: ${record.maintenanceType}'),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
