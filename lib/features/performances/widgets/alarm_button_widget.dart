import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../models/performance.dart';
import '../providers/alarm_provider.dart';
import '../../../shared/services/api_service.dart';

class AlarmButton extends ConsumerWidget {
  final Performance perf;
  const AlarmButton({super.key, required this.perf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmMinutes = ref.watch(alarmProvider(perf.id));
    final hasAlarm = alarmMinutes != null;

    String? alarmLabel;
    if (hasAlarm) {
      if (alarmMinutes >= 1440) alarmLabel = '${alarmMinutes ~/ 1440}일 전';
      else if (alarmMinutes >= 60) alarmLabel = '${alarmMinutes ~/ 60}시간 전';
      else alarmLabel = '$alarmMinutes분 전';
    }

    return Semantics(
      label: hasAlarm ? '알림 $alarmLabel 설정됨. 탭하여 취소' : '알림 설정',
      button: true,
      child: GestureDetector(
        onTap: () => hasAlarm ? _cancel(context, ref) : _showDialog(context, ref),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                size: 13,
                color: hasAlarm ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                hasAlarm ? (alarmLabel ?? '알림 ON') : '알림',
                style: TextStyle(
                  fontSize: 11,
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

  Future<void> _showDialog(BuildContext context, WidgetRef ref) async {
    // 티켓 오픈까지 남은 시간에 따라 옵션 필터링
    final now = DateTime.now();
    final minutesLeft = perf.ticketOpenAt.difference(now).inMinutes;

    final allOptions = [
      (30,   '30분 전'),
      (60,   '1시간 전'),
      (360,  '6시간 전'),
      (720,  '12시간 전'),
      (1440, '24시간 전'),
      (2880, '48시간 전'),
    ];

    // 남은 시간보다 짧은 옵션만 표시 (이미 지난 시점 제외)
    final options = allOptions.where((o) => o.$1 < minutesLeft).toList();
    if (options.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('티켓 오픈 시간이 너무 가까워 알림을 설정할 수 없습니다.')),
        );
      }
      return;
    }

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '알림 시간 선택',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '티켓 오픈 전 알림을 받습니다',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm_rounded, color: AppColors.accent),
                title: Text(
                  opt.$2,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.pop(ctx, opt.$1),
                minLeadingWidth: 28,
                minTileHeight: 44,
              )),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await ref.read(alarmProvider(perf.id).notifier).setAlarm(
      perf, selected,
      ref.read(apiServiceProvider),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('알림이 설정되었습니다 (${alarmLabel(selected)})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String alarmLabel(int minutes) {
    if (minutes >= 1440) return '${minutes ~/ 1440}일 전';
    if (minutes >= 60) return '${minutes ~/ 60}시간 전';
    return '$minutes분 전';
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    await ref.read(alarmProvider(perf.id).notifier).cancel(perf.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림이 취소되었습니다.')),
    );
  }
}
