import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Screen displaying system telemetry, gateway activity, and security audit
/// logs.
class AuditLogPage extends StatelessWidget {
  /// Default constructor for AuditLogPage.
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Telemetry & Audit',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time FLE operations, security events, and health.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Monitoring Live',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Log cards stream simulation
          Expanded(
            child: ListView(
              children: const [
                _LogTile(
                  timestamp: 'Just now',
                  service: 'Deno Core Gateway',
                  message: 'POST /api/auth/resolve-roles - JWT validated for '
                      'Super Admin session',
                  type: _LogType.info,
                ),
                _LogTile(
                  timestamp: '1 min ago',
                  service: 'FLE Cryptography Engine',
                  message:
                      'Blind index generated via HMAC-SHA256 with pepper key',
                  type: _LogType.security,
                ),
                _LogTile(
                  timestamp: '5 mins ago',
                  service: 'API Gateway',
                  message:
                      'Caddy reverse proxy route matched: /api/* -> :8000',
                  type: _LogType.info,
                ),
                _LogTile(
                  timestamp: '12 mins ago',
                  service: 'Go Daemon Service',
                  message: 'Worker pool initialized at :8080. Ready for '
                      'real-time WebSocket traffic',
                  type: _LogType.info,
                ),
                _LogTile(
                  timestamp: '30 mins ago',
                  service: 'Database Migration',
                  message:
                      'PostgreSQL RPC get_user_derived_roles verified',
                  type: _LogType.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _LogType { info, security, success }

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.timestamp,
    required this.service,
    required this.message,
    required this.type,
  });

  final String timestamp;
  final String service;
  final String message;
  final _LogType type;

  Color get _badgeColor {
    switch (type) {
      case _LogType.info:
        return AppColors.primaryLight;
      case _LogType.security:
        return AppColors.accent;
      case _LogType.success:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.terminal_rounded, size: 16, color: _badgeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      service,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _badgeColor,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
