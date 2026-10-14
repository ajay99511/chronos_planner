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

  /// Accent for small text on [background].
  ///
  /// [neonBlue] is a saturated indigo: excellent as a fill or on large type,
  /// but only 2.84:1 against the app background even at full opacity, so it
  /// fails WCAG AA (4.5:1) for anything at body size or below. This is the
  /// same hue lightened to 5.98:1.
  static const Color accentText = Color(0xFF818CF8);
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
    Color(0xFF6366F1),
  ];
  static const List<Color> gradientPurple = [
    Color(0xFF7C3AED),
    Color(0xFFA855F7),
  ];
  static const List<Color> gradientCyan = [
    Color(0xFF0891B2),
    Color(0xFF06B6D4),
  ];
  static const List<Color> gradientSunrise = [
    Color(0xFFF59E0B),
    Color(0xFFF97316),
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
        letterSpacing: 0,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 0,
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
// RESPONSIVE LAYOUT
// ─────────────────────────────────────────────────
class AppResponsive {
  /// Widths below this are a real device class, not an edge case: small
  /// Androids, an iPhone SE, and — far more often — any phone in split-screen.
  /// Every screen used to overflow here.
  static const double tinyWidth = 360;

  /// Material 3's compact/medium boundary.
  static const double mediumWidth = 600;

  /// Material 3's medium/expanded boundary.
  static const double expandedWidth = 900;

  /// The largest text scale the app lays out for.
  ///
  /// Android and iOS both allow more (2.0 and beyond). Past roughly 1.5 a
  /// planner's information density stops working at any width — a day card
  /// cannot show a weekday, a date and a progress bar in a strip that still
  /// fits seven of them — so the app clamps rather than pretending. Clamping
  /// only the *upper* bound, because a user who prefers smaller text is asking
  /// for something the layout can honour.
  ///
  /// 1.5 is also the ceiling the responsive test matrix probes, so nothing
  /// larger can reach a layout that has not been checked.
  static const double maxTextScale = 1.5;

  /// [MediaQuery]'s text scaler, capped at [maxTextScale].
  ///
  /// Applied once in `MyApp.builder` so it covers every route, including
  /// dialogs and bottom sheets, which build in their own subtree.
  static TextScaler clampedTextScaler(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maxTextScale);

  static bool isTiny(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tinyWidth;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mediumWidth;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mediumWidth &&
      MediaQuery.sizeOf(context).width < expandedWidth;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedWidth;

  /// Scales a fixed dimension with the user's text size.
  ///
  /// For a box whose contents are text: a height in logical pixels is only
  /// correct at scale 1.0, and at 1.5 the same box clips its own label. Use
  /// this wherever a hard-coded height or width exists to contain text.
  static double scaled(BuildContext context, double base) =>
      clampedTextScaler(context).scale(base);

  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Tighter gutters below 360: at that width the previous flat 16 left 288
    // for content, which is what pushed several rows over.
    if (width < tinyWidth) return AppSpacing.sm;
    if (width < mediumWidth) return AppSpacing.md;
    if (width < expandedWidth) return AppSpacing.lg;
    return AppSpacing.xl;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final padding = pagePadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets horizontalPadding(BuildContext context) {
    final padding = pagePadding(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  static double heading1Size(BuildContext context) {
    if (isTiny(context)) return 22;
    if (isCompact(context)) return 26;
    if (isMedium(context)) return 29;
    return 32;
  }

  static double heading2Size(BuildContext context) {
    if (isTiny(context)) return 20;
    if (isCompact(context)) return 24;
    return 28;
  }

  static double cardRadius(BuildContext context) =>
      isCompact(context) ? AppRadius.lg : AppRadius.xl;
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

/// The application's theme.
///
/// Lives here rather than inline in `main.dart` so tests render screens under
/// the same colours the app ships. A harness with the default light Scaffold
/// made contrast assertions meaningless: white-on-white measured 1.22:1
/// against a background the user never sees.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.neonBlue,
          secondary: AppColors.neonPurple,
          surface: AppColors.surface,
        ),
      );
}
