import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/alarms/alarm_service.dart';
import 'secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Background FCM handler — no UI access here
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    await AlarmService.instance.initialize();

    // FCM not supported on Windows/Linux
    if (Platform.isWindows || Platform.isLinux) return;

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    _fcmToken = await messaging.getToken();
    if (_fcmToken != null) {
      await SecureStorageService.write('fcm_token', _fcmToken!);
    }

    messaging.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      await SecureStorageService.write('fcm_token', token);
      // Re-subscribe topics with new token
      await _subscribeStoredTopics();
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Subscribe to region_{city}_{category} topics based on user prefs.
  Future<void> subscribeToTopics() async {
    if (Platform.isWindows || Platform.isLinux) return;
    final prefs = await SharedPreferences.getInstance();
    final cities = prefs.getStringList('selected_cities') ?? [];
    final category = prefs.getString('selected_category') ?? 'all';

    final messaging = FirebaseMessaging.instance;
    for (final city in cities) {
      final topic = 'region_${city}_$category';
      await messaging.subscribeToTopic(topic);
    }
    // Store for re-subscription on token refresh
    await prefs.setStringList(
      'subscribed_topics',
      cities.map((c) => 'region_${c}_$category').toList(),
    );
  }

  Future<void> _subscribeStoredTopics() async {
    if (Platform.isWindows || Platform.isLinux) return;
    final prefs = await SharedPreferences.getInstance();
    final topics = prefs.getStringList('subscribed_topics') ?? [];
    final messaging = FirebaseMessaging.instance;
    for (final topic in topics) {
      await messaging.subscribeToTopic(topic);
    }
  }

  Future<String?> getStoredToken() async {
    return SecureStorageService.read('fcm_token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    final isUrgent = message.data['urgent'] == 'true';
    if (isUrgent) {
      AlarmService.instance.showImmediateNotification(title, body, urgent: true);
    } else {
      AlarmService.instance.showImmediateNotification(title, body, urgent: false);
    }
  }
}
