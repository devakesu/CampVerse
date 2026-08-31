import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Card component representing an available workspace role for selection.
class RoleCard extends StatefulWidget {
  /// Default constructor for RoleCard.
  const RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
    this.isBaseRole = false,
    super.key,
  });

  /// The role represented by this card.
  final AppRole role;

  /// True if currently selected in the UI.
  final bool isSelected;

  /// Callback when user selects this role.
  final VoidCallback onTap;

  /// True if this role is the primary base role of the user.
  final bool isBaseRole;

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final roleColor = AppColors.roleColorOf(context, widget.role);
    final isDark = AppColors.isDark(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translateByDouble(0, _isHovered ? -3.0 : 0.0, 0, 1),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? roleColor.withValues(alpha: isDark ? 0.16 : 0.08)
                  : AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.isSelected
                    ? roleColor
                    : (_isHovered
                        ? roleColor.withValues(alpha: 0.6)
                        : AppColors.borderOf(context)),
                width: widget.isSelected ? 2 : 1.2,
              ),
              boxShadow: [
                if (widget.isSelected || _isHovered)
                  BoxShadow(
                    color: roleColor.withValues(alpha: isDark ? 0.25 : 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                else
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.role.icon, color: roleColor, size: 24),
                    ),
                    if (widget.isBaseRole)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevatedOf(context),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: AppColors.borderOf(context)),
                        ),
                        child: Text(
                          'Primary Base',
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.role.displayName,
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.role.description,
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Launch Workspace',
                      style: TextStyle(
                        color: widget.isSelected
                            ? roleColor
                            : AppColors.textSecondaryOf(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: widget.isSelected
                          ? roleColor
                          : AppColors.textSecondaryOf(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
