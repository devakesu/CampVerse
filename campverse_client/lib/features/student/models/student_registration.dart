import 'package:campverse/features/student/models/student_event.dart';
import 'package:flutter/foundation.dart';

/// Represents a student's event registration pass with cryptographic QR code.
@immutable
class StudentRegistration {
  /// Default constructor for StudentRegistration.
  const StudentRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.qrPayload,
    required this.status,
    required this.createdAt,
    this.event,
    this.scannedAt,
  });

  /// Factory constructor parsing from Supabase joined query.
  factory StudentRegistration.fromJson(Map<String, dynamic> json) {
    final eventMap = json['events'] as Map<String, dynamic>?;

    return StudentRegistration(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      qrPayload: json['qr_payload'] as String? ??
          'CAMP-PASS-${json['id'] ?? 'SAMPLE'}',
      status: json['status'] as String? ?? 'confirmed',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      event: eventMap != null
          ? StudentEvent.fromJson(eventMap, isRegistered: true)
          : null,
      scannedAt: json['scanned_at'] != null
          ? DateTime.tryParse(json['scanned_at'].toString())
          : null,
    );
  }

  /// Registration entry ID.
  final String id;

  /// Target event identifier.
  final String eventId;

  /// Registering student user ID.
  final String userId;

  /// Cryptographic QR token payload for gate check-in scanners.
  final String qrPayload;

  /// Ticket status: 'reserved', 'confirmed', 'used', 'cancelled'.
  final String status;

  /// Registration timestamp.
  final DateTime createdAt;

  /// Associated event details if joined.
  final StudentEvent? event;

  /// Timestamp when scanned at entry gate, if used.
  final DateTime? scannedAt;

  /// Whether the pass is currently valid and active for entry.
  bool get isActive => status == 'confirmed';

  /// Whether the pass has already been scanned and used at the gate.
  bool get isUsed => status == 'used';

  /// Whether the registration has been cancelled.
  bool get isCancelled => status == 'cancelled';

  /// Whether the associated event has already concluded.
  bool get isExpired {
    if (event == null) {
      return false;
    }
    return DateTime.now().isAfter(event!.endTime);
  }

  /// Creates a copy with optional overrides.
  StudentRegistration copyWith({
    String? status,
    DateTime? scannedAt,
    StudentEvent? event,
  }) {
    return StudentRegistration(
      id: id,
      eventId: eventId,
      userId: userId,
      qrPayload: qrPayload,
      status: status ?? this.status,
      createdAt: createdAt,
      event: event ?? this.event,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}
