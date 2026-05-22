import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 스플래시 없음 — SharedPreferences 확인 후 즉시 이동.
/// 흰 화면 한 프레임만 렌더되고 바로 전환됨.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 다음 프레임에 즉시 이동 (SharedPreferences는 메모리 캐시라 ~1ms)
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboarded = prefs.getBool('onboarding_complete') ?? false;
    context.go(onboarded ? '/performances' : '/intro');
  }

  @override
  Widget build(BuildContext context) {
    // 배경색만 — 아무것도 안 보임
    return const Scaffold(
      backgroundColor: Color(0xFF0D2B4E),
    );
  }
}
