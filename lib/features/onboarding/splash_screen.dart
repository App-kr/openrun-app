import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _autoNavigating = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _checkOnboarded();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_complete') ?? false;
    if (!mounted) return;
    if (onboarded) {
      setState(() => _autoNavigating = true);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      context.go('/performances');
    }
  }

  void _goIntro() => context.go('/intro');

  @override
  Widget build(BuildContext context) {
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // 한지 크림색
      body: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: _autoNavigating ? null : _goIntro,
          child: Stack(
            children: [
              // ── 좌우 분할 패널 ────────────────────────────────────────
              Row(
                children: [
                  // ── 왼쪽: 클래식 ────────────────────────────────────
                  Expanded(
                    child: _IllustrationPanel(
                      imagePath: 'assets/images/splash_classic.png',
                      fallbackIconPath: 'assets/icons/classic/conductor.png',
                      accent: const Color(0xFF0D2B4E), // navy
                      label: '클래식',
                      sublabel: 'CLASSICAL',
                      align: Alignment.centerLeft,
                    ),
                  ),

                  // ── 오른쪽: 국악 ────────────────────────────────────
                  Expanded(
                    child: _IllustrationPanel(
                      imagePath: 'assets/images/splash_gugak.png',
                      fallbackIconPath: 'assets/icons/gugak/gayageum.png',
                      accent: const Color(0xFF8B5E08), // amber dark
                      label: '국악',
                      sublabel: 'GUGAK',
                      align: Alignment.centerRight,
                      isRight: true,
                    ),
                  ),
                ],
              ),

              // ── 중앙 구분선 ──────────────────────────────────────────
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 1,
                  height: double.infinity,
                  color: const Color(0xFFCCBFA8), // warm taupe
                ),
              ),

              // ── 상단 브랜딩 ──────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(top: safeTop + 20, bottom: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF7F4EF).withValues(alpha: 0.97),
                        const Color(0xFFF7F4EF).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '택킷',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'TAEKIT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF888888),
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 하단 CTA / 스피너 ────────────────────────────────────
              Positioned(
                bottom: safeBottom + 32,
                left: 0,
                right: 0,
                child: _autoNavigating
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: Color(0xFF888888),
                          ),
                        ),
                      )
                    : const Center(
                        child: Column(
                          children: [
                            Text(
                              '탭하여 시작',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFFAAAAAA),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 한쪽 패널 위젯 ─────────────────────────────────────────────────────────────
class _IllustrationPanel extends StatelessWidget {
  final String imagePath;
  final String fallbackIconPath;
  final Color accent;
  final String label;
  final String sublabel;
  final Alignment align;
  final bool isRight;

  const _IllustrationPanel({
    required this.imagePath,
    required this.fallbackIconPath,
    required this.accent,
    required this.label,
    required this.sublabel,
    required this.align,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F4EF),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 배경 일러스트 (전체 채우기) ───────────────────────────────
          Positioned.fill(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
              errorBuilder: (_, __, ___) => Padding(
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  fallbackIconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // ── 하단 레이블 그라디언트 ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF7F4EF).withValues(alpha: 0.98),
                    const Color(0xFFF7F4EF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── 레이블 텍스트 ─────────────────────────────────────────────
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: accent.withValues(alpha: 0.7),
                    letterSpacing: 2.5,
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
