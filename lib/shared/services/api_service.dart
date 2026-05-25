import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  // 서울
  'seoulphil.or.kr',
  'lotteconcerthall.com',
  'sacticket.co.kr',
  'sac.or.kr',
  'sejong.or.kr',
  'sejongpac.or.kr',
  'kbssym.or.kr',
  'nationalopera.or.kr',
  'naruart.or.kr',
  'edu.junggu.seoul.kr',
  // 국립
  'gugak.go.kr',
  'gugakbs.go.kr',
  'nationaltheater.or.kr',
  // 지방
  'bscc.or.kr',
  'bscf.or.kr',
  'classicbusan.busan.go.kr',
  'daeguconcethouse.or.kr',
  'artincheon.org',
  'gcf.or.kr',
  'gjart.kr',
  'daejeonarts.or.kr',
  'timf.org',
  'changwonart.or.kr',
  'jinam.or.kr',
  'ulmusic.or.kr',
  // 티켓팅 플랫폼
  'interpark.com',
  'tickets.interpark.com',
  'ticket.yes24.com',
  'yes24.com',
  'ticketlink.co.kr',
  'melon.com',
  'naver.com',
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

/// Supabase PostgREST는 snake_case로 반환 → Freezed 모델(camelCase)로 변환
Map<String, dynamic> _snakeToCamel(Map<String, dynamic> m) {
  String camelize(String s) {
    final parts = s.split('_');
    if (parts.length == 1) return s;
    return parts[0] +
        parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
  }
  return m.map((k, v) => MapEntry(camelize(k), v));
}

class ApiService {
  final CacheService _cache;
  late final Dio _dio;

  ApiService(this._cache) {
    _dio = Dio(BaseOptions(
      baseUrl: backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      responseDecoder: (responseBytes, options, responseBody) =>
          utf8.decode(responseBytes, allowMalformed: true),
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(responseBody: false, requestBody: false));
    }
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
    int limit = 500,
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

      final rawList = resp.data['performances'] as List;
      final list = rawList
          .map((e) {
            final m = _snakeToCamel(e as Map<String, dynamic>);
            // ticket_open_at 없는 행은 앱에 표시하지 않음
            if (m['ticketOpenAt'] == null) return null;
            try {
              return Performance.fromJson(m);
            } catch (_) {
              return null;
            }
          })
          .whereType<Performance>()
          .toList();

      _cache.savePerformances(list, category: category, region: region).catchError((e) {
        debugPrint('[API] cache save error (ignored): $e');
      });
      return list;
    } on DioException {
      // Network error — fallback to cache
      final cached = await _cache.loadPerformances(category: category, region: region);
      if (cached.isNotEmpty) return cached;
      rethrow;
    } catch (e, st) {
      debugPrint('[API] fetchPerformances parse error: $e\n$st');
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

  Future<List<Performance>> fetchPastPerformances({
    String category = 'all',
    String region = 'all',
    int limit = 50,
  }) async {
    try {
      final resp = await _dio.get(
        '/api/performances/past',
        queryParameters: {
          if (category != 'all') 'category': category,
          if (region != 'all') 'region': region,
          'limit': limit,
        },
      );
      final rawList = resp.data['performances'] as List;
      return rawList
          .map((e) {
            final m = _snakeToCamel(e as Map<String, dynamic>);
            if (m['ticketOpenAt'] == null) return null;
            try {
              return Performance.fromJson(m);
            } catch (_) {
              return null;
            }
          })
          .whereType<Performance>()
          .toList();
    } catch (e, st) {
      debugPrint('[API] fetchPastPerformances error: $e\n$st');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAds() async {
    try {
      final resp = await _dio.get('/api/ads');
      final rawList = resp.data['ads'] as List? ?? [];
      return rawList.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
