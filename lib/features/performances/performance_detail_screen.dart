import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../shared/utils/html_utils.dart';
import 'models/performance.dart';

// ── Official English venue names (verified, DB-matched) ───────────
String _venueEn(String venue) {
  const map = {
    '롯데콘서트홀': 'Lotte Concert Hall',
    '예술의전당': 'Seoul Arts Center',
    '예술의전당 콘서트홀': 'Seoul Arts Center, Concert Hall',
    '예술의전당 오페라극장': 'Seoul Arts Center, Opera Theater',
    '예술의전당 리사이틀홀': 'Seoul Arts Center, Recital Hall',
    '예술의전당 IBK챔버홀': 'Seoul Arts Center, IBK Chamber Hall',
    '세종문화회관': 'Sejong Center for the Performing Arts',
    '서울 세종문화회관': 'Sejong Center for the Performing Arts',
    '세종문화회관 대극장': 'Sejong Center, Grand Theater',
    '세종문화회관 체임버홀': 'Sejong Center, Chamber Hall',
    '국립국악원 예악당': 'National Gugak Center, Yeak Hall',
    '국립국악원 우면당': 'National Gugak Center, Umyeon Hall',
    'KBS홀': 'KBS Hall',
    '부산문화회관 대극장': 'Busan Cultural Center, Grand Theater',
    '부산문화회관 중극장': 'Busan Cultural Center, Medium Theater',
    '부산문화회관 챔버홀': 'Busan Cultural Center, Chamber Hall',
    '부산시민회관 대극장': 'Busan Citizen Hall, Grand Theater',
    '국립부산국악원 연악당': 'National Gugak Center Busan, Yeonak Hall',
    '국립부산국악원': 'National Gugak Center Busan',
    '대구콘서트하우스 그랜드홀': 'Daegu Concert House, Grand Hall',
    '대구콘서트하우스 챔버홀': 'Daegu Concert House, Chamber Hall',
    '대구오페라하우스': 'Daegu Opera House',
    '인천문화예술회관': 'Incheon Culture & Arts Center',
    '인천문화예술회관 대공연장': 'Incheon Culture & Arts Center, Grand Hall',
    '광주문화예술회관': 'Gwangju Culture & Arts Center',
    '광주문화예술회관 대극장': 'Gwangju Culture & Arts Center, Grand Theater',
    '대전예술의전당': 'Daejeon Arts Center',
    '대전예술의전당 아트홀': 'Daejeon Arts Center, Art Hall',
    '통영국제음악당 콘서트홀': 'Tongyeong Concert Hall',
    '창원성산아트홀': 'Changwon Seongsan Art Hall',
  };
  return map[venue] ?? venue;
}

// ── 공연장별 공식 티켓팅 페이지 (항상 유효한 목록/예매 페이지) ────────
String _venueHomeUrl(String v) {
  // 서울
  if (v.contains('서울시향') || v.contains('서울필하모닉') || v.contains('서울 필하모닉')) {
    return 'https://www.seoulphil.or.kr/perf/list';
  }
  if (v.contains('롯데콘서트홀')) {
    return 'https://www.lotteconcerthall.com/performance/list';
  }
  if (v.contains('예술의전당')) {
    return 'https://www.sacticket.co.kr/SacFront/index.do';
  }
  if (v.contains('세종문화회관')) {
    return 'https://www.sejong.or.kr/ticketing/present.jsp';
  }
  if (v.contains('KBS홀') || v.contains('KBS 홀')) {
    return 'https://www.kbssym.or.kr/concert/upcoming.jsp';
  }
  if (v.contains('국립오페라단')) {
    return 'https://www.nationalopera.or.kr/';
  }
  if (v.contains('충무아트센터')) {
    return 'https://www.chungmuartcenter.or.kr/';
  }
  // 국립
  if (v.contains('국립부산국악원')) {
    return 'https://www.gugakbs.go.kr/perform/perform_list.do';
  }
  if (v.contains('국립국악원')) {
    return 'https://www.gugak.go.kr/site/main/perform/perform01/list';
  }
  if (v.contains('국립극장')) {
    return 'https://www.nationaltheater.or.kr/cms/main/reserve/ReserveList.do';
  }
  // 부산
  if (v.contains('부산') && v.contains('국악')) {
    return 'https://www.gugakbs.go.kr/perform/perform_list.do';
  }
  if (v.contains('부산문화회관')) {
    return 'https://www.bscc.or.kr/01_perfor/?mcode=0401010200';
  }
  if (v.contains('부산시민회관')) {
    return 'https://www.bscf.or.kr/';
  }
  // 대구
  if (v.contains('대구콘서트하우스')) {
    return 'https://www.daeguconcethouse.or.kr/reservation/performance_view.asp';
  }
  if (v.contains('대구오페라하우스')) {
    return 'https://www.daeguoperahouse.org/';
  }
  // 인천·광주·대전
  if (v.contains('인천문화예술회관')) {
    return 'https://www.artincheon.org/';
  }
  if (v.contains('광주문화예술회관')) {
    return 'https://gcf.or.kr/';
  }
  if (v.contains('대전예술의전당')) {
    return 'https://www.daejeonarts.or.kr/';
  }
  // 경남
  if (v.contains('통영국제음악당')) {
    return 'https://www.timf.org/';
  }
  if (v.contains('창원성산아트홀')) {
    return 'https://www.changwonart.or.kr/';
  }
  return '';
}

