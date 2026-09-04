import 'package:campverse/core/models/app_role.dart';
import 'package:flutter/material.dart';

/// Centralized semantic color palette tailored for CampVerse.
/// Built with academic & editorial restraint, strictly avoiding generic AI
/// palette cliches.
/// Supports both Light (default) and Dark modes with WCAG AAA/AA contrast.
class AppColors {
  AppColors._();

  // ==========================================
  // Brand Colors (Refined Cobalt & Indigo)
  // ==========================================

  /// Primary brand action color in light mode (Refined Royal Cobalt).
  static const Color lightPrimary = Color(0xFF1D4ED8);

  /// Primary brand action color in dark mode (Luminous Indigo).
  static const Color darkPrimary = Color(0xFF6366F1);

  /// Lighter primary tint.
  static const Color primaryLight = Color(0xFF818CF8);

  /// Darker primary tint.
  static const Color primaryDark = Color(0xFF1E40AF);

  /// Accent highlight color (Caspian Cerulean).
  static const Color accent = Color(0xFF0284C7);

  /// Primary color token for universal use.
  static const Color primary = lightPrimary;

  // ==========================================
  // Light Theme Palette (Default)
  // ==========================================

  /// Core light canvas background surface (Clean slate paper).
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Elevated card and dialog surface in light mode (Pure crisp white).
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// High-elevation container surface in light mode (Subtle slate 100).
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);

  /// Boundary border color in light mode (Slate 200).
  static const Color lightSurfaceBorder = Color(0xFFE2E8F0);

  /// High-contrast primary text in light mode (Rich Obsidian Slate 900).
  static const Color lightTextPrimary = Color(0xFF0F172A);

  /// Secondary text in light mode (Slate 600 - 6.5:1 contrast).
  static const Color lightTextSecondary = Color(0xFF475569);

  /// Muted placeholder text in light mode (Slate 500 - 4.6:1 contrast).
  static const Color lightTextMuted = Color(0xFF64748B);

  /// Frosted glass background for light mode.
  static const Color lightGlassBackground = Color(0xF2FFFFFF); // 95% opacity

  /// Frosted glass border highlight for light mode.
  static const Color lightGlassBorder = Color(0x80CBD5E1);

  // ==========================================
  // Dark Theme Palette
  // ==========================================

  /// Core dark canvas background surface (Deep Charcoal Ink).
  static const Color darkBackground = Color(0xFF0B0F19);

  /// Elevated card and dialog surface in dark mode.
  static const Color darkSurface = Color(0xFF111827);

  /// High-elevation container surface in dark mode.
  static const Color darkSurfaceElevated = Color(0xFF1E293B);

  /// Boundary border color in dark mode (Slate 700).
  static const Color darkSurfaceBorder = Color(0xFF283548);

  /// High-contrast primary text in dark mode (Slate 50).
  static const Color darkTextPrimary = Color(0xFFF8FAFC);

  /// Secondary text in dark mode (Slate 300).
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  /// Muted placeholder in dark mode (Slate 400).
  static const Color darkTextMuted = Color(0xFF94A3B8);

  /// Frosted glass background for dark mode.
  static const Color darkGlassBackground = Color(0xD9111827); // 85% opacity

  /// Frosted glass border highlight for dark mode.
  static const Color darkGlassBorder = Color(0x26FFFFFF); // 15% white

  // ==========================================
  // Backward Compatible Default Tokens (Light First)
  // ==========================================

  /// Default background surface.
  static const Color background = lightBackground;

  /// Default card/dialog surface.
  static const Color surface = lightSurface;

  /// Default elevated container surface.
  static const Color surfaceElevated = lightSurfaceElevated;

  /// Default surface boundary border.
  static const Color surfaceBorder = lightSurfaceBorder;

  /// Default high-contrast primary text.
  static const Color textPrimary = lightTextPrimary;

  /// Default secondary text.
  static const Color textSecondary = lightTextSecondary;

  /// Default muted placeholder text.
  static const Color textMuted = lightTextMuted;

  // ==========================================
  // Status Colors (Universal)
  // ==========================================

  /// Success state color (Deep Pine Emerald).
  static const Color success = Color(0xFF059669);

  /// Warning state color (Warm Amber).
  static const Color warning = Color(0xFFD97706);

  /// Error and failure state color (Rose Crimson).
  static const Color error = Color(0xFFDC2626);

  /// Informational state color (Aegean Blue).
  static const Color info = Color(0xFF2563EB);

  // ==========================================
  // 8 Bespoke Campus Role Badges - Dual Mode
  // ==========================================

  // 1. Super Admin (Obsidian Mulberry / Royal Amethyst)

  /// Super Admin light badge color.
  static const Color roleSuperAdminLight = Color(0xFF581C87);

  /// Super Admin dark badge color.
  static const Color roleSuperAdminDark = Color(0xFFC084FC);

  /// Super Admin universal reference.
  static const Color roleSuperAdmin = roleSuperAdminLight;

  // 2. Principal (Oxford Navy / Glacier Periwinkle)

  /// Principal light badge color.
  static const Color rolePrincipalLight = Color(0xFF1E3A8A);

  /// Principal dark badge color.
  static const Color rolePrincipalDark = Color(0xFF93C5FD);

  /// Principal universal reference.
  static const Color rolePrincipal = rolePrincipalLight;

  // 3. Office Admin (Deep Mineral Slate / Cool Quartz)

  /// Office Admin light badge color.
  static const Color roleOfficeAdminLight = Color(0xFF334155);

  /// Office Admin dark badge color.
  static const Color roleOfficeAdminDark = Color(0xFF94A3B8);

  /// Office Admin universal reference.
  static const Color roleOfficeAdmin = roleOfficeAdminLight;

  // 4. Head of Department (Aegean Cobalt / Celestial Sky)

  /// HOD light badge color.
  static const Color roleHodLight = Color(0xFF1D4ED8);

  /// HOD dark badge color.
  static const Color roleHodDark = Color(0xFF60A5FA);

  /// HOD universal reference.
  static const Color roleHod = roleHodLight;

  // 5. Faculty (Evergreen Pine / Luminous Mint Sage)

  /// Faculty light badge color.
  static const Color roleFacultyLight = Color(0xFF065F46);

  /// Faculty dark badge color.
  static const Color roleFacultyDark = Color(0xFF34D399);

  /// Faculty universal reference.
  static const Color roleFaculty = roleFacultyLight;

  // 6. Student Union (Burnt Terracotta / Warm Apricot Sunset)

  /// Student Union light badge color.
  static const Color roleStudentUnionLight = Color(0xFF9A3412);

  /// Student Union dark badge color.
  static const Color roleStudentUnionDark = Color(0xFFFB923C);

  /// Student Union universal reference.
  static const Color roleStudentUnion = roleStudentUnionLight;

  // 7. Club Admin (Velvet Crimson / Coral Blossom)

  /// Club Admin light badge color.
  static const Color roleClubAdminLight = Color(0xFF9F1239);

  /// Club Admin dark badge color.
  static const Color roleClubAdminDark = Color(0xFFFB7185);

  /// Club Admin universal reference.
  static const Color roleClubAdmin = roleClubAdminLight;

  // 8. Student (Caspian Cerulean / Electric Sky)

  /// Student light badge color.
  static const Color roleStudentLight = Color(0xFF0369A1);

  /// Student dark badge color.
  static const Color roleStudentDark = Color(0xFF38BDF8);

  /// Student universal reference.
  static const Color roleStudent = roleStudentLight;

  // ==========================================
  // Context-Aware Helper Methods
  // ==========================================

  /// True if current theme brightness is dark.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Dynamic background color based on active theme.
  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  /// Dynamic surface color based on active theme.
  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  /// Dynamic elevated surface color based on active theme.
  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;

  /// Dynamic border color based on active theme.
  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkSurfaceBorder : lightSurfaceBorder;

  /// Semantic alias for borderOf.
  static Color surfaceBorderOf(BuildContext context) => borderOf(context);

  /// Dynamic primary text color based on active theme.
  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  /// Dynamic secondary text color based on active theme.
  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  /// Dynamic muted text color based on active theme.
  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  /// Dynamic glass background based on active theme.
  static Color glassBackgroundOf(BuildContext context) =>
      isDark(context) ? darkGlassBackground : lightGlassBackground;

  /// Dynamic glass border based on active theme.
  static Color glassBorderOf(BuildContext context) =>
      isDark(context) ? darkGlassBorder : lightGlassBorder;

  /// Dynamic primary brand color based on active theme.
  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : lightPrimary;

  /// Context-aware role color resolving the optimal contrast for light or dark.
  static Color roleColorOf(BuildContext context, AppRole role) {
    final dark = isDark(context);
    switch (role) {
      case AppRole.superAdmin:
        return dark ? roleSuperAdminDark : roleSuperAdminLight;
      case AppRole.principal:
        return dark ? rolePrincipalDark : rolePrincipalLight;
      case AppRole.officeAdmin:
        return dark ? roleOfficeAdminDark : roleOfficeAdminLight;
      case AppRole.hod:
        return dark ? roleHodDark : roleHodLight;
      case AppRole.faculty:
        return dark ? roleFacultyDark : roleFacultyLight;
      case AppRole.studentUnion:
        return dark ? roleStudentUnionDark : roleStudentUnionLight;
      case AppRole.clubAdmin:
        return dark ? roleClubAdminDark : roleClubAdminLight;
      case AppRole.student:
        return dark ? roleStudentDark : roleStudentLight;
    }
  }

  // ==========================================
  // Gradients
  // ==========================================

  /// Vibrant brand gradient.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
  );

  /// Deep surface card gradient for dark mode.
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Crisp surface card gradient for light mode.
  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
