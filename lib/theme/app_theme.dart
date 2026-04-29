import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design system for Sheen Bazaar.
/// Mirrors the Traam-and-Beyond website's dark-luxury, heritage aesthetic.
class AppColors {
  AppColors._();

  // ── Backgrounds ─────────────────────────────────────────────────────────────
  /// Primary scaffold/page background — deep walnut brown
  static const Color walnut = Color(0xFF20180C);

  /// Deeper section background — used in headers, bottom sheets, overlays
  static const Color walnutDeep = Color(0xFF1A130A);

  /// Card / surface background — slightly lighter than walnut
  static const Color surface = Color(0xFF2A1E0F);

  /// Slightly lighter dark — for dividers, input fills, nested surfaces
  static const Color walnutLight = Color(0xFF5F4B2B);

  // ── Accent / Brand ───────────────────────────────────────────────────────────
  /// Primary action color — terracotta
  static const Color terracotta = Color(0xFFB57031);

  /// Lighter terracotta — for pressed states, borders, highlights
  static const Color terracottaLight = Color(0xFFCA9A56);

  /// Gold highlight — used for verified badges, price text
  static const Color saffron = Color(0xFFD4A017);

  /// Legacy gold accent — kept for compatibility (close to terracottaLight)
  static const Color gold = Color(0xFFC9A55A);

  // ── Text ─────────────────────────────────────────────────────────────────────
  /// Primary text on dark backgrounds — warm cream
  static const Color cream = Color(0xFFF8E8D2);

  /// Secondary / descriptive text — muted stone
  static const Color stone = Color(0xFFA68F67);

  /// Lighter stone — for captions, timestamps
  static const Color stoneLight = Color(0xFFC4A882);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB57031); // terracotta doubles as error
  static const Color warning = Color(0xFFD4A017); // saffron for warnings

  // ── Utility ──────────────────────────────────────────────────────────────────
  /// Overlay for gradients on images
  static const Color overlay = Color(0x99200F00);

  /// Subtle border — cream at 20% opacity
  static const Color border = Color(0x33F8E8D2);

  /// Card border — gold at 30% opacity
  static const Color cardBorder = Color(0x4DC9A55A);
}

class AppTextStyles {
  AppTextStyles._();

  // ── Display (Playfair Display — serif, elegant) ───────────────────────────────
  static TextStyle displayHero = GoogleFonts.playfairDisplay(
    fontSize: 50,
    fontWeight: FontWeight.w500,
    color: AppColors.cream,
    letterSpacing: 1.2,
    height: 1.1,
  );

  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 38,
    fontWeight: FontWeight.w500,
    color: AppColors.cream,
    letterSpacing: 1.0,
  );

  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: AppColors.cream,
    letterSpacing: 0.6,
  );

  static TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.cream,
    letterSpacing: 0.3,
  );

  static TextStyle appBarTitle = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.cream,
    letterSpacing: 1.8,
  );

  // ── Body (Nunito — rounded sans-serif) ───────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.cream,
    height: 1.6,
  );

  static TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.cream,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.stone,
    height: 1.4,
  );

  static TextStyle label = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.stone,
    letterSpacing: 1.2,
  );

  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.stone,
    letterSpacing: 0.3,
  );

  static TextStyle button = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.cream,
    letterSpacing: 0.8,
  );

  static TextStyle price = GoogleFonts.playfairDisplay(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.saffron,
    letterSpacing: 0.3,
  );
}

/// Reusable decoration helpers
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.cardBorder, width: 1),
  );

  static BoxDecoration cardElevated = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.cardBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration inputField = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColors.border, width: 1),
  );

  static BoxDecoration sectionHeader = const BoxDecoration(
    color: AppColors.walnutDeep,
  );
}