/// 실제 예매 버튼에 사용할 URL 결정 로직
/// - 티켓 오픈 중: 직접 예매 링크(bookingUrl) 사용
/// - 티켓 미오픈: 공연장 예매 목록 페이지 (404 방지)
/// - 둘 다 없으면 빈 문자열
String _effectiveBookingUrl(Performance perf) {
  final now = DateTime.now();
  final isOpen = perf.ticketOpenAt.isBefore(now);

  if (isOpen) {
    // 오픈 중 → 직접 예매 URL 우선
    final bookingUrl = perf.bookingUrl;
    if (bookingUrl != null && bookingUrl.isNotEmpty) {
      return bookingUrl;
    }
  }

  // 미오픈 또는 URL 없음 → 공연장 공식 예매 페이지 (항상 유효)
  final venueUrl = _venueHomeUrl(perf.venue);
  if (venueUrl.isNotEmpty) return venueUrl;

  // 최후 수단: bookingUrl이라도 반환
  return perf.bookingUrl ?? '';
}

// ── 자동 프로그램 설명 생성 ────────────────────────────────────────
/// programInfo가 null일 때 타이틀·공연장·장르·가격·시간으로 자동 생성.
/// 서버에서 program_info가 채워지면 이 함수 결과 대신 서버값이 표시된다.
String _buildAutoInfo(Performance perf) {
  final buf = StringBuffer();
  final t = perf.title;
  final tLow = t.toLowerCase();
  // venue 잘못된 값 보정 (스크래핑 오류: "1:1문의하기" 등)
  final v = (perf.venue.contains('문의') || perf.venue.length < 2) ? '공연장' : perf.venue;
  final isGugak = perf.category == 'gugak';

  // ── 작곡가 추출 ────────────────────────────────────────────────────
  const composerMap = {
    '차이코프스키': '차이코프스키', '베토벤': '베토벤', '모차르트': '모차르트',
    '브람스': '브람스', '말러': '말러', '쇼팽': '쇼팽', '슈베르트': '슈베르트',
    '슈만': '슈만', '드보르작': '드보르작', '시벨리우스': '시벨리우스',
    '라흐마니노프': '라흐마니노프', '프로코피예프': '프로코피예프',
    '바흐': '바흐', '헨델': '헨델', '비발디': '비발디', '하이든': '하이든',
    '리스트': '리스트', '생상스': '생상스', '드뷔시': '드뷔시', '라벨': '라벨',
  };
  final composers = composerMap.entries
      .where((e) => t.contains(e.key))
      .map((e) => e.value)
      .toList();

  // ── 1) 공연 종류 감지 ─────────────────────────────────────────────
  // 국악 상설공연
  if (t.contains('토요명품')) {
    buf.writeln('국립국악원의 토요명품공연은 매주 토요일 열리는 대표 국악 상설공연입니다.');
    buf.writeln('판소리·민속무용·기악 등 다양한 전통 국악 장르를 한 무대에서 감상할 수 있습니다.');
  } else if (t.contains('정오의 음악회') || t.contains('정오의음악회')) {
    buf.writeln('국립국악원 정오의 음악회는 점심시간에 즐기는 국악 상설공연입니다.');
    buf.writeln('국악관현악·실내악·성악 등 다채로운 프로그램으로 구성됩니다.');
  } else if (t.contains('수요공감')) {
    buf.writeln('국립국악원 수요공감은 매주 수요일 열리는 국악 상설공연입니다.');
    buf.writeln('젊은 국악인들의 창의적인 무대를 가까이서 만날 수 있습니다.');
  } else if (t.contains('민속공연') || t.contains('민속무대')) {
    buf.writeln('$v에서 열리는 전통 민속공연입니다.');
    buf.writeln('우리 민족 고유의 민속 예술을 선보이는 상설 프로그램입니다.');
  // 교향악
  } else if ((t.contains('교향') || t.contains('심포니') || t.contains('Symphony')) &&
      (t.contains('오케스트라') || t.contains('Orchestra') || t.contains('필하모닉'))) {
    final compStr = composers.isNotEmpty ? ' ${composers.take(2).join(', ')}의 작품을 중심으로' : '';
    buf.writeln('$v에서 열리는$compStr 오케스트라 교향악 공연입니다.');
  } else if (t.contains('교향') || t.contains('심포니') || t.contains('Symphony')) {
    final compStr = composers.isNotEmpty ? ' ${composers.first}의' : '';
    buf.writeln('$v에서 열리는$compStr 교향악 공연입니다.');
  // 오페라
  } else if (t.contains('오페라') || t.contains('Opera')) {
    buf.writeln('$v에서 열리는 오페라 공연입니다.');
    if (t.contains('갈라') || t.contains('하이라이트')) {
      buf.writeln('여러 오페라의 하이라이트를 모아 선보이는 갈라 공연입니다.');
    }
  // 발레
  } else if (t.contains('발레') || t.contains('Ballet')) {
    buf.writeln('$v에서 열리는 발레 공연입니다.');
    if (composers.isNotEmpty) {
      buf.writeln('${composers.first}의 음악에 맞춘 발레 작품입니다.');
    }
  // 독주회
  } else if (t.contains('리사이틀') || t.contains('독주회') || t.contains('Recital')) {
    final instr = _extractInstrument(t);
    final compStr = composers.isNotEmpty ? ' ${composers.take(2).join(', ')}의 작품을 포함한' : '';
    buf.writeln('$v에서 열리는${instr.isNotEmpty ? ' $instr' : ''}$compStr 독주회입니다.');
  // 협주곡
  } else if (t.contains('협주') || t.contains('컨체르토') || t.contains('Concerto')) {
    final compStr = composers.isNotEmpty ? ' ${composers.first}의' : '';
    buf.writeln('$v에서 열리는$compStr 협주곡 공연입니다.');
  // 실내악/앙상블
  } else if (t.contains('실내악') || t.contains('챔버') || t.contains('Chamber') ||
      t.contains('앙상블') || t.contains('Ensemble') ||
      t.contains('Quartet') || t.contains('Trio') || t.contains('Quintet')) {
    buf.writeln('$v에서 열리는 실내악 공연입니다.');
    if (composers.isNotEmpty) {
      buf.writeln('${composers.take(2).join(', ')}의 작품으로 구성됩니다.');
    }
  // 합창
  } else if (t.contains('합창') || t.contains('Chorus') || t.contains('Choir')) {
    buf.writeln('$v에서 열리는 합창 공연입니다.');
  // 듀오
  } else if (t.contains('듀오') || t.contains('Duo') || t.contains('이중주')) {
    buf.writeln('$v에서 열리는 듀오 연주회입니다.');
  // 국악 — 판소리
  } else if (t.contains('판소리')) {
    buf.writeln('한국 전통 성악 예술인 판소리 공연입니다. $v에서 만나볼 수 있습니다.');
  } else if (t.contains('가야금')) {
    buf.writeln('가야금으로 연주하는 국악 공연입니다. $v에서 열립니다.');
  } else if (t.contains('해금')) {
    buf.writeln('해금의 섬세하고 풍부한 음색을 감상할 수 있는 국악 공연입니다.');
  } else if (t.contains('대금')) {
    buf.writeln('한국 전통 관악기 대금의 깊은 울림을 감상하는 국악 공연입니다.');
  } else if (t.contains('병창')) {
    buf.writeln('악기 연주와 노래를 함께 선보이는 병창 공연입니다.');
  } else if (t.contains('아쟁') || t.contains('거문고') || t.contains('피리') ||
      t.contains('소리') || t.contains('민요') || t.contains('장구')) {
    buf.writeln('$v에서 열리는 국악 기악 공연입니다.');
  } else if (t.contains('무용') || t.contains('춤') || t.contains('무악')) {
    buf.writeln('$v에서 열리는 ${isGugak ? '전통 ' : ''}무용 공연입니다.');
  // K-POP / 애니 크로스오버
  } else if (tLow.contains('k-pop') || tLow.contains('kpop') || tLow.contains('케이팝') ||
      tLow.contains('애니') || tLow.contains('anime') || tLow.contains('j-pop')) {
    buf.writeln('$v에서 열리는 팝 & 애니메이션 심포닉 콘서트입니다.');
    buf.writeln('인기 K-POP·애니메이션 음악을 오케스트라 편곡으로 감상하는 특별 공연입니다.');
  } else if ((tLow.contains('심포닉') || tLow.contains('symphonic')) &&
      (tLow.contains('pop') || tLow.contains('팝') || tLow.contains('게임') || tLow.contains('영화'))) {
    buf.writeln('$v에서 열리는 심포닉 크로스오버 콘서트입니다.');
    buf.writeln('영화·게임·팝 음악을 오케스트라 사운드로 새롭게 해석한 공연입니다.');
  // 정기공연
  } else if (t.contains('정기연주회') || t.contains('정기공연') || t.contains('정기연주')) {
    final genre = isGugak ? '국악' : '클래식';
    final numMatch = RegExp(r'제\s*(\d+)\s*회').firstMatch(t);
    final numStr = numMatch != null ? ' 제${numMatch.group(1)}회' : '';
    buf.writeln('$v 소속 단체의$numStr $genre 정기공연입니다.');
  } else if (t.contains('특별') || t.contains('기획') || t.contains('페스티벌') ||
      t.contains('Festival') || t.contains('갈라') || t.contains('Gala')) {
    final genre = isGugak ? '국악' : '클래식';
    buf.writeln('$v에서 열리는 특별 기획 $genre 공연입니다.');
  } else {
    final genre = isGugak ? '국악' : '클래식';
    final compStr = composers.isNotEmpty ? ' ${composers.take(2).join(', ')}의 작품을 중심으로' : '';
    buf.writeln('$v에서 열리는$compStr $genre 공연입니다.');
  }

  // ── 2) 작곡가 정보 보완 ────────────────────────────────────────────
  if (composers.isNotEmpty) {
    final firstLine = buf.toString();
    if (!composers.any((c) => firstLine.contains(c))) {
      buf.writeln('${composers.take(2).join(', ')}의 작품을 프로그램으로 구성합니다.');
    }
  }

  // ── 3) 공연 특성 태그 ──────────────────────────────────────────────
  if (perf.isFree) buf.writeln('무료 입장 가능한 공연입니다.');
  if (perf.isNational) buf.writeln('국공립 기관이 주최하는 공연입니다.');
  if (t.contains('앙코르') || t.contains('Encore')) {
    buf.writeln('인기 앙코르 프로그램으로 구성된 공연입니다.');
  }
  if (t.contains('신년') || t.contains('새해')) {
    buf.writeln('새해를 맞아 특별히 기획된 공연입니다.');
  }
  final annMatch = RegExp(r'(\d+)\s*주년').firstMatch(t);
  if (annMatch != null) {
    buf.writeln('창단/개관 ${annMatch.group(1)}주년을 기념하는 특별 공연입니다.');
  } else if (t.contains('기념')) {
    buf.writeln('기념 특별 공연입니다.');
  }

  // ── 4) 공연 정보 요약 ──────────────────────────────────────────────
  final info = <String>[];
  if (perf.runningTime != null) info.add('공연시간 ${perf.runningTime}');
  if (perf.ageLimit != null) info.add('${perf.ageLimit} 관람 가능');
  if (perf.priceInfo != null && !perf.isFree) info.add('입장료 ${perf.priceInfo}');
  if (info.isNotEmpty) buf.writeln(info.join(' · '));

  buf.write('상세 프로그램은 예매 페이지에서 확인하세요.');
  return buf.toString().trim();
}

