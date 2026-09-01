import 'package:flutter/material.dart';

/// Supported authenticator brand/hardware types derived from friendly name.
enum PasskeyDeviceType {
  /// Apple platform authenticators (Touch ID, Face ID, iCloud Keychain).
  apple,

  /// Google Password Manager / Android biometrics.
  google,

  /// Windows Hello platform authenticator.
  windows,

  /// Dedicated physical security key (e.g. YubiKey, Titan).
  securityKey,

  /// Password managers (1Password, Bitwarden, Dashlane).
  passwordManager,

  /// Generic biometric or platform authenticator.
  generic;

  /// Icon representing this authenticator type.
  IconData get icon {
    switch (this) {
      case PasskeyDeviceType.apple:
        return Icons.apple_rounded;
      case PasskeyDeviceType.google:
        return Icons.android_rounded;
      case PasskeyDeviceType.windows:
        return Icons.desktop_windows_rounded;
      case PasskeyDeviceType.securityKey:
        return Icons.key_rounded;
      case PasskeyDeviceType.passwordManager:
        return Icons.lock_outline_rounded;
      case PasskeyDeviceType.generic:
        return Icons.fingerprint_rounded;
    }
  }

  /// Human-friendly display title for this authenticator category.
  String get displayName {
    switch (this) {
      case PasskeyDeviceType.apple:
        return 'Apple Device';
      case PasskeyDeviceType.google:
        return 'Google Device';
      case PasskeyDeviceType.windows:
        return 'Windows Device';
      case PasskeyDeviceType.securityKey:
        return 'Hardware Security Key';
      case PasskeyDeviceType.passwordManager:
        return 'Password Manager';
      case PasskeyDeviceType.generic:
        return 'Biometric Authenticator';
    }
  }
}

/// Represents a registered WebAuthn passkey credential.
@immutable
class AppPasskey {
  /// Default constructor for AppPasskey.
  const AppPasskey({
    required this.id,
    required this.friendlyName,
    required this.createdAt,
    this.lastUsedAt,
    this.aaguid,
  });

  /// Parses an AppPasskey from JSON or Supabase response map.
  factory AppPasskey.fromJson(Map<String, dynamic> json) {
    return AppPasskey(
      id: json['id'] as String? ?? '',
      friendlyName: json['friendly_name'] as String? ??
          json['friendlyName'] as String? ??
          'Passkey Credential',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.tryParse(json['last_used_at'].toString())
          : null,
      aaguid: json['aaguid'] as String?,
    );
  }

  /// Unique UUID of the registered passkey in Supabase Auth.
  final String id;

  /// Human-readable label (e.g., "MacBook Pro Touch ID", "YubiKey 5C").
  final String friendlyName;

  /// Registration timestamp.
  final DateTime createdAt;

  /// Timestamp of the most recent authentication with this credential.
  final DateTime? lastUsedAt;

  /// Authenticator Attestation GUID if provided by the authenticator.
  final String? aaguid;

  /// Infers the authenticator platform type from friendlyName or aaguid.
  PasskeyDeviceType get deviceType {
    final lower = friendlyName.toLowerCase();
    if (lower.contains('apple') ||
        lower.contains('icloud') ||
        lower.contains('mac') ||
        lower.contains('iphone') ||
        lower.contains('ipad')) {
      return PasskeyDeviceType.apple;
    }
    if (lower.contains('google') ||
        lower.contains('android') ||
        lower.contains('pixel')) {
      return PasskeyDeviceType.google;
    }
    if (lower.contains('windows') || lower.contains('hello')) {
      return PasskeyDeviceType.windows;
    }
    if (lower.contains('yubikey') ||
        lower.contains('titan') ||
        lower.contains('fido') ||
        lower.contains('hardware') ||
        lower.contains('key')) {
      return PasskeyDeviceType.securityKey;
    }
    if (lower.contains('1password') ||
        lower.contains('bitwarden') ||
        lower.contains('dashlane') ||
        lower.contains('keeper')) {
      return PasskeyDeviceType.passwordManager;
    }
    return PasskeyDeviceType.generic;
  }

  /// Copies this instance with optional updated fields.
  AppPasskey copyWith({
    String? id,
    String? friendlyName,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? aaguid,
  }) {
    return AppPasskey(
      id: id ?? this.id,
      friendlyName: friendlyName ?? this.friendlyName,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      aaguid: aaguid ?? this.aaguid,
    );
  }

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendly_name': friendlyName,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'aaguid': aaguid,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPasskey &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          friendlyName == other.friendlyName &&
          createdAt == other.createdAt &&
          lastUsedAt == other.lastUsedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      friendlyName.hashCode ^
      createdAt.hashCode ^
      lastUsedAt.hashCode;
}
