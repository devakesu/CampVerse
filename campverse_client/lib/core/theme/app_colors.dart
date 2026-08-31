import 'package:flutter/material.dart';

/// Centralized color palette tailored for CampVerse.
class AppColors {
  AppColors._();

  /// Primary brand color (Indigo).
  static const Color primary = Color(0xFF6366F1);

  /// Lighter primary tint.
  static const Color primaryLight = Color(0xFF818CF8);

  /// Darker primary tint.
  static const Color primaryDark = Color(0xFF4338CA);

  /// Accent highlight color (Sky Blue).
  static const Color accent = Color(0xFF38BDF8);

  /// Core dark background surface.
  static const Color background = Color(0xFF0B0F19);

  /// Elevated card and dialog surface.
  static const Color surface = Color(0xFF111827);

  /// High-elevation container surface.
  static const Color surfaceElevated = Color(0xFF1F2937);

  /// Subtle container boundary border color.
  static const Color surfaceBorder = Color(0xFF374151);

  /// High-contrast primary text color.
  static const Color textPrimary = Color(0xFFF9FAFB);

  /// Secondary muted text color.
  static const Color textSecondary = Color(0xFF9CA3AF);

  /// Low-contrast muted placeholder color.
  static const Color textMuted = Color(0xFF6B7280);

  /// Success state color.
  static const Color success = Color(0xFF10B981);

  /// Warning state color.
  static const Color warning = Color(0xFFF59E0B);

  /// Error and failure state color.
  static const Color error = Color(0xFFEF4444);

  /// Informational state color.
  static const Color info = Color(0xFF3B82F6);

  /// Accent badge color for Super Admin role.
  static const Color roleSuperAdmin = Color(0xFFEC4899);

  /// Accent badge color for Principal role.
  static const Color rolePrincipal = Color(0xFF8B5CF6);

  /// Accent badge color for Office Admin role.
  static const Color roleOfficeAdmin = Color(0xFF3B82F6);

  /// Accent badge color for HOD role.
  static const Color roleHod = Color(0xFF10B981);

  /// Accent badge color for Faculty role.
  static const Color roleFaculty = Color(0xFF14B8A6);

  /// Accent badge color for Student Union role.
  static const Color roleStudentUnion = Color(0xFFF59E0B);

  /// Accent badge color for Club Admin role.
  static const Color roleClubAdmin = Color(0xFFF97316);

  /// Accent badge color for Student role.
  static const Color roleStudent = Color(0xFF6366F1);

  /// Vibrant brand gradient.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  /// Deep surface card gradient.
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );
}
