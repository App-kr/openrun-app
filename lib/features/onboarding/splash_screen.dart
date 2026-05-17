import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── 가야금 CustomPaint 아이콘 ──────────────────────────────────────────────
class _GayageumIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _GayageumIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GayageumPainter(color)),
    );
  }
}

class _GayageumPainter extends CustomPainter {
  final Color color;
  _GayageumPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // 몸체 — 긴 직사각형 (살짝 둥근 모서리)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.12, w * 0.7, h * 0.76),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, paint);

    // 양쪽 끝 지지대 (안족/괘)
    final bridgePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 상단 지지대
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.08, w * 0.6, h * 0.06),
        const Radius.circular(3),
      ),
      bridgePaint,
    );

    // 하단 지지대
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.86, w * 0.6, h * 0.06),
        const Radius.circular(3),
      ),
      bridgePaint,
    );

    // 6개 현 (가로선)
    final stringPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;

    for (int i = 0; i < 6; i++) {
      final x = w * 0.25 + (w * 0.5) * (i / 5);
      canvas.drawLine(
        Offset(x, h * 0.14),
        Offset(x, h * 0.86),
        stringPaint,
      );
    }

    // 안족 (중간 삼각형 지지대들)
    final anjokPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final x = w * 0.25 + (w * 0.5) * (i / 5);
      final y = h * 0.45 + (i % 2 == 0 ? 0 : h * 0.08);
      final path = Path()
        ..moveTo(x - 4, y + 6)
        ..lineTo(x, y - 4)
        ..lineTo(x + 4, y + 6)
        ..close();
      canvas.drawPath(path, anjokPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _autoNavigating = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarded();
  }

  Future<void> _checkOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_complete') ?? false;
    if (!mounted) return;
    if (onboarded) {
      setState(() => _autoNavigating = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      context.go('/performances');
    }
  }

  void _goIntro() {
    context.go('/intro');
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // ── Split background ─────────────────────────────────────
          Row(
            children: [
              // ── Left: Classic — dark navy ─────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: _autoNavigating ? null : () => _goIntro(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D2B4E), // dark navy base
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0D2B4E), Color(0xFF1A3F6F)],
                      ),
                    ),
                    child: _HalfPanel(
                      imagePath: 'assets/icons/classic/conductor.png',
                      fallbackIcon: Icons.piano,
                      fallbackIconColor: const Color(0xFF7EB3E8),
                      headline: '클래식 공연\n일정 찾기',
                      subheadline: 'CLASSIC MUSIC',
                      textColor: Colors.white,
                      pillColor: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),

              // ── Right: Gugak — golden amber (태극 feel) ───────────
              Expanded(
                child: GestureDetector(
                  onTap: _autoNavigating ? null : () => _goIntro(),
                  child: Container(
                    color: const Color(0xFFB8720A),
                    child: Stack(
                      children: [
                        // subtle warm gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFD4860A), Color(0xFF8B5E08)],
                              ),
                            ),
                          ),
                        ),
                        _HalfPanel(
                          imagePath: 'assets/icons/gugak/gayageum.png',
                          fallbackWidget: const _GayageumIcon(size: 80, color: Color(0xFFFFE5A0)),
                          headline: '국악 공연\n찾기',
                          subheadline: 'TRADITIONAL KOREAN MUSIC',
                          textColor: Colors.white,
                          pillColor: Colors.white.withValues(alpha: 0.18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Top center: "택킷" branding spanning both halves ────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: safeTop + 14, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 7),
                  Text(
                    '택킷',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Center vertical divider ────────────────────────────────
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 1.5,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),

          // ── Auto-navigate spinner ──────────────────────────────────
          if (_autoNavigating)
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── One half of the split screen ──────────────────────────────────────────────
class _HalfPanel extends StatelessWidget {
  final String imagePath;
  final IconData? fallbackIcon;
  final Color? fallbackIconColor;
  final Widget? fallbackWidget;
  final String headline;
  final String subheadline;
  final Color textColor;
  final Color pillColor;

  const _HalfPanel({
    required this.imagePath,
    this.fallbackIcon,
    this.fallbackIconColor,
    this.fallbackWidget,
    required this.headline,
    required this.subheadline,
    required this.textColor,
    required this.pillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60), // space for top logo

          // ── Illustration ──────────────────────────────────────────
          Image.asset(
            imagePath,
            width: 110,
            height: 110,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallbackWidget ?? Icon(
              fallbackIcon ?? Icons.music_note,
              size: 80,
              color: fallbackIconColor ?? Colors.white,
            ),
          ),

          const SizedBox(height: 28),

          // ── Main headline ─────────────────────────────────────────
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),

          const SizedBox(height: 8),

          // ── Sub headline ──────────────────────────────────────────
          Text(
            subheadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 1.2,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
            ),
          ),

          const SizedBox(height: 32),

          // ── Tap pill ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: const Text(
              '공연 보기 →',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
