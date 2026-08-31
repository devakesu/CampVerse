import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for adding a new state or affiliating university.
class AddUniversityPage extends ConsumerStatefulWidget {
  /// Default constructor for AddUniversityPage.
  const AddUniversityPage({super.key});

  @override
  ConsumerState<AddUniversityPage> createState() => _AddUniversityPageState();
}

class _AddUniversityPageState extends ConsumerState<AddUniversityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _stateController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _stateController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final service = ref.read(superAdminServiceProvider);
    final result = await service.createUniversity(
      name: _nameController.text,
      slug: _slugController.text,
      state: _stateController.text,
      website: _websiteController.text.isNotEmpty
          ? _websiteController.text
          : null,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) {
      return;
    }

    if (result.success) {
      await ref.read(universitiesProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('University registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to register university.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          'Add Affiliated University',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderOf(context)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'University Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Register a state or central affiliating university for '
                      'curriculum and institute onboarding.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: AppColors.textPrimaryOf(context)),
                      decoration: const InputDecoration(
                        labelText: 'University Name *',
                        hintText: 'e.g. APJ Abdul Kalam Tech University',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter university name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _slugController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Slug / Code *',
                              hintText: 'e.g. KTU',
                              prefixIcon: Icon(Icons.short_text_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Code required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _stateController,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'State / Province *',
                              hintText: 'e.g. Kerala',
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'State is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      style: TextStyle(color: AppColors.textPrimaryOf(context)),
                      decoration: const InputDecoration(
                        labelText: 'Official Website URL',
                        hintText: 'https://ktu.edu.in',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roleSuperAdmin,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded),
                                SizedBox(width: 8),
                                Text('Register University'),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
