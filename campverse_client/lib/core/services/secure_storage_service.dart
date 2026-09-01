import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing hardware-encrypted local key-value persistence.
class SecureStorageService {
  /// Default constructor initializing encrypted preferences and keychain.
  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  final FlutterSecureStorage _storage;

  static const String _keyActiveRole = 'campverse_active_role';
  static const String _keyMfaVerifiedSession = 'campverse_mfa_verified_session';

  /// Key storing a JSON object: { "role": "...", "switched_at": "ISO8601" }.
  static const String _keyRoleSwitchTtl = 'campverse_role_switch_ttl';

  /// How long a switched role persists across app closes (minutes).
  static const int roleSwitchTtlMinutes = 30;

  /// Saves the user's active workspace role.
  Future<void> saveActiveRole(String role) async {
    await _storage.write(key: _keyActiveRole, value: role);
  }

  /// Retrieves the stored active workspace role if any.
  Future<String?> getActiveRole() async {
    return _storage.read(key: _keyActiveRole);
  }

  /// Clears the stored active role.
  Future<void> clearActiveRole() async {
    await _storage.delete(key: _keyActiveRole);
  }

  /// Records that MFA has been verified for the current session token.
  Future<void> setMfaVerifiedForSession(String sessionId) async {
    await _storage.write(key: _keyMfaVerifiedSession, value: sessionId);
  }

  /// Checks if MFA has already been cleared for the given session token.
  Future<bool> isMfaVerifiedForSession(String sessionId) async {
    final stored = await _storage.read(key: _keyMfaVerifiedSession);
    return stored == sessionId;
  }

  // ── Role Switch TTL ────────────────────────────────────────────────────────

  /// Persists a role switch with the current timestamp.
  ///
  /// Call this whenever the user explicitly switches to a non-base role.
  /// The timestamp is used on the next app open to decide whether to restore
  /// the switched role or fall back to [baseRole].
  Future<void> storeRoleSwitch(String role) async {
    final payload = jsonEncode({
      'role': role,
      'switched_at': DateTime.now().toUtc().toIso8601String(),
    });
    await _storage.write(key: _keyRoleSwitchTtl, value: payload);
  }

  /// Returns the switched role if it is still within [roleSwitchTtlMinutes],
  /// otherwise returns `null` (caller should revert to base role).
  Future<String?> getRestoredRoleIfValid() async {
    final raw = await _storage.read(key: _keyRoleSwitchTtl);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final role = decoded['role'] as String?;
      final switchedAt = decoded['switched_at'] as String?;

      if (role == null || switchedAt == null) return null;

      final switchedTime = DateTime.parse(switchedAt);
      final elapsed = DateTime.now().toUtc().difference(switchedTime);

      if (elapsed.inMinutes <= roleSwitchTtlMinutes) {
        return role;
      }

      // TTL expired — clear the stored switch
      await _storage.delete(key: _keyRoleSwitchTtl);
      return null;
    } on Object {
      await _storage.delete(key: _keyRoleSwitchTtl);
      return null;
    }
  }

  /// Clears the stored role switch (e.g. on sign out or explicit revert).
  Future<void> clearRoleSwitch() async {
    await _storage.delete(key: _keyRoleSwitchTtl);
  }

  /// Clears all encrypted storage entries on sign out.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
