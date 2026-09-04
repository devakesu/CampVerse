import 'dart:async';
import 'dart:convert';

import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/passkey_model.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/services/role_service.dart';
import 'package:campverse/core/services/secure_storage_service.dart';
import 'package:campverse/core/services/supabase_auth_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _createJwt({required int expSeconds, String role = 'student'}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': 'test-user-id',
            'exp': expSeconds,
            'app_metadata': {'active_role': role},
          }),
        ),
      )
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

Session _createSession({
  required int expiresAtSeconds,
  String refreshToken = 'test_refresh_token',
  String? accessToken,
}) {
  final token = accessToken ?? _createJwt(expSeconds: expiresAtSeconds);
  return Session.fromJson(<String, dynamic>{
    'access_token': token,
    'refresh_token': refreshToken,
    'expires_in': 3600,
    'token_type': 'bearer',
    'user': <String, dynamic>{
      'id': 'test-user-id',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-09-01T00:00:00.000Z',
    },
  })!;
}

class _MockSupabaseAuthService extends SupabaseAuthService {
  _MockSupabaseAuthService({
    SupabaseClient? client,
    Session? initialSession,
  })  : _session = initialSession,
        _authStateController = StreamController<AuthState>.broadcast(),
        super(
          client: client ??
              SupabaseClient(
                'http://localhost:54321',
                'dummy_publishable_key',
              ),
        );

  Session? _session;
  int refreshCallCount = 0;
  Session? nextRefreshedSession;
  final StreamController<AuthState> _authStateController;

  @override
  Session? get currentSession => _session;

  @override
  bool get isSessionExpired => _session?.isExpired ?? true;

  @override
  Future<Session?> getSession() async => _session;

  @override
  Future<AuthResponse> refreshSession([String? refreshToken]) async {
    refreshCallCount++;
    if (nextRefreshedSession != null) {
      _session = nextRefreshedSession;
      return AuthResponse(session: nextRefreshedSession);
    }
    return AuthResponse(session: _session);
  }

  @override
  Future<List<Factor>> getEnrolledMfaFactors() async => [];

  @override
  Future<List<AppPasskey>> listPasskeys() async => [];

  @override
  Future<void> signOut() async {
    _session = null;
  }

  void emitAuthState(AuthChangeEvent event, Session? session) {
    _authStateController.add(AuthState(event, session));
  }

  Future<void> dispose() async {
    await _authStateController.close();
  }
}

class _MockRoleService extends RoleService {
  _MockRoleService({
    SupabaseClient? supabaseClient,
  }) : super(
         supabaseClient: supabaseClient ??
             SupabaseClient(
               'http://localhost:54321',
               'dummy_publishable_key',
             ),
       );

  int checkLoginStatusCalls = 0;
  String? lastCheckedToken;

  @override
  Future<LoginStatusResult> checkLoginStatus(String accessToken) async {
    checkLoginStatusCalls++;
    lastCheckedToken = accessToken;
    return const LoginStatusResult(
      allowed: true,
      baseRole: AppRole.student,
      accountStatus: 'active',
    );
  }

