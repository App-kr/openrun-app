import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      bg1: Color(0xFF0D2B4E),
      bg2: Color(0xFF1A3F6F),
      icon: Icons.confirmation_number_outlined,
      iconColor: Color(0xFF7EB3E8),
      title: '택킷에 오신 걸\n환영합니다',
      subtitle: '클래식 · 국악 공연 티켓 오픈 알림\n한 곳에서 모아보세요',
    ),
    _Slide(
      bg1: Color(0xFF0D2B4E),
      bg2: Color(0xFF1B3A5C),
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFFFFD97D),
      title: '티켓 오픈 순간을\n놓치지 마세요',
      subtitle: '원하는 공연을 저장하면\n오픈 전 알림을 보내드려요',
    ),
    _Slide(
      bg1: Color(0xFF12243A),
      bg2: Color(0xFF0D2B4E),
      icon: Icons.calendar_month_outlined,
      iconColor: Color(0xFF90E0C0),
      title: '전국 주요 공연장\n한눈에 보기',
      subtitle: '예술의전당, 세종문화회관, 국립국악원 등\n국립 · 시립 공연장을 통합 제공해요',
    ),
    _Slide(
      bg1: Color(0xFF1A3F6F),
      bg2: Color(0xFF0D2B4E),
      icon: Icons.music_note_outlined,
      iconColor: Color(0xFFB39DDB),
      title: '무료 입장 공연도\n바로 확인',
      subtitle: '수수료 없이 즐기는 클래식 · 국악\n무료 공연 정보도 알려드려요',
    ),
  ];

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/performances');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
          ),

          // 건너뛰기
          if (!isLast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: TextButton(
                onPressed: _start,
                child: const Text(
                  '건너뛰기',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),

          // 하단 인디케이터 + 버튼
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // 점 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // 다음 / 시작하기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLast
                        ? _start
                        : () => _ctrl.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D2B4E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(isLast ? '시작하기' : '다음'),
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

class _Slide {
  final Color bg1, bg2;
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  const _Slide({
    required this.bg1,
    required this.bg2,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [slide.bg1, slide.bg2],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(slide.icon, size: 60, color: slide.iconColor),
              ),
              const SizedBox(height: 48),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
