import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';


class AppStyles {
  AppStyles._();

  // ---------------------------------------------------------------------
  // Headings
  // ---------------------------------------------------------------------
  static TextStyle heading1({Color color = AppColors.textPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle heading2({Color color = AppColors.textPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.3,
    );
  }

  static TextStyle heading3({Color color = AppColors.textPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle heading4({Color color = AppColors.textPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  // ---------------------------------------------------------------------
  // Body text
  // ---------------------------------------------------------------------
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  // ---------------------------------------------------------------------
  // Labels / captions / buttons
  // ---------------------------------------------------------------------
  static TextStyle label({Color color = AppColors.textSecondary}) {
    return GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle caption({Color color = AppColors.textHint}) {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle buttonText({Color color = AppColors.textOnPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.3,
    );
  }

  // ---------------------------------------------------------------------
  // Splash screen specific styles
  // ---------------------------------------------------------------------
  static TextStyle splashTitle({Color color = AppColors.textOnPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 1.0,
    );
  }

  static TextStyle splashSubtitle({Color color = AppColors.textOnPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color.withOpacity(0.9),
      letterSpacing: 0.4,
    );
  }

  static TextStyle splashFooter({Color color = AppColors.textOnPrimary}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w300,
      color: color.withOpacity(0.75),
      letterSpacing: 0.6,
    );
  }
}
