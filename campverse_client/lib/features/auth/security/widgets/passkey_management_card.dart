import 'dart:async';
import 'package:campverse/core/models/passkey_model.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive card managing WebAuthn Passkeys for the current user.
class PasskeyManagementCard extends ConsumerWidget {
  /// Default constructor for PasskeyManagementCard.
  const PasskeyManagementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final authState = ref.watch(authStateProvider);
    final passkeys = authState.userPasskeys;
    final isLoading = authState.isLoadingPasskeys;

    final primaryAccent =
        isDark ? const Color(0xFF818CF8) : const Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: primaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passkeys & WebAuthn',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phishing-resistant biometrics & security keys.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _showAddPasskeyDialog(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Add Passkey',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.borderOf(context), height: 1),
          const SizedBox(height: 16),

          // Content: Loading / Empty / List
          if (isLoading && passkeys.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: primaryAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Accessing device security subsystem...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (passkeys.isEmpty)
            _buildEmptyState(context, ref, primaryAccent)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: passkeys.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final passkey = passkeys[index];
                return _buildPasskeyItem(
                  context,
                  ref,
                  passkey,
                  isDark,
                  primaryAccent,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    Color primaryAccent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.key_off_rounded,
            size: 38,
            color: AppColors.textMutedOf(context),
          ),
          const SizedBox(height: 10),
          Text(
            'No Passkeys Registered',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              'Enroll your Touch ID, Face ID, Windows Hello, or security key '
              'to sign in with a single tap without entering passwords.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showAddPasskeyDialog(context, ref),
            icon: const Icon(Icons.fingerprint_rounded, size: 16),
            label: const Text('Register This Device'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasskeyItem(
    BuildContext context,
    WidgetRef ref,
    AppPasskey passkey,
    bool isDark,
    Color primaryAccent,
  ) {
    final createdStr = 'Added ${_formatDate(passkey.createdAt)}';
    final lastUsedStr = passkey.lastUsedAt != null
        ? 'Last used ${_formatDate(passkey.lastUsedAt!)}'
        : 'Never used';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Icon(
              passkey.deviceType.icon,
              size: 20,
              color: primaryAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        passkey.friendlyName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$createdStr • $lastUsedStr',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: AppColors.textSecondaryOf(context),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.borderOf(context)),
            ),
            color: AppColors.surfaceOf(context),
            onSelected: (value) {
              if (value == 'rename') {
                unawaited(_showRenamePasskeyDialog(context, ref, passkey));
              } else if (value == 'delete') {
                unawaited(_showDeletePasskeyDialog(context, ref, passkey));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 10),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Revoke',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _showAddPasskeyDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController(text: 'Campus Device');

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceOf(dialogCtx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.fingerprint_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Register New Passkey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(dialogCtx),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give this passkey a friendly label so you can recognize it.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(dialogCtx),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimaryOf(dialogCtx),
                ),
                decoration: InputDecoration(
                  labelText: 'Device / Passkey Name',
                  hintText: 'e.g. MacBook Pro, YubiKey 5C, Work laptop',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final label = nameController.text.trim();
                Navigator.of(dialogCtx).pop();
                unawaited(
                  ref.read(authStateProvider.notifier).registerPasskey(
                        friendlyName: label.isNotEmpty ? label : 'Passkey',
                      ),
                );
              },
              child: const Text('Continue to Biometrics'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenamePasskeyDialog(
    BuildContext context,
    WidgetRef ref,
    AppPasskey passkey,
  ) async {
    final controller = TextEditingController(text: passkey.friendlyName);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceOf(dialogCtx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Rename Passkey',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(dialogCtx),
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Friendly Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newName = controller.text.trim();
                Navigator.of(dialogCtx).pop();
                if (newName.isNotEmpty && newName != passkey.friendlyName) {
                  unawaited(
                    ref.read(authStateProvider.notifier).updatePasskeyName(
                          passkeyId: passkey.id,
                          friendlyName: newName,
                        ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeletePasskeyDialog(
    BuildContext context,
    WidgetRef ref,
    AppPasskey passkey,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceOf(dialogCtx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Revoke Passkey?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(dialogCtx),
            ),
          ),
          content: Text(
            'Are you sure you want to revoke "${passkey.friendlyName}"? '
            'You will no longer be able to use it for one-touch sign-in.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondaryOf(dialogCtx),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                unawaited(
                  ref.read(authStateProvider.notifier).deletePasskey(
                        passkeyId: passkey.id,
                      ),
                );
              },
              child: const Text('Revoke Credential'),
            ),
          ],
        );
      },
    );
  }
}
