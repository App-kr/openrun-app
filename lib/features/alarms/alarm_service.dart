import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../performances/models/performance.dart';

class AlarmService {
  AlarmService._();
  static final instance = AlarmService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Channel IDs per spec
  static const _urgentChannelId = 'ticket_open_urgent';
  static const _urgentChannelName = '티켓 오픈 긴급 알림';
  static const _generalChannelId = 'new_performance';
  static const _generalChannelName = '새 공연 알림';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Windows/Linux: skip notification plugin init (not fully supported)
    if (Platform.isWindows || Platform.isLinux) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Android notification channels
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _urgentChannelId,
        _urgentChannelName,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ));

      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _generalChannelId,
        _generalChannelName,
        importance: Importance.defaultImportance,
        showBadge: true,
        playSound: false,
      ));
    }
  }

  Future<void> scheduleAlarm(Performance perf, {int minutesBefore = 30}) async {
    if (Platform.isWindows || Platform.isLinux) return;

    await cancelAlarm(perf.id);

    final openTime = tz.TZDateTime.from(perf.ticketOpenAt, tz.local);
    if (openTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final notifyTime = openTime.subtract(Duration(minutes: minutesBefore));
    if (notifyTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final isUrgent = minutesBefore <= 30;

    await _plugin.zonedSchedule(
      _idFrom(perf.id, 'scheduled'),
      isUrgent ? '🎼 $minutesBefore분 후 티켓 오픈!' : '🎼 관심공연이 곧 오픈합니다!',
      '${perf.title} — 관심공연이 곧 오픈합니다!',
      notifyTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isUrgent ? _urgentChannelId : _generalChannelId,
          isUrgent ? _urgentChannelName : _generalChannelName,
          importance: isUrgent ? Importance.max : Importance.defaultImportance,
          priority: isUrgent ? Priority.max : Priority.defaultPriority,
          fullScreenIntent: isUrgent,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: isUrgent,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showImmediateNotification(String title, String body,
      {bool urgent = false}) async {
    if (Platform.isWindows || Platform.isLinux) return;

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          urgent ? _urgentChannelId : _generalChannelId,
          urgent ? _urgentChannelName : _generalChannelName,
          importance: urgent ? Importance.max : Importance.defaultImportance,
          priority: urgent ? Priority.max : Priority.defaultPriority,
          fullScreenIntent: urgent,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: urgent,
        ),
      ),
    );
  }

  Future<void> showAlarmSetConfirmation(Performance perf, int minutesBefore) async {
    final label = minutesBefore >= 1440
        ? '24시간 전'
        : minutesBefore >= 60
            ? '${minutesBefore ~/ 60}시간 전'
            : '$minutesBefore분 전';
    await showImmediateNotification(
      '🎼 알림 설정 완료',
      '${perf.title} — $label 알림이 설정되었습니다',
    );
  }

  Future<void> cancelAlarm(String perfId) async {
    if (Platform.isWindows || Platform.isLinux) return;
    await _plugin.cancel(_idFrom(perfId, 'scheduled'));
  }

  int _idFrom(String perfId, String suffix) =>
      '${perfId}_$suffix'.hashCode.abs() % 100000;
}
