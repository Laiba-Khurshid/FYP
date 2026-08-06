import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF123E9E);
  static const Color primaryLight = Color(0xFF5B85E8);
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color accent = Color(0xFFF59E0B);

  // ---------------------------------------------------------------------
  // Neutral / background colors
  // ---------------------------------------------------------------------
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F1420);
  static const Color surface = Color(0xFFF7F9FC);
  static const Color surfaceDark = Color(0xFF1A2232);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E2738);

  // ---------------------------------------------------------------------
  // Text colors
  // ---------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);

  // ---------------------------------------------------------------------
  // Status / semantic colors
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // ---------------------------------------------------------------------
  // Complaint / status specific colors (used later by complaint module)
  // ---------------------------------------------------------------------
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusInProgress = Color(0xFF0EA5E9);
  static const Color statusResolved = Color(0xFF16A34A);
  static const Color statusEscalated = Color(0xFFDC2626);

  // ---------------------------------------------------------------------
  // Borders & dividers
  // ---------------------------------------------------------------------
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF2D3748);
  static const Color divider = Color(0xFFEDF0F5);

  // ---------------------------------------------------------------------
  // Shadow
  // ---------------------------------------------------------------------
  static const Color shadow = Color(0x1A000000);

  // ---------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primary, secondary],
  );
}