  @override
  Future<List<AppRole>> resolveUserRoles(String accessToken) async {
    return const [AppRole.student];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('SupabaseAuthService Expiration & Refresh Methods', () {
    test('isSessionExpired returns true when currentSession is null', () async {
      final authService = _MockSupabaseAuthService();
      expect(authService.isSessionExpired, isTrue);
      await authService.dispose();
    });

    test(
      'isSessionExpired returns true when session expires in past',
      () async {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 5));
        final session = _createSession(
          expiresAtSeconds: pastTime.millisecondsSinceEpoch ~/ 1000,
        );
        final authService = _MockSupabaseAuthService(initialSession: session);
        expect(authService.isSessionExpired, isTrue);
        await authService.dispose();
      },
    );

    test('isSessionExpired returns false when session is fresh', () async {
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      final session = _createSession(
        expiresAtSeconds: futureTime.millisecondsSinceEpoch ~/ 1000,
      );
      final authService = _MockSupabaseAuthService(initialSession: session);
      expect(authService.isSessionExpired, isFalse);
      await authService.dispose();
    });
  });

  group('AuthNotifier Periodic & On-Demand Session Refresh', () {
    test('checkAndRefreshSession returns false when no session exists',
        () async {
      final authService = _MockSupabaseAuthService();
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
      );

      final result = await notifier.checkAndRefreshSession();
      expect(result, isFalse);
      expect(authService.refreshCallCount, 0);

      notifier.dispose();
      await authService.dispose();
    });

    test(
        'checkAndRefreshSession skips refresh when fresh (> 10 mins remain)',
        () async {
      final freshTime = DateTime.now().add(const Duration(minutes: 45));
      final session = _createSession(
        expiresAtSeconds: freshTime.millisecondsSinceEpoch ~/ 1000,
      );
      final authService = _MockSupabaseAuthService(initialSession: session);
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await notifier.checkAndRefreshSession();
      expect(result, isTrue);
      expect(authService.refreshCallCount, 0);

      notifier.dispose();
      await authService.dispose();
    });

    test(
        'checkAndRefreshSession refreshes when session expires in <= 10 mins',
        () async {
      final expiringSoonTime = DateTime.now().add(const Duration(minutes: 5));
      final session = _createSession(
        expiresAtSeconds: expiringSoonTime.millisecondsSinceEpoch ~/ 1000,
      );
      final refreshedTime = DateTime.now().add(const Duration(hours: 1));
      final refreshedSession = _createSession(
        expiresAtSeconds: refreshedTime.millisecondsSinceEpoch ~/ 1000,
      );

      final authService = _MockSupabaseAuthService(initialSession: session)
        ..nextRefreshedSession = refreshedSession;
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await notifier.checkAndRefreshSession();
      expect(result, isTrue);
      expect(authService.refreshCallCount, 1);
      expect(
        notifier.state.session?.accessToken,
        refreshedSession.accessToken,
      );
      expect(notifier.state.isLoading, isFalse);

      notifier.dispose();
      await authService.dispose();
    });

    test('checkAndRefreshSession forces refresh when force flag is true',
        () async {
      final freshTime = DateTime.now().add(const Duration(hours: 1));
      final session = _createSession(
        expiresAtSeconds: freshTime.millisecondsSinceEpoch ~/ 1000,
      );
      final refreshedSession = _createSession(
        expiresAtSeconds: freshTime.millisecondsSinceEpoch ~/ 1000,
      );

      final authService = _MockSupabaseAuthService(initialSession: session)
        ..nextRefreshedSession = refreshedSession;
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await notifier.checkAndRefreshSession(force: true);
      expect(result, isTrue);
      expect(authService.refreshCallCount, 1);
      expect(
        notifier.state.session?.accessToken,
        refreshedSession.accessToken,
      );

      notifier.dispose();
      await authService.dispose();
    });

    test(
        'checkAndRefreshSession updates state silently without toggling '
        'isLoading', () async {
      final expiringTime = DateTime.now().add(const Duration(minutes: 2));
      final session = _createSession(
        expiresAtSeconds: expiringTime.millisecondsSinceEpoch ~/ 1000,
      );
      final nextTime = DateTime.now().add(const Duration(hours: 1));
      final nextSession = _createSession(
        expiresAtSeconds: nextTime.millisecondsSinceEpoch ~/ 1000,
      );

      final authService = _MockSupabaseAuthService(initialSession: session)
        ..nextRefreshedSession = nextSession;
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.activeRole, AppRole.student);

      final states = <bool>[];
      notifier.addListener((state) {
        states.add(state.isLoading);
      });

      await notifier.checkAndRefreshSession();

      // State isLoading was never set back to true during silent refresh
      expect(states.every((loading) => !loading), isTrue);
      expect(notifier.state.session?.accessToken, nextSession.accessToken);
      expect(notifier.state.activeRole, AppRole.student);

      notifier.dispose();
      await authService.dispose();
    });
  });

  group('AuthNotifier App Lifecycle Resume & Periodic Timer', () {
    test('didChangeAppLifecycleState resumed triggers session check', () async {
      final expiringSoon = DateTime.now().add(const Duration(minutes: 4));
      final session = _createSession(
        expiresAtSeconds: expiringSoon.millisecondsSinceEpoch ~/ 1000,
      );
      final nextHour = DateTime.now().add(const Duration(hours: 1));
      final fresh = _createSession(
        expiresAtSeconds: nextHour.millisecondsSinceEpoch ~/ 1000,
      );

      final authService = _MockSupabaseAuthService(initialSession: session)
        ..nextRefreshedSession = fresh;
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(authService.refreshCallCount, 1);
      expect(notifier.state.session?.accessToken, fresh.accessToken);

      notifier.dispose();
      await authService.dispose();
    });

    test('Periodic timer automatically refreshes session while app open',
        () async {
      final expiringSoon = DateTime.now().add(const Duration(minutes: 3));
      final session = _createSession(
        expiresAtSeconds: expiringSoon.millisecondsSinceEpoch ~/ 1000,
      );
      final nextHour = DateTime.now().add(const Duration(hours: 1));
      final fresh = _createSession(
        expiresAtSeconds: nextHour.millisecondsSinceEpoch ~/ 1000,
      );

      final authService = _MockSupabaseAuthService(initialSession: session)
        ..nextRefreshedSession = fresh;
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      // Configure a short 30ms refresh interval for test
      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
        refreshInterval: const Duration(milliseconds: 30),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(authService.refreshCallCount, 0);

      // Wait for periodic timer to tick
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(authService.refreshCallCount, greaterThanOrEqualTo(1));
      expect(notifier.state.session?.accessToken, fresh.accessToken);

      notifier.dispose();
      await authService.dispose();
    });
  });

  group('AuthNotifier Expired Session Recovery on Startup', () {
    test(
        '_processSession recovers expired session before loginStatus check',
        () async {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 10));
      final expiredSession = _createSession(
        expiresAtSeconds: pastTime.millisecondsSinceEpoch ~/ 1000,
      );
      final nextHour = DateTime.now().add(const Duration(hours: 1));
      final freshSession = _createSession(
        expiresAtSeconds: nextHour.millisecondsSinceEpoch ~/ 1000,
      );

      final authService =
          _MockSupabaseAuthService(initialSession: expiredSession)
            ..nextRefreshedSession = freshSession;
      final roleService = _MockRoleService();
      final storageService = SecureStorageService();

      final notifier = AuthNotifier(
        authService: authService,
        roleService: roleService,
        storageService: storageService,
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Refresh was called because the initial session was expired
      expect(authService.refreshCallCount, 1);
      // checkLoginStatus received the FRESH token, NOT the expired one
      expect(roleService.lastCheckedToken, freshSession.accessToken);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.session?.accessToken, freshSession.accessToken);

      notifier.dispose();
      await authService.dispose();
    });
  });
}
