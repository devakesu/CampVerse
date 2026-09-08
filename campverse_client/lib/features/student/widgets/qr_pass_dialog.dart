import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available presentation views for an event pass.
enum _PassViewMode { qr, secretCode }

/// Interactive modal sheet rendering an authenticated digital event pass
/// with interchangeable QR code, secret code, scan counts, and checkpoints.
class QrPassDialog extends ConsumerStatefulWidget {
  /// Default constructor.
  const QrPassDialog({
    required this.registration,
    super.key,
  });

  /// Registration record.
  final StudentRegistration registration;

  /// Convenience display helper.
  static Future<void> show(
    BuildContext context,
    StudentRegistration registration,
  ) {
    return showDialog(
      context: context,
      builder: (context) => QrPassDialog(registration: registration),
    );
  }

  @override
  ConsumerState<QrPassDialog> createState() => _QrPassDialogState();
}

class _QrPassDialogState extends ConsumerState<QrPassDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late _PassViewMode _viewMode;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!widget.registration.isSingleUseExpired) {
      _animCtrl.repeat(reverse: true);
    }

    // If QR is available, default to QR mode; otherwise default to secret code
    if (widget.registration.hasQr) {
      _viewMode = _PassViewMode.qr;
    } else {
      _viewMode = _PassViewMode.secretCode;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  String _formatCheckpointName(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'entry':
        return '🎟️ Gate Entry';
      case 'food':
      case 'meals':
      case 'meal':
        return '🍱 Food & Meals';
      case 'kit':
      case 'swag':
      case 'swag_kit':
      case 'donor_kit':
        return '🎒 Swag Kit';
      case 'workshop':
        return '💻 Workshop';
      default:
        final cap = raw.isNotEmpty
            ? '${raw[0].toUpperCase()}${raw.substring(1)}'
            : raw;
        return '🏷️ $cap';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final reg = widget.registration;
    final event = reg.event;
    final authState = ref.watch(authStateProvider);
    final studentName =
        authState.user?.userMetadata?['full_name'] as String? ??
        'Verified Student';

    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final canSwitchModes = reg.hasQr && reg.hasSecretCode;
    final isExpiredUsed = reg.isSingleUseExpired;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isExpiredUsed
                  ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                  : (isDark
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                      : const Color(0xFF0369A1).withValues(alpha: 0.2)),
              width: isExpiredUsed ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpiredUsed
                    ? const Color(0xFFEF4444).withValues(alpha: 0.22)
                    : (isDark ? Colors.black : Colors.blueGrey).withValues(
                        alpha: 0.2,
                      ),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Ticket Header ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isExpiredUsed
                        ? (isDark
                            ? const Color(0xFF450A0A).withValues(alpha: 0.5)
                            : const Color(0xFFFEF2F2))
                        : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (event?.primaryOrgLogo != null &&
                          event!.primaryOrgLogo!.isNotEmpty)
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(event.primaryOrgLogo!),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isExpiredUsed
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF0369A1))
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExpiredUsed
                                ? Icons.do_not_disturb_on_rounded
                                : Icons.confirmation_number_rounded,
                            color: isExpiredUsed
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0284C7),
                            size: 22,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event?.title ?? 'Campus Entry Pass',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event?.venue ?? 'Campus Venue',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Perforated Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(
                      26,
                      (i) => Expanded(
                        child: Container(
                          height: 1.5,
                          color: i.isEven ? border : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Ticket Body ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Status Badge & Attendee Name
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isExpiredUsed
                                  ? const Color(0xFFEF4444)
                                        .withValues(alpha: 0.12)
                                  : (reg.isActive
                                      ? const Color(0xFF16A34A)
                                            .withValues(alpha: 0.12)
                                      : border),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isExpiredUsed
                                    ? const Color(0xFFEF4444)
                                    : (reg.isActive
                                        ? const Color(0xFF16A34A)
                                        : Colors.grey),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpiredUsed
                                      ? Icons.do_not_disturb_on_rounded
                                      : (reg.isActive
                                          ? Icons.verified_rounded
                                          : Icons.info_outline_rounded),
                                  size: 13,
                                  color: isExpiredUsed
                                      ? const Color(0xFFEF4444)
                                      : (reg.isActive
                                          ? const Color(0xFF16A34A)
                                          : Colors.grey),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isExpiredUsed
                                      ? 'EXPIRED - USED'
                                      : reg.status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: isExpiredUsed
                                        ? const Color(0xFFEF4444)
                                        : (reg.isActive
                                            ? const Color(0xFF16A34A)
                                            : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            studentName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (isExpiredUsed) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This single-use pass has already been used '
                                  'and is expired.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Interchangeable Switcher (QR vs Secret Code) ───────
                      if (canSwitchModes)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildModeSegment(
                                  label: 'QR Code Pass',
                                  icon: Icons.qr_code_rounded,
                                  isSelected: _viewMode == _PassViewMode.qr,
                                  isDark: isDark,
                                  onTap: () => setState(
                                    () => _viewMode = _PassViewMode.qr,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildModeSegment(
                                  label: 'Secret Code',
                                  icon: Icons.pin_rounded,
                                  isSelected:
                                      _viewMode == _PassViewMode.secretCode,
                                  isDark: isDark,
                                  onTap: () => setState(
                                    () => _viewMode = _PassViewMode.secretCode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ── Display: QR Code or Secret Code ───────────────────
                      if (_viewMode == _PassViewMode.qr)
                        _buildQrSection(
                          context: context,
                          reg: reg,
                          isDark: isDark,
                          textSecondary: textSecondary,
                        )
                      else
                        _buildSecretCodeSection(
                          context: context,
                          reg: reg,
                          isDark: isDark,
                          border: border,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                      if (event != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${_formatDate(event.startTime)} • '
                                '${_formatTime(event.startTime)}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ── Verification & Scan Details Card ──────────────────
                      _buildScanDetailsCard(
                        context: context,
                        reg: reg,
                        isDark: isDark,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      // ── Cancel Registration Button ────────────────────────
                      if (reg.isActive) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isCancelling
                                ? null
                                : () => _handleCancelRegistration(context, reg),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isCancelling
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 16),
                            label: Text(
                              _isCancelling
                                  ? 'Cancelling...'
                                  : 'Cancel Pass Registration',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiredStamp() {
    return Transform.rotate(
      angle: -0.15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.do_not_disturb_on_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'EXPIRED - USED',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0284C7) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0369A1))
                  : Colors.grey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0369A1))
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection({
    required BuildContext context,
    required StudentRegistration reg,
    required bool isDark,
    required Color textSecondary,
  }) {
    final qrToken = reg.qrPayload ?? reg.displayCode;
    final isExpiredUsed = reg.isSingleUseExpired;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 175,
              height: 175,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isExpiredUsed
                    ? Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isExpiredUsed
                            ? const Color(0xFFEF4444)
                            : Colors.black)
                        .withValues(alpha: isExpiredUsed ? 0.2 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isExpiredUsed
                  ? ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: 5,
                        sigmaY: 5,
                      ),
                      child: CustomPaint(
                        painter: _VectorQrMatrixPainter(
                          seed: qrToken,
                          isDark: false,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _VectorQrMatrixPainter(
                        seed: qrToken,
                        isDark: false,
                      ),
                    ),
            ),
            if (!isExpiredUsed)
              // Animated glowing scanline
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) {
                  return Positioned(
                    top: 15 + (_animCtrl.value * 140),
                    child: Container(
                      width: 155,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7)
                                .withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              _buildExpiredStamp(),
          ],
        ),
        const SizedBox(height: 14),

        // QR Token Box
        InkWell(
          onTap: () {
            unawaited(Clipboard.setData(ClipboardData(text: qrToken)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isExpiredUsed
                      ? 'Expired pass token copied'
                      : 'Pass token copied to clipboard',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isExpiredUsed
                  ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
              border: isExpiredUsed
                  ? Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      qrToken,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isExpiredUsed ? const Color(0xFFEF4444) : null,
                        decoration:
                            isExpiredUsed ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: isExpiredUsed ? const Color(0xFFEF4444) : Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (!isExpiredUsed) ...[
          const SizedBox(height: 6),
          Text(
            'Present this pass at the gate for instant NFC/QR check-in',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecretCodeSection({
    required BuildContext context,
    required StudentRegistration reg,
    required bool isDark,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final code =
        reg.secretCode ??
        (reg.id.isNotEmpty
            ? 'CODE-${reg.id.substring(
                0,
                reg.id.length > 6 ? 6 : reg.id.length,
              ).toUpperCase()}'
            : 'NO-CODE');
    final isExpiredUsed = reg.isSingleUseExpired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExpiredUsed
              ? (isDark
                  ? [
                      const Color(0xFF450A0A),
                      const Color(0xFF1C1917),
                    ]
                  : [
                      const Color(0xFFFEF2F2),
                      const Color(0xFFFEE2E2),
                    ])
              : (isDark
                  ? [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ]
                  : [
                      const Color(0xFFF0F9FF),
                      const Color(0xFFE0F2FE),
                    ]),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpiredUsed
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : (isDark
                  ? const Color(0xFF0284C7).withValues(alpha: 0.35)
                  : const Color(0xFF38BDF8).withValues(alpha: 0.4)),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpiredUsed
                    ? Icons.block_rounded
                    : Icons.lock_outline_rounded,
                size: 13,
                color: isExpiredUsed
                    ? const Color(0xFFEF4444)
                    : (isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0369A1)),
              ),
              const SizedBox(width: 5),
              Text(
                isExpiredUsed
                    ? 'EXPIRED SECRET CODE'
                    : 'CLUB VERIFICATION CODE',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isExpiredUsed
                      ? const Color(0xFFEF4444)
                      : (isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0369A1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Secret Code with Blur + Expired Stamp
          Stack(
            alignment: Alignment.center,
            children: [
              if (isExpiredUsed)
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 5,
                    sigmaY: 5,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      code,
                      style: GoogleFonts.robotoMono(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: const Color(0xFFEF4444),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    code,
                    style: GoogleFonts.robotoMono(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              if (isExpiredUsed) _buildExpiredStamp(),
            ],
          ),
          const SizedBox(height: 12),

          // Tap to copy button
          InkWell(
            onTap: () {
              unawaited(Clipboard.setData(ClipboardData(text: code)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isExpiredUsed
                        ? 'Expired verification code copied'
                        : 'Secret verification code copied!',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isExpiredUsed
                      ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                      : border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: isExpiredUsed
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Copy Code',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isExpiredUsed
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isExpiredUsed) ...[
            const SizedBox(height: 10),
            Text(
              'Provide this secret code to club coordinators '
              'for desk check-in or manual verification',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanDetailsCard({
    required BuildContext context,
    required StudentRegistration reg,
    required bool isDark,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final hasScanned = reg.scanCount > 0 || reg.usedAt != null;
    final isExpiredUsed = reg.isSingleUseExpired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpiredUsed
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpiredUsed
                    ? Icons.error_outline_rounded
                    : Icons.fact_check_outlined,
                size: 13,
                color: isExpiredUsed
                    ? const Color(0xFFEF4444)
                    : textSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'CHECK-IN & USAGE METRICS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isExpiredUsed
                        ? const Color(0xFFEF4444)
                        : textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Policy & Count Rows (adaptive layout for small screens)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 240;
              final policyTile = _buildDetailTile(
                icon: reg.isSingleScan
                    ? Icons.looks_one_rounded
                    : Icons.all_inclusive_rounded,
                iconColor: isExpiredUsed
                    ? const Color(0xFFEF4444)
                    : (reg.isSingleScan
                        ? const Color(0xFF0284C7)
                        : const Color(0xFF8B5CF6)),
                title: 'Usage Type',
                subtitle: isExpiredUsed
                    ? 'Single usage (Used)'
                    : (reg.isSingleScan
                        ? 'Single usage'
                        : 'Multiple usage'),
                isDark: isDark,
                border: isExpiredUsed
                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                    : border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
              final countTile = _buildDetailTile(
                icon: isExpiredUsed
                    ? Icons.do_not_disturb_on_rounded
                    : Icons.how_to_reg_rounded,
                iconColor: isExpiredUsed
                    ? const Color(0xFFEF4444)
                    : (hasScanned
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFF59E0B)),
                title: isExpiredUsed
                    ? '${reg.scanCount} Used'
                    : '${reg.scanCount} '
                        '${reg.scanCount == 1 ? 'Usage' : 'Usages'}',
                subtitle: isExpiredUsed
                    ? 'Limit reached'
                    : (hasScanned ? 'Used pass' : 'Unused pass'),
                isDark: isDark,
                border: isExpiredUsed
                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                    : border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    policyTile,
                    const SizedBox(height: 8),
                    countTile,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: policyTile),
                  const SizedBox(width: 8),
                  Expanded(child: countTile),
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          // Last Used / Used At Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 14,
                  color: reg.usedAt != null
                      ? const Color(0xFF16A34A)
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Usage / Check-in',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        reg.usedAt != null
                            ? '${_formatDate(reg.usedAt!)} at '
                                  '${_formatTime(reg.usedAt!)}'
                            : 'Awaiting check-in',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: reg.usedAt != null
                              ? const Color(0xFF16A34A)
                              : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scan Types / Checkpoints
          if (reg.allowedScanTypes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Authorized Checkpoints',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reg.allowedScanTypes.map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Text(
                    _formatCheckpointName(type),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0369A1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelRegistration(
    BuildContext context,
    StudentRegistration reg,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel Registration?'),
        content: const Text(
          'Are you sure you want to surrender this pass?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Keep Pass'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Pass'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isCancelling = true);
      final success = await ref
          .read(studentRegistrationsProvider.notifier)
          .cancelPass(reg.id);

      if (success) {
        await ref.read(studentEventsProvider.notifier).loadEvents();
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration cancelled')),
        );
      }
    }
  }
}

/// Custom painter rendering a crisp, deterministic vector 2D QR matrix.
class _VectorQrMatrixPainter extends CustomPainter {
  _VectorQrMatrixPainter({
    required this.seed,
    required this.isDark,
  });

  final String seed;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black87
      ..style = PaintingStyle.fill;

    const matrixSize = 21;
    final cellSize = size.width / matrixSize;

    // Corner finder patterns
    void drawFinder(double x, double y) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, 7 * cellSize, 7 * cellSize),
        paint,
      );
      final whitePaint = Paint()
        ..color = isDark ? Colors.black87 : Colors.white
        ..style = PaintingStyle.fill;
      canvas
        ..drawRect(
          Rect.fromLTWH(
            x + cellSize,
            y + cellSize,
            5 * cellSize,
            5 * cellSize,
          ),
          whitePaint,
        )
        ..drawRect(
          Rect.fromLTWH(
            x + (2 * cellSize),
            y + (2 * cellSize),
            3 * cellSize,
            3 * cellSize,
          ),
          paint,
        );
    }

    drawFinder(0, 0);
    drawFinder((matrixSize - 7) * cellSize, 0);
    drawFinder(0, (matrixSize - 7) * cellSize);

    // Deterministic pseudo-random pattern based on seed
    final rand = Random(seed.hashCode.abs());

    for (var row = 0; row < matrixSize; row++) {
      for (var col = 0; col < matrixSize; col++) {
        // Skip finder regions
        final inTopLeft = row < 8 && col < 8;
        final inTopRight = row < 8 && col >= matrixSize - 8;
        final inBottomLeft = row >= matrixSize - 8 && col < 8;

        if (inTopLeft || inTopRight || inBottomLeft) {
          continue;
        }

        // Timing patterns
        if (row == 6 || col == 6) {
          if ((row + col).isEven) {
            canvas.drawRect(
              Rect.fromLTWH(
                col * cellSize,
                row * cellSize,
                cellSize,
                cellSize,
              ),
              paint,
            );
          }
          continue;
        }

        if (rand.nextBool()) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                col * cellSize,
                row * cellSize,
                cellSize * 0.92,
                cellSize * 0.92,
              ),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_VectorQrMatrixPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.isDark != isDark;
  }
}
