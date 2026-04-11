import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'shared/services/notification_service.dart';

const String backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://openrun-api.onrender.com',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite FFI init for Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Debug: reset onboarding so the flow is always visible during development
  if (kDebugMode) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');
  }

  try {
    await Firebase.initializeApp();
    await NotificationService.instance.initialize();
  } catch (_) {
    // Firebase not configured for this platform — continue without notifications
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("FLUTTER_ERROR: ${details.exceptionAsString()}");
    debugPrint(details.stack.toString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("PLATFORM_ERROR: $error");
    debugPrint(stack.toString());
    return true;
  };
  runApp(const ProviderScope(child: OpenRunApp()));
}

class OpenRunApp extends ConsumerWidget {
  const OpenRunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'OpenRun',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
    );
  }
}
