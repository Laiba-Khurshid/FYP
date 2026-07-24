import 'package:flutter/material.dart';

import 'package:project/core/utils/app_colors.dart';
import 'package:project/widgets/loading_widget.dart';
/// A generic full-screen loading state used while the app performs
/// initial setup work (e.g. checking auth state, resolving user role)
/// before routing to the correct dashboard.
class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({super.key, this.message = 'Loading, please wait...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingWidget(message: message),
    );
  }
}
