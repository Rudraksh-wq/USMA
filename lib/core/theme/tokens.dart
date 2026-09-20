import 'package:flutter/material.dart';

/// Design tokens for USMA — Calm, warm, hand-crafted studio palette.
/// Colors strictly audited for WCAG 2.1 AA (text ≥ 4.5:1, UI borders ≥ 3:1).
class AppColors {
  // Light Neutrals
  static const Color background = Color(0xFFF5EFE6);
  static const Color surface = Color(0xFFFBF7F1);
  static const Color surfaceVariant = Color(0xFFEFE6D8);
  static const Color border = Color(0xFFE4D9C8);
  static const Color borderStrong = Color(0xFF8A7767);
  static const Color divider = Color(0xFFE4D9C8);

  // Light Typography (never lighter than 4.5:1 against background)
  static const Color textPrimary = Color(0xFF3B2A20);
  static const Color textSecondary = Color(0xFF6B5747);
  static const Color textTertiary = Color(0xFF7A6656);

  // Primary & Accent (Warm Earth Brown)
  static const Color primary = Color(0xFF8B5E3C);
  static const Color primaryLight = Color(0xFFA67854);
  static const Color primaryDark = Color(0xFF6F4A2E);
  static const Color primaryPressed = Color(0xFF6F4A2E);

  static const Color secondary = Color(0xFF8B5E3C);
  static const Color secondaryLight = Color(0xFFA67854);
  static const Color secondaryDark = Color(0xFF6F4A2E);

  static const Color accent = Color(0xFF8B5E3C);
  static const Color softAccent = Color(0xFFD9C3A5);
  static const Color gold = Color(0xFF8A5A12);

  // Semantic Status Fills & Text (4.5:1 verified)
  static const Color success = Color(0xFF4A6B3E);
  static const Color successBg = Color(0xFFE6EDDD);

  static const Color warning = Color(0xFF8A5A12);
  static const Color warningBg = Color(0xFFF6E8CC);

  static const Color error = Color(0xFF9E3B2F);
  static const Color errorBg = Color(0xFFF3DAD5);

  static const Color info = Color(0xFF6B5747);
  static const Color infoBg = Color(0xFFEADFCF);

  // Dark Theme Neutrals
  static const Color darkBackground = Color(0xFF1F1712);
  static const Color darkSurface = Color(0xFF2A2019);
  static const Color darkSurfaceVariant = Color(0xFF382C23);
  static const Color darkBorder = Color(0xFF4A3B30);
  static const Color darkBorderStrong = Color(0xFF8A7767);

  static const Color darkTextPrimary = Color(0xFFF1E7D8);
  static const Color darkTextSecondary = Color(0xFFBFAE9B);
  static const Color darkTextTertiary = Color(0xFF9C8C7A);

  static const Color darkAccent = Color(0xFFD2A57A);
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 12.0; // Uniform 12 for cards & buttons per design system
  static const double xl = 16.0;
  static const double full = 999.0;
}
