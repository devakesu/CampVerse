import 'dart:async';
import 'dart:math';

import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive modal sheet rendering an authenticated digital QR entry pass.
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
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final reg = widget.registration;
    final event = reg.event;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                  : const Color(0xFF0369A1).withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.blueGrey)
                    .withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ticket Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0369A1).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: Color(0xFF0284C7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event?.title ?? 'Campus Entry Pass',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event?.venue ?? 'Campus Venue',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryOf(context),
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
                        color: i.isEven
                            ? AppColors.borderOf(context)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),

              // Ticket Body & QR
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: reg.isActive
                            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                            : AppColors.borderOf(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: reg.isActive
                              ? const Color(0xFF16A34A)
                              : Colors.grey,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            reg.isActive
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            size: 14,
                            color: reg.isActive
                                ? const Color(0xFF16A34A)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reg.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: reg.isActive
                                  ? const Color(0xFF16A34A)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Vector QR Code with Animated Scanline
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _VectorQrMatrixPainter(
                              seed: reg.qrPayload,
                              isDark: false,
                            ),
                          ),
                        ),
                        // Animated glowing scanline
                        AnimatedBuilder(
                          animation: _animCtrl,
                          builder: (context, child) {
                            return Positioned(
                              top: 20 + (_animCtrl.value * 140),
                              child: Container(
                                width: 160,
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Pass Payload Token
                    InkWell(
                      onTap: () {
                        unawaited(
                          Clipboard.setData(
                            ClipboardData(text: reg.qrPayload),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pass token copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reg.qrPayload,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Scan this QR at the entrance gate for instant check-in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),

                    // KTU points incentive badge
                    if (event != null && event.ktuActivityPoints > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              size: 16,
                              color: Color(0xFF8B5CF6),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '+${event.ktuActivityPoints} '
                                'KTU Activity Points on Check-in',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Cancel Registration Button
                    if (reg.isActive)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isCancelling
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Cancel Registration?'),
                                      content: const Text(
                                        'Are you sure you want to surrender '
                                        'this pass?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop(false),
                                          child: const Text('Keep Pass'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                          ),
                                          child: const Text('Cancel Pass'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    setState(() => _isCancelling = true);
                                    await ref
                                        .read(
                                          studentRegistrationsProvider.notifier,
                                        )
                                        .cancelPass(reg.id);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
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
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering a crisp, deterministic vector 2D QR matrix.
class _VectorQrMatrixPainter extends CustomPainter {
  const _VectorQrMatrixPainter({
    required this.seed,
    required this.isDark,
  });

  final String seed;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    const gridSize = 19;
    final cellSize = size.width / gridSize;

    // Corner Finder Patterns (7x7 squares at corners)
    _drawFinderPattern(canvas, paint, 0, 0, cellSize);
    _drawFinderPattern(canvas, paint, gridSize - 7, 0, cellSize);
    _drawFinderPattern(canvas, paint, 0, gridSize - 7, cellSize);

    // Deterministic module generation from seed hash
    final random = Random(seed.hashCode);

    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        // Skip finder pattern zones
        final inTopLeft = r < 7 && c < 7;
        final inTopRight = r < 7 && c >= gridSize - 7;
        final inBottomLeft = r >= gridSize - 7 && c < 7;

        if (inTopLeft || inTopRight || inBottomLeft) {
          continue;
        }

        // Timing patterns
        if (r == 6 || c == 6) {
          if ((r + c).isEven) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  c * cellSize,
                  r * cellSize,
                  cellSize - 0.5,
                  cellSize - 0.5,
                ),
                const Radius.circular(1),
              ),
              paint,
            );
          }
          continue;
        }

        // Pseudo-random deterministic fill based on seed
        if (random.nextBool()) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellSize,
                r * cellSize,
                cellSize - 0.5,
                cellSize - 0.5,
              ),
              const Radius.circular(1),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(
    Canvas canvas,
    Paint paint,
    int startCol,
    int startRow,
    double cellSize,
  ) {
    // Outer 7x7
    canvas.drawRect(
      Rect.fromLTWH(
        startCol * cellSize,
        startRow * cellSize,
        7 * cellSize,
        7 * cellSize,
      ),
      paint,
    );

    // Inner 5x5 cutout
    final clearPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas
      ..drawRect(
        Rect.fromLTWH(
          (startCol + 1) * cellSize,
          (startRow + 1) * cellSize,
          5 * cellSize,
          5 * cellSize,
        ),
        clearPaint,
      )
      ..drawRect(
        Rect.fromLTWH(
          (startCol + 2) * cellSize,
          (startRow + 2) * cellSize,
          3 * cellSize,
          3 * cellSize,
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _VectorQrMatrixPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.isDark != isDark;
}
