import 'package:campverse/features/student/models/student_event.dart';
import 'package:flutter/foundation.dart';

/// Represents a student's event registration pass with cryptographic QR code
/// or secret code.
@immutable
class StudentRegistration {
  /// Default constructor for StudentRegistration.
  const StudentRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.qrPayload,
    this.secretCode,
    this.isSingleScan = true,
    this.scanCount = 0,
    this.allowedScanTypes = const ['entry'],
    this.scanHistory = const [],
    this.event,
    DateTime? usedAt,
    DateTime? scannedAt,
  }) : usedAt = usedAt ?? scannedAt;

  /// Factory constructor parsing from Supabase joined query.
  factory StudentRegistration.fromJson(Map<String, dynamic> json) {
    final eventMap = json['events'] as Map<String, dynamic>?;

    final parsedAllowedTypes = (json['allowed_scan_types'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['entry'];

    final parsedScanHistory = (json['scan_history'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const [];

    return StudentRegistration(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'confirmed',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      qrPayload: json['qr_payload'] as String?,
      secretCode: json['secret_code'] as String?,
      isSingleScan: json['is_single_scan'] as bool? ?? true,
      scanCount: (json['scan_count'] as num?)?.toInt() ?? 0,
      allowedScanTypes: parsedAllowedTypes,
      scanHistory: parsedScanHistory,
      event: eventMap != null
          ? StudentEvent.fromJson(eventMap, isRegistered: true)
          : null,
      usedAt: json['used_at'] != null
          ? DateTime.tryParse(json['used_at'].toString())
          : (json['scanned_at'] != null
              ? DateTime.tryParse(json['scanned_at'].toString())
              : null),
    );
  }

  /// Registration entry ID.
  final String id;

  /// Target event identifier.
  final String eventId;

  /// Registering student user ID.
  final String userId;

  /// Cryptographic QR token payload for gate check-in scanners (optional).
  final String? qrPayload;

  /// 8-character verification secret code for desk check-ins (optional).
  final String? secretCode;

  /// Whether the pass is single-use only or can be scanned multiple times.
  final bool isSingleScan;

  /// How many times this pass has been scanned or validated.
  final int scanCount;

  /// Allowed scan checkpoints / types (e.g. ['entry', 'food', 'kit']).
  final List<String> allowedScanTypes;

  /// History of individual scan events with timestamp and checkpoint type.
  final List<Map<String, dynamic>> scanHistory;

  /// Ticket status: 'reserved', 'confirmed', 'used', 'cancelled'.
  final String status;

  /// Registration timestamp.
  final DateTime createdAt;

  /// Associated event details if joined.
  final StudentEvent? event;

  /// Timestamp when scanned / used at entry gate, if used.
  final DateTime? usedAt;

  /// Alias for usedAt for backward compatibility.
  DateTime? get scannedAt => usedAt;

  /// Whether a valid QR payload is available.
  bool get hasQr => qrPayload != null && qrPayload!.trim().isNotEmpty;

  /// Whether a desk verification secret code is available.
  bool get hasSecretCode =>
      secretCode != null && secretCode!.trim().isNotEmpty;

  /// Safe display code: secret code, QR payload, or generated fallback
  /// identifier.
  String get displayCode {
    if (hasSecretCode) {
      return secretCode!;
    }
    if (hasQr) {
      return qrPayload!;
    }
    if (id.isNotEmpty) {
      final safeLen = id.length > 8 ? 8 : id.length;
      return 'PASS-${id.substring(0, safeLen).toUpperCase()}';
    }
    return 'PASS-PENDING';
  }

  /// Whether this pass is single-use and has already been redeemed
  /// (use count > 0 or marked used).
  bool get isSingleUseExpired => isSingleScan && (scanCount > 0 || isUsed);

  /// Whether the pass is currently valid and active for entry.
  bool get isActive => status == 'confirmed' && !isSingleUseExpired;

  /// Whether the pass has already been scanned and marked used.
  bool get isUsed => status == 'used';

  /// Whether the registration has been cancelled.
  bool get isCancelled => status == 'cancelled';

  /// Whether the associated event has already concluded or pass has expired.
  bool get isExpired {
    if (isSingleUseExpired) {
      return true;
    }
    if (event == null) {
      return false;
    }
    return DateTime.now().isAfter(event!.endTime);
  }

  /// Creates a copy with optional overrides.
  StudentRegistration copyWith({
    String? status,
    String? qrPayload,
    String? secretCode,
    bool? isSingleScan,
    int? scanCount,
    List<String>? allowedScanTypes,
    List<Map<String, dynamic>>? scanHistory,
    DateTime? usedAt,
    DateTime? scannedAt,
    StudentEvent? event,
  }) {
    return StudentRegistration(
      id: id,
      eventId: eventId,
      userId: userId,
      status: status ?? this.status,
      createdAt: createdAt,
      qrPayload: qrPayload ?? this.qrPayload,
      secretCode: secretCode ?? this.secretCode,
      isSingleScan: isSingleScan ?? this.isSingleScan,
      scanCount: scanCount ?? this.scanCount,
      allowedScanTypes: allowedScanTypes ?? this.allowedScanTypes,
      scanHistory: scanHistory ?? this.scanHistory,
      event: event ?? this.event,
      usedAt: usedAt ?? scannedAt ?? this.usedAt,
    );
  }
}
