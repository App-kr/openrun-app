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
      stepLabel: '01',
      title: '택킷에 오신 걸\n환영합니다',
      body:
          '클래식과 국악 공연의 티켓 오픈 알림을\n'
          '한 곳에서 모아볼 수 있어요.\n\n'
          '더 이상 티켓 오픈 시간을\n놓치지 마세요.',
    ),
    _Slide(
      stepLabel: '02',
      title: '전국 공연장\n한눈에',
      body:
          '예술의전당, 세종문화회관,\n'
          '국립국악원, 롯데콘서트홀 등\n\n'
          '전국 주요 공연장의 공연 일정을\n'
          '통합해서 제공해요.',
    ),
    _Slide(
      stepLabel: '03',
      title: '오픈 알림을\n미리 받으세요',
      body:
          '관심 공연을 저장하면\n'
          '티켓 오픈 전 알림을 보내드려요.\n\n'
          '10분 전, 1시간 전, 24시간 전 중\n원하는 시간을 선택하세요.',
    ),
    _Slide(
      stepLabel: '04',
      title: '무료 공연도\n바로 확인',
      body:
          '수수료 없이 즐기는 클래식 · 국악\n'
          '무료 공연 정보도 알려드려요.\n\n'
          '지금 바로 시작해 보세요.',
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
      backgroundColor: const Color(0xFF0D2B4E),
      body: Stack(
        children: [
          // 슬라이드
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
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),

          // 하단 영역
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 28,
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
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // 다음 / 시작하기
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLast
                        ? _start
                        : () => _ctrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D2B4E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
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

// ── 데이터 ────────────────────────────────────────────────────────────────────
class _Slide {
  final String stepLabel;
  final String title;
  final String body;
  const _Slide({
    required this.stepLabel,
    required this.title,
    required this.body,
  });
}

// ── 슬라이드 페이지 (이미지/아이콘 없음, 순수 텍스트) ────────────────────────
class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),

            // 단계 번호
            Text(
              slide.stepLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 20),

            // 제목
            Text(
              slide.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 28),

            // 구분선
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // 본문
            Text(
              slide.body,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