String _extractInstrument(String title) {
  const map = {
    '피아노': '피아노', '바이올린': '바이올린', '첼로': '첼로', '플루트': '플루트',
    '오보에': '오보에', '클라리넷': '클라리넷', '하프': '하프', '기타': '기타',
    '성악': '성악', '소프라노': '소프라노', '테너': '테너', '바리톤': '바리톤',
    'Piano': '피아노', 'Violin': '바이올린', 'Cello': '첼로',
  };
  for (final entry in map.entries) {
    if (title.contains(entry.key)) {
      return entry.value;
    }
  }
  return '';
}

// ── Color constants ────────────────────────────────────────────────
const _colorFree = Color(0xFF185FA5);
const _colorPaid = Color(0xFF9B1C1C);
const _tagBg = Color(0xFF185FA5);

class PerformanceDetailScreen extends ConsumerWidget {
  final Performance perf;
  const PerformanceDetailScreen({super.key, required this.perf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = htmlDecode(perf.title);
    final isGugak = perf.category == 'gugak';
    final genreBgColor = isGugak ? AppColors.gugakBg : AppColors.classicBg;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: const BackButton(color: AppColors.textPrimary),
        titleSpacing: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PosterSection(perf: perf, genreBgColor: genreBgColor),
            _InfoSection(perf: perf),
            const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
            _EnglishSection(perf: perf),
            const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
            _InfoProgramSection(perf: perf),
            _BookingSection(perf: perf),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Poster
// ─────────────────────────────────────────────────────────────────────────────
class _PosterSection extends StatelessWidget {
  final Performance perf;
  final Color genreBgColor;
  const _PosterSection({required this.perf, required this.genreBgColor});

  @override
  Widget build(BuildContext context) {
    if (perf.posterUrl != null) {
      return CachedNetworkImage(
        imageUrl: perf.posterUrl!,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final isGugak = perf.category == 'gugak';
    final iconPath = isGugak
        ? 'assets/icons/gugak/janggu.png'
        : 'assets/icons/classic/violin.png';
    return Container(
      width: double.infinity,
      height: 200,
      color: genreBgColor,
      child: Center(
        child: Image.asset(
          iconPath, width: 80, height: 80, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            isGugak ? Icons.music_note : Icons.piano,
            size: 64,
            color: isGugak ? AppColors.gugakBorder : AppColors.classicBorder,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Korean info rows
// ─────────────────────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final Performance perf;
  const _InfoSection({required this.perf});

  @override
  Widget build(BuildContext context) {
    final dateStr = perf.performanceAt != null ? _formatDate(perf.performanceAt!) : null;
    final timeStr = perf.performanceAt != null ? _formatTime(perf.performanceAt!) : null;
    final admissionColor = perf.isFree ? _colorFree : _colorPaid;
    final admissionText = perf.isFree ? '무료' : (perf.priceInfo ?? '유료');

    final rows = <_KRow>[
      if (dateStr != null) _KRow('공연일자', dateStr, bold: true, fontSize: 17),
      if (timeStr != null) _KRow('시작시간', timeStr),
      _KRow('공연장소', '${perf.region} ${perf.venue}', bold: true),
      if (perf.runningTime != null) _KRow('공연시간', perf.runningTime!),
      _KRow('입장료', admissionText, bold: true, valueColor: admissionColor,
            multiLine: perf.priceInfo != null && !perf.isFree),
      if (perf.ageLimit != null) _KRow('관람연령', perf.ageLimit!),
    ];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 0.5, thickness: 0.5, indent: 16, endIndent: 16,
                  color: Color(0xFFEEEEEE)),
            _InfoRow(row: rows[i]),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final local = dt.toLocal();
    final wd = weekdays[local.weekday - 1];
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} ($wd)';
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? '오전' : '오후';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$ampm $h12:$m';
  }
}

class _KRow {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final bool multiLine;
  final double fontSize;
  const _KRow(this.label, this.value,
      {this.bold = false, this.valueColor, this.multiLine = false, this.fontSize = 16});
}

class _InfoRow extends StatelessWidget {
  final _KRow row;
  const _InfoRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: row.fontSize,
      color: row.valueColor ?? const Color(0xFF111111),
      fontWeight: row.bold ? FontWeight.bold : FontWeight.normal,
      height: 1.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              row.label,
              style: TextStyle(
                fontSize: row.fontSize,
                color: const Color(0xFF999999),
              ),
            ),
          ),
          Expanded(child: Text(row.value, style: valueStyle)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// English section
// ─────────────────────────────────────────────────────────────────────────────
class _EnglishSection extends StatelessWidget {
  final Performance perf;
  const _EnglishSection({required this.perf});

  @override
  Widget build(BuildContext context) {
    final dateStr = perf.performanceAt != null ? _formatDateEn(perf.performanceAt!) : null;
    final timeStr = perf.performanceAt != null ? _formatTimeEn(perf.performanceAt!) : null;
    final admissionText = perf.isFree ? 'Free' : (perf.priceInfo ?? 'Paid · Check Website');
    final admissionColor = perf.isFree ? _colorFree : _colorPaid;

    final rows = <_KRow>[
      if (dateStr != null) _KRow('Date', dateStr),
      if (timeStr != null) _KRow('Time', timeStr),
      _KRow('Venue', _venueEn(perf.venue), bold: true),
      if (perf.runningTime != null) _KRow('Duration', perf.runningTime!),
      _KRow('Admission', admissionText, bold: true, valueColor: admissionColor,
            multiLine: perf.priceInfo != null && !perf.isFree),
      if (perf.ageLimit != null) _KRow('Age', perf.ageLimit!),
    ];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'ENGLISH',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999), letterSpacing: 2.0),
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 0.5, thickness: 0.5, indent: 16, endIndent: 16,
                  color: Color(0xFFEEEEEE)),
            _InfoRow(row: rows[i]),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static String _formatDateEn(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final local = dt.toLocal();
    return '${weekdays[local.weekday - 1]}, ${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String _formatTimeEn(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $ampm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO / Program section
// ─────────────────────────────────────────────────────────────────────────────
class _InfoProgramSection extends StatelessWidget {
  final Performance perf;
  const _InfoProgramSection({required this.perf});

  @override
  Widget build(BuildContext context) {
    // 서버에서 온 program_info 우선 — 없으면 자동 생성
    final hasServerInfo = perf.programInfo != null && perf.programInfo!.isNotEmpty;
    final displayText = hasServerInfo
        ? perf.programInfo!
        : _buildAutoInfo(perf);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'INFO',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                  letterSpacing: 2.0,
                ),
              ),
              if (!hasServerInfo) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '자동',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayText,
            style: TextStyle(
              fontSize: hasServerInfo ? 16 : 15,
              color: hasServerInfo
                  ? const Color(0xFF111111)
                  : const Color(0xFF444444),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking buttons
// ─────────────────────────────────────────────────────────────────────────────
class _BookingSection extends StatelessWidget {
  final Performance perf;
  const _BookingSection({required this.perf});

  @override
  Widget build(BuildContext context) {
    final url = _effectiveBookingUrl(perf);
    final isOpen = perf.ticketOpenAt.isBefore(DateTime.now());

    // 버튼 텍스트: 오픈 중이면 "예매하기", 미오픈이면 "공식 예매 사이트"
    final koLabel = isOpen ? '예매하기' : '공식 예매 사이트 보기';
    final enLabel = isOpen ? 'Book Tickets' : 'Visit Official Site';
    final notice = isOpen
        ? '예매하기를 누르면 공식사이트로 연결됩니다\nTap "Book" to visit the official site'
        : '티켓 오픈 전입니다. 공식사이트에서 일정을 확인하세요.\nTickets not open yet — check the official site for schedule.';

    if (url.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Text(
          '예매 링크 준비 중입니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _launch(context, url),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tagBg,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              child: Text(koLabel),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _launch(context, url),
              style: OutlinedButton.styleFrom(
                foregroundColor: _tagBg,
                side: const BorderSide(color: _tagBg, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              child: Text(enLabel),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            notice,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.6),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('예매 페이지를 열 수 없습니다.')),
        );
      }
    }
  }
}
