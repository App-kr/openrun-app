import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../models/performance.dart';
import '../providers/alarm_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/utils/genre_icon_provider.dart';
import 'badge_widget.dart';
import 'countdown_timer.dart';

class PerfCard extends ConsumerWidget {
  final Performance perf;

  const PerfCard({super.key, required this.perf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUrgent = perf.isUrgent;

    return Semantics(
      label: '${perf.title}, ${perf.venue}, ${perf.region}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent ? Colors.red.shade200 : AppColors.divider,
            width: isUrgent ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster
                  Semantics(
                    label: '${perf.title} 포스터',
                    image: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: perf.posterUrl != null
                          ? CachedNetworkImage(
                              imageUrl: perf.posterUrl!,
                              width: 70,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _PosterPlaceholder(category: perf.category),
                              errorWidget: (_, __, ___) => _PosterPlaceholder(category: perf.category),
                            )
                          : _PosterPlaceholder(category: perf.category),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perf.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${perf.venue} · ${perf.region}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            if (perf.isHot) const BadgeWidget(type: BadgeType.hot),
                            if (perf.isFree) const BadgeWidget(type: BadgeType.free),
                            if (perf.isNational) const BadgeWidget(type: BadgeType.national),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUrgent ? AppColors.urgentBg : AppColors.background,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  CountdownTimer(
                    openAt: perf.ticketOpenAt,
                    bookingUrl: perf.bookingUrl,
                    onBook: () => _handleBook(context, perf.bookingUrl),
                  ),
                  const Spacer(),
                  _AlarmButton(perf: perf),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBook(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;

    if (!isAllowedBookingUrl(url)) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('지원하지 않는 사이트'),
          content: const Text('이 예매 사이트는 검증된 목록에 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _AlarmButton extends ConsumerWidget {
  final Performance perf;
  const _AlarmButton({required this.perf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmMinutes = ref.watch(alarmProvider(perf.id));
    final hasAlarm = alarmMinutes != null;

    return Semantics(
      label: hasAlarm ? '알림 설정됨 버튼' : '알림 설정 버튼',
      button: true,
      child: GestureDetector(
        onTap: () => hasAlarm
            ? _cancelAlarm(context, ref)
            : _showAlarmDialog(context, ref),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasAlarm ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: hasAlarm ? AppColors.accent : AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasAlarm ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                size: 14,
                color: hasAlarm ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                hasAlarm ? '알림 ON' : '알림',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasAlarm ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAlarmDialog(BuildContext context, WidgetRef ref) async {
    final options = [
      (10, '10분 전'),
      (60, '1시간 전'),
      (1440, '24시간 전'),
    ];

    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '알림 시간 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm_rounded, color: AppColors.accent),
                    title: Text(opt.$2,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    onTap: () => Navigator.pop(ctx, opt.$1),
                    minLeadingWidth: 32,
                    minTileHeight: 48,
                  )),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;
    if (!context.mounted) return;

    final api = ref.read(apiServiceProvider);
    await ref.read(alarmProvider(perf.id).notifier).setAlarm(perf, selected, api);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림이 설정되었습니다.')),
    );
  }

  Future<void> _cancelAlarm(BuildContext context, WidgetRef ref) async {
    await ref.read(alarmProvider(perf.id).notifier).cancel(perf.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림이 취소되었습니다.')),
    );
  }
}

class _PosterPlaceholder extends StatefulWidget {
  final String category;
  const _PosterPlaceholder({required this.category});

  @override
  State<_PosterPlaceholder> createState() => _PosterPlaceholderState();
}

class _PosterPlaceholderState extends State<_PosterPlaceholder> {
  late final String _iconPath;

  @override
  void initState() {
    super.initState();
    _iconPath = GenreIconProvider.instance.nextIcon(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    final isGugak = widget.category == 'gugak';
    final bgColor = isGugak ? AppColors.gugakBg : AppColors.classicBg;
    final fallbackColor = isGugak ? AppColors.gugakText : AppColors.classicText;
    final fallbackIcon = isGugak ? Icons.music_note_rounded : Icons.piano_rounded;

    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Image(
          image: AssetImage(_iconPath),
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            fallbackIcon,
            color: fallbackColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}
