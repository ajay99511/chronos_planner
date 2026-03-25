import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for Chronos Planner.
/// 
/// Centralized source of truth for all visual styling:
/// - Color palette (backgrounds, accents, task types)
/// - Typography scale (Inter font via Google Fonts)
/// - Spacing system (4px base unit)
/// - Border radius scale
/// - Shadow presets
/// - Animation durations
/// - Gradient presets
/// 
/// Usage: Always import and use these constants instead of magic values.
/// 
/// Example:
/// ```dart
/// Container(
///   color: AppColors.surface,
///   padding: const EdgeInsets.all(AppSpacing.md),
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(AppRadius.lg),
///     boxShadow: AppShadows.medium,
///   ),
/// )
/// ```
// ─────────────────────────────────────────────────
// COLOR PALETTE
// ─────────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);
  static const Color neonBlue = Color(0xFF4F46E5);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassFill = Color(0x0DFFFFFF);

  // Task Type Colors
  static const Color work = Color(0xFF3B82F6);
  static const Color personal = Color(0xFFA855F7);
  static const Color health = Color(0xFF10B981);
  static const Color leisure = Color(0xFFF59E0B);

  // Accent Gradients (start, end)
  static const List<Color> gradientBlue = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1)
  ];
  static const List<Color> gradientPurple = [
    Color(0xFF7C3AED),
    Color(0xFFA855F7)
  ];
  static const List<Color> gradientCyan = [
    Color(0xFF0891B2),
    Color(0xFF06B6D4)
  ];
  static const List<Color> gradientSunrise = [
    Color(0xFFF59E0B),
    Color(0xFFF97316)
  ];
}

// ─────────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────────
class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get chip => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
}

// ─────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─────────────────────────────────────────────────
// BORDER RADII
// ─────────────────────────────────────────────────
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;
}

// ─────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────
class AppShadows {
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.4}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.5),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
}

// ─────────────────────────────────────────────────
// ANIMATION DURATIONS
// ─────────────────────────────────────────────────
class AppAnimDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration stagger = Duration(milliseconds: 50); // per-item delay
}

// ─────────────────────────────────────────────────
// GRADIENTS
// ─────────────────────────────────────────────────
class AppGradients {
  static const LinearGradient primaryBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.gradientBlue,
  );

  static const LinearGradient purple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.gradientPurple,
  );

  static LinearGradient surfaceCard = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.surface.withValues(alpha: 0.9),
      AppColors.surface.withValues(alpha: 0.6),
    ],
  );
}
