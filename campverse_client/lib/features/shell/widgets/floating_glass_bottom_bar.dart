import 'dart:ui';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Navigation item model for floating glass bottom bar.
class FloatingNavTab {
  /// Default constructor for FloatingNavTab.
  const FloatingNavTab({
    required this.label,
    this.shortLabel,
    this.accentColor,
    required this.icon,
    required this.selectedIcon,
  });

  /// Full text label for the tab.
  final String label;

  /// Short concise label for smaller displays.
  final String? shortLabel;

  /// Optional signature accent color for this specific tab.
  final Color? accentColor;

  /// Default unselected icon.
  final IconData icon;

  /// Selected state icon.
  final IconData selectedIcon;

  /// Resolves the concise display label for smaller viewports.
  String get displayLabel => shortLabel ?? label;
}

/// A floating frosted glassmorphism bottom navigation bar for mobile devices.
class FloatingGlassBottomBar extends StatelessWidget {
  /// Default constructor for FloatingGlassBottomBar.
  const FloatingGlassBottomBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.accentColor,
    super.key,
  });

  /// List of navigation tab items.
  final List<FloatingNavTab> tabs;

  /// Index of the currently active tab.
  final int selectedIndex;

  /// Callback when a tab is pressed.
  final ValueChanged<int> onTap;

  /// Primary accent color fallback (defaults to AppColors.primary).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.primary;
    final isDark = AppColors.isDark(context);

    // Active tab's custom accent color (if any)
    final currentActiveColor =
        (selectedIndex >= 0 && selectedIndex < tabs.length)
            ? (tabs[selectedIndex].accentColor ?? activeColor)
            : activeColor;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              // Ambient soft elevation shadow
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.09),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
              // Soft colored glow reflecting the active tab accent
              BoxShadow(
                color: currentActiveColor.withValues(
                  alpha: isDark ? 0.22 : 0.14,
                ),
                blurRadius: 24,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  // Translucent frosted glass gradient
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B).withValues(alpha: 0.65),
                            const Color(0xFF0F172A).withValues(alpha: 0.50),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.72),
                            Colors.white.withValues(alpha: 0.48),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  // Glass refraction perimeter highlight border
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.88),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(tabs.length, (index) {
                    final tab = tabs[index];
                    final isSelected = index == selectedIndex;
                    final tabColor = tab.accentColor ?? activeColor;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      tabColor.withValues(
                                        alpha: isDark ? 0.22 : 0.16,
                                      ),
                                      tabColor.withValues(
                                        alpha: isDark ? 0.10 : 0.06,
                                      ),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color: tabColor.withValues(
                                      alpha: isDark ? 0.38 : 0.26,
                                    ),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.12 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isSelected ? tab.selectedIcon : tab.icon,
                                  size: 21,
                                  color: isSelected
                                      ? tabColor
                                      : AppColors.textSecondaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tab.displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  letterSpacing: -0.1,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? Colors.white : tabColor)
                                      : AppColors.textSecondaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Glowing micro-indicator pip
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 14 : 0,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? tabColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: tabColor.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 4,
                                            spreadRadius: 0.5,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
