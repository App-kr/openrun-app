import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../performances/models/performance.dart';

/// 알림음 모드
/// - auto    : 공연 장르에 따라 자동 선택 (기본값)
/// - gugak   : 항상 국악 알림음
/// - classic : 항상 클래식 알림음
/// - default : 시스템 기본 알림음
/// - silent  : 무음
class AlarmService {
  AlarmService._();
  static final instance = AlarmService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── 채널 ID ────────────────────────────────────────────────
  static const _gugakChannelId   = 'ticket_open_gugak';
  static const _gugakChannelName = '국악 티켓 오픈 알림';
  static const _classicChannelId   = 'ticket_open_classic';
  static const _classicChannelName = '클래식 티켓 오픈 알림';
  static const _defaultChannelId   = 'ticket_open_default';
  static const _defaultChannelName = '티켓 오픈 알림';
  static const _silentChannelId   = 'ticket_open_silent';
  static const _silentChannelName = '티켓 오픈 알림 (무음)';

  /// SharedPreferences 키
  static const soundPrefKey = 'notification_sound_mode';

  // ── 초기화 ─────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    if (Platform.isWindows || Platform.isLinux) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // 국악 채널 — res/raw/gugak_sound.mp3 사용 (없으면 기본음 폴백)
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _gugakChannelId,
        _gugakChannelName,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('gugak_sound'),
        enableVibration: true,
        enableLights: true,
      ));

      // 클래식 채널 — res/raw/classic_sound.mp3 사용
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _classicChannelId,
        _classicChannelName,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('classic_sound'),
        enableVibration: true,
        enableLights: true,
      ));

      // 기본 채널 — 시스템 기본 알림음
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _defaultChannelId,
        _defaultChannelName,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ));

      // 무음 채널
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _silentChannelId,
        _silentChannelName,
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
      ));
    }
  }

  // ── 음원 설정 읽기 ──────────────────────────────────────────
  Future<String> getSoundMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(soundPrefKey) ?? 'auto';
  }

  Future<void> setSoundMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(soundPrefKey, mode);
  }

  // ── 채널 선택 헬퍼 ─────────────────────────────────────────
  String _channelId(String category, String soundMode) => switch (soundMode) {
    'silent'  => _silentChannelId,
    'gugak'   => _gugakChannelId,
    'classic' => _classicChannelId,
    'default' => _defaultChannelId,
    _         => category == 'gugak' ? _gugakChannelId : _classicChannelId,
  };

  String _channelName(String category, String soundMode) => switch (soundMode) {
    'silent'  => _silentChannelName,
    'gugak'   => _gugakChannelName,
    'classic' => _classicChannelName,
    'default' => _defaultChannelName,
    _         => category == 'gugak' ? _gugakChannelName : _classicChannelName,
  };

  /// iOS 알림음 파일명 — res/raw와 동일한 파일을 ios/Runner/에 복사해야 함
  String? _iosSound(String category, String soundMode) => switch (soundMode) {
    'silent'  => null,
    'default' => null,
    'gugak'   => 'gugak_sound.mp3',
    'classic' => 'classic_sound.mp3',
    _         => category == 'gugak' ? 'gugak_sound.mp3' : 'classic_sound.mp3',
  };

  // ── 시간 포맷 ───────────────────────────────────────────────
  String _formatBefore(int minutes) {
    if (minutes >= 1440) return '${minutes ~/ 1440}일';
    if (minutes >= 60)   return '${minutes ~/ 60}시간';
    return '$minutes분';
  }

  // ── 예약 알림 ───────────────────────────────────────────────
  Future<void> scheduleAlarm(Performance perf, {int minutesBefore = 60}) async {
    if (Platform.isWindows || Platform.isLinux) return;

    await cancelAlarm(perf.id);

    final openTime = tz.TZDateTime.from(perf.ticketOpenAt, tz.local);
    if (openTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final notifyTime = openTime.subtract(Duration(minutes: minutesBefore));
    if (notifyTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final soundMode = await getSoundMode();
    final chId   = _channelId(perf.category, soundMode);
    final chName = _channelName(perf.category, soundMode);
    final iSound = _iosSound(perf.category, soundMode);
    final beforeLabel = _formatBefore(minutesBefore);
    final isSilent = soundMode == 'silent';

    await _plugin.zonedSchedule(
      _idFrom(perf.id, 'scheduled'),
      '🎼 $beforeLabel 후 티켓 오픈!',
      '${perf.title} — $beforeLabel 후 예매가 시작됩니다',
      notifyTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chId, chName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: minutesBefore <= 60,
          playSound: !isSilent,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
          sound: iSound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── 즉시 알림 ───────────────────────────────────────────────
  Future<void> showImmediateNotification(
    String title,
    String body, {
    bool urgent = false,
    String category = 'classic',
  }) async {
    if (Platform.isWindows || Platform.isLinux) return;

    final soundMode = urgent ? await getSoundMode() : 'silent';
    final chId   = _channelId(category, soundMode);
    final chName = _channelName(category, soundMode);
    final iSound = _iosSound(category, soundMode);
    final isSilent = soundMode == 'silent';

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chId, chName,
          importance: urgent ? Importance.max : Importance.defaultImportance,
          priority: urgent ? Priority.max : Priority.defaultPriority,
          fullScreenIntent: urgent,
          playSound: !isSilent,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
          sound: iSound,
        ),
      ),
    );
  }

  // ── 알람 설정 확인 토스트 알림 ─────────────────────────────
  Future<void> showAlarmSetConfirmation(Performance perf, int minutesBefore) async {
    final label = '${_formatBefore(minutesBefore)} 전';
    await showImmediateNotification(
      '🎼 알림 설정 완료',
      '${perf.title} — $label 알림이 설정되었습니다',
      urgent: false,
      category: perf.category,
    );
  }

  // ── 취소 ────────────────────────────────────────────────────
  Future<void> cancelAlarm(String perfId) async {
    if (Platform.isWindows || Platform.isLinux) return;
    await _plugin.cancel(_idFrom(perfId, 'scheduled'));
  }

  int _idFrom(String perfId, String suffix) =>
      '${perfId}_$suffix'.hashCode.abs() % 100000;
}
