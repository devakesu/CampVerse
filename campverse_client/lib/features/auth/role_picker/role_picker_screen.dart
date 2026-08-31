import 'dart:async';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/auth/role_picker/widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen allowing multi-role users to select their active workspace
/// perspective.
class RolePickerScreen extends ConsumerStatefulWidget {
  /// Default constructor for RolePickerScreen.
  const RolePickerScreen({super.key});

  @override
  ConsumerState<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends ConsumerState<RolePickerScreen> {
  AppRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final availableRoles = authState.availableRoles;
    final baseRole = authState.baseRole;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Select Workspace',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
              color: AppColors.textSecondaryOf(context),
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              size: 20,
              color: AppColors.textSecondaryOf(context),
            ),
            onPressed: () {
              unawaited(ref.read(authStateProvider.notifier).signOut());
            },
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Multi-Role Authorization',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimaryOf(context),
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the active profile perspective for this session. '
                    'You can switch roles anytime from the sidebar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 600 ? 2 : 1;
                        return GridView.builder(
                          itemCount: availableRoles.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: crossAxisCount == 2 ? 1.5 : 2.1,
                          ),
                          itemBuilder: (context, index) {
                            final role = availableRoles[index];
                            final isSelected = _selectedRole == role;

                            return RoleCard(
                              role: role,
                              isSelected: isSelected,
                              isBaseRole: role == baseRole,
                              onTap: () {
                                setState(() => _selectedRole = role);
                                unawaited(
                                  ref
                                      .read(authStateProvider.notifier)
                                      .switchRole(role),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  if (authState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
