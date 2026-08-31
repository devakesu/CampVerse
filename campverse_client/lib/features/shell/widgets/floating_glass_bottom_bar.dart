import 'dart:ui';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Navigation item model for floating glass bottom bar.
class FloatingNavTab {
  /// Default constructor for FloatingNavTab.
  const FloatingNavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Text label for the tab.
  final String label;

  /// Default unselected icon.
  final IconData icon;

  /// Selected state icon.
  final IconData selectedIcon;
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

  /// Primary accent color (defaults to AppColors.primary).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.primary;
    final isDark = AppColors.isDark(context);
    final glassBg = AppColors.glassBackgroundOf(context);
    final glassBorder = AppColors.glassBorderOf(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: glassBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: glassBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(tabs.length, (index) {
                    final tab = tabs[index];
                    final isSelected = index == selectedIndex;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor.withValues(
                                    alpha: isDark ? 0.18 : 0.12,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? tab.selectedIcon : tab.icon,
                                size: 22,
                                color: isSelected
                                    ? activeColor
                                    : AppColors.textSecondaryOf(context),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? activeColor
                                      : AppColors.textSecondaryOf(context),
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
