import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../performances/providers/performances_provider.dart';
import '../performances/widgets/perf_card.dart';

class AlarmListScreen extends ConsumerWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPerfsAsync = ref.watch(performancesProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('내 알림')),
      body: allPerfsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (result) {
          final perfs = result.$1;
          // Filter only alarms that user has set
          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final prefs = snap.data!;
              final alarmed = perfs.where((p) => prefs.getBool('alarm_${p.id}') == true).toList();

              if (alarmed.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 52, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text('설정된 알림이 없습니다.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      SizedBox(height: 6),
                      Text('공연 목록에서 🔔 버튼을 눌러 알림을 설정하세요.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: alarmed.length,
                itemBuilder: (_, i) => PerfCard(perf: alarmed[i]),
              );
            },
          );
        },
      ),
    );
  }
}
