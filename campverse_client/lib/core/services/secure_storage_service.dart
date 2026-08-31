import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service managing hardware-encrypted local key-value persistence.
class SecureStorageService {
  /// Default constructor initializing encrypted preferences and keychain.
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions:
              IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final FlutterSecureStorage _storage;

  static const String _keyActiveRole = 'campverse_active_role';
  static const String _keyMfaVerifiedSession =
      'campverse_mfa_verified_session';

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

  /// Clears all encrypted storage entries on sign out.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
