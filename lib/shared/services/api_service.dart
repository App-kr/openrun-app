import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/performances/models/performance.dart';
import 'cache_service.dart';
import '../../main.dart';

part 'api_service.g.dart';

@riverpod
ApiService apiService(ApiServiceRef ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ApiService(cache);
}

// Booking URL whitelist — security
const allowedBookingDomains = {
  'bscc.or.kr',
  'seoulphil.or.kr',
  'gugak.go.kr',
  'gugakbs.go.kr',
  'timf.org',
  'daeguconcethouse.or.kr',
  'nationalopera.or.kr',
  'gcf.or.kr',
  'artincheon.org',
  'gjart.kr',
  'daejeonarts.or.kr',
  // legacy
  'classicbusan.busan.go.kr',
  'kbssym.or.kr',
  'bscf.or.kr',
};

bool isAllowedBookingUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();
    return allowedBookingDomains.any((d) => host == d || host.endsWith('.$d'));
  } catch (_) {
    return false;
  }
}

class ApiService {
  final CacheService _cache;
  late final Dio _dio;

  ApiService(this._cache) {
    _dio = Dio(BaseOptions(
      baseUrl: backendUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  /// Ping /health to wake the Render free-tier server.
  /// Returns true when server is up.
  Future<bool> pingHealth() async {
    try {
      await _dio.get(
        '/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Performance>> fetchPerformances({
    String category = 'all',
    String region = 'all',
    int limit = 50,
  }) async {
    try {
      final resp = await _dio.get(
        '/api/performances',
        queryParameters: {
          if (category != 'all') 'category': category,
          if (region != 'all') 'region': region,
          'limit': limit,
        },
      );

      final list = (resp.data['performances'] as List)
          .map((e) => Performance.fromJson(e as Map<String, dynamic>))
          .toList();

      await _cache.savePerformances(list, category: category, region: region);
      return list;
    } on DioException {
      // Fallback to cache
      final cached = await _cache.loadPerformances(category: category, region: region);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<void> setAlarm({
    required String perfId,
    required String? fcmToken,
    required int minutesBefore,
  }) async {
    await _dio.post('/api/alarm/set', data: {
      'perf_id': perfId,
      if (fcmToken != null) 'fcm_token': fcmToken,
      'minutes_before': minutesBefore,
    });
  }
}
