import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

  // Render 콜드스타트 방지: 4분마다 keep-alive ping
  // Render free tier는 5분 비활성 시 슬립 → 4분 주기로 항상 깨어있게 유지
  _startKeepAlivePing();

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
  runApp(const ProviderScope(child: TaekitApp()));
}

/// Render free tier 슬립 방지 — 4분마다 /health ping
/// dart:io HttpClient 사용 (추가 패키지 불필요)
void _startKeepAlivePing() {
  Timer.periodic(const Duration(minutes: 4), (_) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse('$backendUrl/health'));
      final res = await req.close();
      await res.drain<void>();
      client.close();
    } catch (_) {
      // 실패해도 무시 — 다음 주기에 재시도
    }
  });
}

class TaekitApp extends ConsumerWidget {
  const TaekitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Taekit',
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
