import 'package:campverse/core/config/app_config.dart';
import 'package:campverse/core/router/app_router.dart';
import 'package:campverse/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget configuring theme and GoRouter.
class CampVerseApp extends ConsumerWidget {
  /// Default constructor for CampVerseApp.
  const CampVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
