import 'package:flutter/material.dart';

/// Responsive breakpoints and layout helpers for CampVerse.
class ResponsiveLayout {
  ResponsiveLayout._();

  /// Mobile breakpoint boundary (width < 768).
  static const double mobileBreakpoint = 768;

  /// Tablet breakpoint boundary (768 <= width < 1100).
  static const double tabletBreakpoint = 1100;

  /// Large desktop breakpoint boundary (width >= 1440).
  static const double largeDesktopBreakpoint = 1440;

  /// Check if the current context has a compact/mobile screen width (< 768).
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if the current context has a tablet screen width (768 to 1100).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if the current context has a desktop screen width (>= 768).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  /// Check if the current context has an expanded large desktop width
  /// (>= 1100).
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;
}

/// Responsive builder widget rendering distinct layouts per screen
/// form-factor.
class ResponsiveBuilder extends StatelessWidget {
  /// Default constructor for ResponsiveBuilder.
  const ResponsiveBuilder({
    required this.mobile,
    required this.desktop,
    this.tablet,
    super.key,
  });

  /// Widget rendered on mobile screen widths (< 768px).
  final Widget mobile;

  /// Widget rendered on desktop screen widths (>= 768px).
  final Widget desktop;

  /// Optional widget specifically for tablet screens.
  final Widget? tablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < ResponsiveLayout.mobileBreakpoint) {
      return mobile;
    } else if (tablet != null && width < ResponsiveLayout.tabletBreakpoint) {
      return tablet!;
    } else {
      return desktop;
    }
  }
}
