import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import 'models/performance.dart';

// ── HTML entity decoder ────────────────────────────────────────────
String _htmlDecode(String text) => text
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#x27;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&#34;', '"')
    .replaceAll('&nbsp;', ' ');

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

// ── Fallback booking URL ───────────────────────────────────────────
String _fallbackBookingUrl(Performance perf) {
  final v = perf.venue;
  if (v.contains('서울시향') || v.contains('서울필하모닉')) return 'https://www.seoulphil.or.kr/perf/list';
  if (v.contains('부산문화회관') || v.contains('부산시민회관')) return 'https://www.bscc.or.kr/01_perfor/?mcode=0401010200';
  if (v.contains('국립부산국악원')) return 'https://www.gugakbs.go.kr';
  if (v.contains('국립국악원')) return 'https://www.gugak.go.kr';
  if (v.contains('인천문화예술회관')) return 'https://www.artincheon.org';
  if (v.contains('광주문화예술회관')) return 'https://gcf.or.kr';
  if (v.contains('대전예술의전당')) return 'https://www.daejeonarts.or.kr';
  return '';
}

String _effectiveBookingUrl(Performance perf) {
  if (perf.bookingUrl != null && perf.bookingUrl!.isNotEmpty) return perf.bookingUrl!;
  return _fallbackBookingUrl(perf);
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
    final title = _htmlDecode(perf.title);
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
            _InfoProgramSection(programInfo: perf.programInfo),
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
  final String? programInfo;
  const _InfoProgramSection({required this.programInfo});

  @override
  Widget build(BuildContext context) {
    final hasInfo = programInfo != null && programInfo!.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFO',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          if (hasInfo)
            Text(
              programInfo!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF111111),
                height: 1.6,
              ),
            )
          else
            const Text(
              '프로그램 정보를 준비 중입니다.\n예매 페이지에서 상세 내용을 확인하세요.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF999999),
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
              child: const Text('예매하기'),
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
              child: const Text('Book Tickets'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '예매하기를 누르면 공식사이트로 연결됩니다\nTap "Book" to visit the official site',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.6),
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
