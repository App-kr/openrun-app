import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/performance.dart';
import '../../alarms/alarm_service.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/notification_service.dart';

part 'alarm_provider.g.dart';

/// Returns minutesBefore if alarm is set, null if not.
@riverpod
class Alarm extends _$Alarm {
  static const _prefix = 'alarm_';

  @override
  int? build(String perfId) {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$perfId');
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = map['minutes_before'] as int?;
      } catch (_) {
        state = null;
      }
    }
  }

  Future<void> setAlarm(Performance perf, int minutesBefore, ApiService api) async {
    state = minutesBefore;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix${perf.id}',
      jsonEncode({'minutes_before': minutesBefore}),
    );

    // Schedule local notification
    await AlarmService.instance.scheduleAlarm(perf, minutesBefore: minutesBefore);

    // POST to backend
    final token = await NotificationService.instance.getStoredToken();
    try {
      await api.setAlarm(
        perfId: perf.id,
        fcmToken: token,
        minutesBefore: minutesBefore,
      );
    } catch (_) {
      // Backend call failed but local alarm is set — acceptable
    }
  }

  Future<void> cancel(String perfId) async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$perfId');
    await AlarmService.instance.cancelAlarm(perfId);
  }
}
