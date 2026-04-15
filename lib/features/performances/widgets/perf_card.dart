import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/performance.dart';
import '../../../shared/utils/genre_icon_provider.dart';
import 'alarm_button_widget.dart';
import 'countdown_timer.dart';

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

// ── Status helpers ─────────────────────────────────────────────────
enum _TicketStatus { open, soonOpen, upcoming }

_TicketStatus _getStatus(DateTime openAt) {
  final now = DateTime.now();
  if (openAt.isBefore(now)) return _TicketStatus.open;
  if (openAt.difference(now).inDays < 7) return _TicketStatus.soonOpen;
  return _TicketStatus.upcoming;
}

class PerfCard extends StatelessWidget {
  final Performance perf;
  final VoidCallback? onTap;

  const PerfCard({super.key, required this.perf, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGugak = perf.category == 'gugak';
    final genreLabel = isGugak ? 'GUGAK' : 'CLASSIC';
    final status = _getStatus(perf.ticketOpenAt);

    return Semantics(
      label: '${perf.title}, ${perf.venue}, ${perf.region}',
      button: onTap != null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main content row ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    _PosterImage(perf: perf),
                    const SizedBox(width: 12),
                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag row
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _TagPill(label: genreLabel, bg: const Color(0xFF185FA5)),
                              _TagPill(label: perf.region, bg: const Color(0xFF4A5568)),
                              _StatusTag(status: status),
                              if (perf.isFree)
                                _TagPill(label: '무료', bg: const Color(0xFF2E7D32)),
                            ],
                          ),
                          const SizedBox(height: 7),
                          // Title
                          Text(
                            _htmlDecode(perf.title),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Meta rows
                          _IconMetaRow(
                            icon: Icons.location_on_outlined,
                            text: perf.venue,
                          ),
                          if (perf.performanceAt != null) ...[
                            _IconMetaRow(
                              icon: Icons.calendar_today_outlined,
                              text: _formatDate(perf.performanceAt!),
                              bold: false,
                            ),
                            _IconMetaRow(
                              icon: Icons.access_time_outlined,
                              text: _formatTime(perf.performanceAt!),
                            ),
                          ],
                          _PriceRow(perf: perf),
                        ],
                      ),
                    ),
                  ],
                ),
                // ── Divider ───────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                // ── Bottom bar ────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CountdownTimer(
                        openAt: perf.ticketOpenAt,
                        bookingUrl: perf.bookingUrl,
                        showBookButton: false,
                      ),
                    ),
                    AlarmButton(perf: perf),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

// ── Tag pill ──────────────────────────────────────────────────────
class _TagPill extends StatelessWidget {
  final String label;
  final Color bg;
  const _TagPill({required this.label, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Status tag ────────────────────────────────────────────────────
class _StatusTag extends StatelessWidget {
  final _TicketStatus status;
  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final String label;
    switch (status) {
      case _TicketStatus.open:
        bg = const Color(0xFFD32F2F);
        label = '오픈중';
      case _TicketStatus.soonOpen:
        bg = const Color(0xFFF57C00);
        label = '예매대기';
      case _TicketStatus.upcoming:
        bg = const Color(0xFF90A4AE);
        label = '공연예정';
    }
    return _TagPill(label: label, bg: bg);
  }
}

// ── Icon + text meta row ──────────────────────────────────────────
class _IconMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  const _IconMetaRow({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price badge ───────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final Performance perf;
  const _PriceRow({required this.perf});

  @override
  Widget build(BuildContext context) {
    final bool free = perf.isFree;
    final Color bgColor = free
        ? const Color(0xFFE3F0FF)  // 연한 파란색
        : const Color(0xFFFFECEC); // 연한 붉은색
    final Color textColor = free
        ? const Color(0xFF1565C0)
        : const Color(0xFFB71C1C);

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          free ? '무료' : '유료',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ── Poster image ──────────────────────────────────────────────────
class _PosterImage extends StatefulWidget {
  final Performance perf;
  const _PosterImage({required this.perf});

  @override
  State<_PosterImage> createState() => _PosterImageState();
}

class _PosterImageState extends State<_PosterImage> {
  late final String _iconPath;

  @override
  void initState() {
    super.initState();
    _iconPath = GenreIconProvider.instance.nextIcon(widget.perf.category);
  }

  @override
  Widget build(BuildContext context) {
    final isGugak = widget.perf.category == 'gugak';
    final bgColor = isGugak ? AppColors.gugakBg : AppColors.classicBg;
    final fallbackColor = isGugak ? AppColors.gugakText : AppColors.classicText;
    final fallbackIcon = isGugak ? Icons.music_note_rounded : Icons.piano_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: widget.perf.posterUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.perf.posterUrl!,
              width: 80,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(bgColor, fallbackIcon, fallbackColor),
              errorWidget: (_, __, ___) => _placeholder(bgColor, fallbackIcon, fallbackColor),
            )
          : _placeholder(bgColor, fallbackIcon, fallbackColor),
    );
  }

  Widget _placeholder(Color bg, IconData icon, Color iconColor) {
    return Container(
      width: 80,
      height: 120,
      color: bg,
      child: Center(
        child: Image(
          image: AssetImage(_iconPath),
          width: 44,
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}
