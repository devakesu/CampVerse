import 'package:campverse/features/student/models/student_class_details.dart';
import 'package:flutter/material.dart';

/// Digital Campus Identity Card rendering institutional credentials
/// with holographic gradient styling and library barcode.
class StudentIdCard extends StatelessWidget {
  /// Default constructor.
  const StudentIdCard({
    required this.studentName,
    required this.studentEmail,
    required this.classDetails,
    this.admissionNo = '23CS042',
    this.universityRegNo = 'KTE23CS042',
    this.instituteName = 'Govt. Model Engineering College',
    super.key,
  });

  /// Student display name.
  final String studentName;

  /// Student institutional email.
  final String studentEmail;

  /// Class and programme details.
  final StudentClassDetails classDetails;

  /// Student admission number.
  final String admissionNo;

  /// University registration index.
  final String universityRegNo;

  /// Institute title.
  final String instituteName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0369A1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0369A1).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Subtle holographic background watermark / circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Institute & Smart Card Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instituteName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF93C5FD),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'CAMPUS STUDENT IDENTITY PASS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Gold Smart Chip
                    Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFB45309),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Student Identity Section
                Row(
                  children: [
                    // Avatar / Photo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          studentName.isNotEmpty
                              ? studentName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF38BDF8),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            studentEmail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              classDetails.displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7DD3FC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Academic Cohort & Identifiers Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIdDetail('ADMISSION NO.', admissionNo),
                      _buildIdDetail('REG NO.', universityRegNo),
                      _buildIdDetail('BATCH', classDetails.batchYearString),
                      _buildIdDetail('SEM', 'S${classDetails.currentSemester}'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Library / Gate Barcode
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Barcode custom graphic
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: CustomPaint(
                          painter: _BarcodePainter(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'KTU AUTHORIZED PASS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdDetail(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.fill;

    // Pseudo barcode stripes
    final barWidths = [
      1.5, 3.0, 1.0, 4.0, 2.0, 1.0, 3.0, 1.5, 2.0, 4.0, 1.0, 2.5, 1.5, 3.5,
      1.0, 2.0, 4.0, 1.5, 3.0, 1.0, 2.5, 1.5, 3.0, 2.0, 1.0, 4.0, 2.0, 1.5,
      3.0, 1.0, 2.0, 3.5, 1.5, 2.0, 1.0, 3.0, 2.5, 1.0, 4.0, 1.5,
    ];

    var x = 0.0;
    for (var i = 0; i < barWidths.length && x < size.width; i++) {
      final width = barWidths[i];
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      }
      x += width + 1.2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
