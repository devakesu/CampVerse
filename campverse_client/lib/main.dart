import 'package:campverse/app.dart';
import 'package:campverse/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Application entry point initializing Supabase and running CampVerseApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  } on Exception catch (e) {
    debugPrint('Supabase initialization notice (offline/custom config): $e');
  }

  runApp(
    const ProviderScope(
      child: CampVerseApp(),
    ),
  );
}
