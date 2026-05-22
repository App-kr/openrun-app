import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/performance.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/cache_service.dart';

part 'performances_provider.g.dart';

/// 앱 번들 시드 데이터 — 서버 콜드스타트 시 즉시 표시
Future<List<Performance>> _loadSeedData({
  String category = 'all',
  String region = 'all',
}) async {
  try {
    final raw = await rootBundle.loadString('assets/seed_performances.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Performance.fromJson(e as Map<String, dynamic>))
        .toList();
    return list.where((p) {
      final catOk = category == 'all' || p.category == category;
      final regOk = region == 'all' || p.region == region;
      return catOk && regOk;
    }).toList();
  } catch (_) {
    return [];
  }
}

/// 로딩 전략 (멜론티켓/인터파크 패턴):
/// 1. 캐시 있으면 즉시 표시 → 백그라운드 갱신
/// 2. 캐시 없으면 API 대기 — 실패해도 에러 화면 없이 자동 재시도
/// 3. 어떤 상황에서도 AsyncError 절대 발생 안 함
@riverpod
class Performances extends _$Performances {
  String _category = 'all';
  String _region = 'all';
  bool _disposed = false;

  // 지수 백오프 딜레이 (초)
  static const _retryDelays = [3, 5, 10, 20, 30];

  @override
  Future<(List<Performance>, bool)> build({
    String category = 'all',
    String region = 'all',
  }) async {
    _category = category;
    _region = region;
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final cache = ref.watch(cacheServiceProvider);
    final api = ref.watch(apiServiceProvider);

    // ── STEP 1: 시드 데이터 최우선 (번들 에셋, ~10ms) ─────────────────
    // 캐시/API 보다 먼저 확인 → 앱 첫 화면 즉시 표시
    // isFromCache=false: 시드는 앱 내장 데이터 → "오프라인" 배너 표시 안 함
    final seed = await _loadSeedData(category: category, region: region);
    if (seed.isNotEmpty) {
      // 시드 즉시 반환 → 백그라운드에서 캐시 확인 후 API 갱신
      _scheduleFullRefresh(api, cache);
      return (seed, false);
    }

    // ── STEP 2: 시드 없으면 캐시 확인 ────────────────────────────────
    final cached = await cache.loadPerformances(category: category, region: region);
    if (cached.isNotEmpty) {
      _scheduleBackgroundRefresh(api, cache);
      return (cached, true);
    }

    // ── STEP 3: 캐시도 없으면 API 직접 호출 (실패 시 자동 재시도) ──────
    for (var attempt = 0; ; attempt++) {
      if (_disposed) return (const <Performance>[], false);

      try {
        final fresh = await api.fetchPerformances(
          category: _category,
          region: _region,
        );
        cache.savePerformances(fresh, category: category, region: region)
            .catchError((_) {});
        return (fresh, false);
      } catch (_) {
        if (_disposed) return (const <Performance>[], false);
        final delay = _retryDelays[attempt.clamp(0, _retryDelays.length - 1)];
        await Future.delayed(Duration(seconds: delay));
      }
    }
  }

  /// 시드 표시 후 백그라운드에서 캐시 확인 → API 갱신
  void _scheduleFullRefresh(ApiService api, CacheService cache) {
    Future.delayed(const Duration(milliseconds: 80), () async {
      if (_disposed) return;
      // 캐시 먼저 (poster_url 포함된 이전 API 데이터)
      final cached = await cache.loadPerformances(category: _category, region: _region);
      if (!_disposed && cached.isNotEmpty && !state.isLoading) {
        state = AsyncData((cached, true)); // 캐시: 오프라인 배너 표시
      }
      // API 갱신
      _scheduleBackgroundRefresh(api, cache);
    });
  }

  /// 백그라운드 갱신 — 로딩 스피너 없이 조용히 교체
  /// Render 콜드스타트(최대 60초) 대비 충분한 타임아웃
  void _scheduleBackgroundRefresh(ApiService api, CacheService cache) {
    Future.delayed(const Duration(milliseconds: 150), () async {
      if (_disposed) return;
      // 재시도 2회: Render 콜드스타트 후 첫 응답이 느릴 수 있음
      for (var attempt = 0; attempt < 2; attempt++) {
        if (_disposed) return;
        try {
          final fresh = await api.fetchPerformances(
            category: _category,
            region: _region,
          );
          if (_disposed) return;
          cache.savePerformances(fresh, category: _category, region: _region)
              .catchError((_) {});
          // isLoading 체크 제거: seed/cache 위에 덮어쓰기 항상 허용
          state = AsyncData((fresh, false));
          return; // 성공하면 종료
        } catch (_) {
          if (attempt == 0) {
            // 1차 실패 → 30초 대기 후 재시도 (Render 콜드스타트 대응)
            await Future.delayed(const Duration(seconds: 30));
          }
          // 2차 실패 → 캐시 유지, 무시
        }
      }
    });
  }

  /// 화면 변화 없는 조용한 백그라운드 갱신 — 앱 포그라운드 복귀 시 사용
  /// forceRefresh()와 달리 AsyncLoading을 설정하지 않아 shimmer가 표시되지 않음
  Future<void> silentRefresh() async {
    if (_disposed) return;
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(cacheServiceProvider);
    try {
      final fresh = await api.fetchPerformances(
        category: _category,
        region: _region,
      );
      if (_disposed) return;
      cache.savePerformances(fresh, category: _category, region: _region)
          .catchError((_) {});
      state = AsyncData((fresh, false));
    } catch (_) {
      // 실패 시 기존 상태 유지 (조용히 무시)
    }
  }

  /// Pull-to-refresh — 에러 발생해도 캐시 복원, 절대 AsyncError 없음
  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(cacheServiceProvider);
    try {
      final fresh = await api.fetchPerformances(
        category: _category,
        region: _region,
      );
      cache.savePerformances(fresh, category: _category, region: _region)
          .catchError((_) {});
      state = AsyncData((fresh, false));
    } catch (_) {
      // 실패 → 캐시로 복원 (없으면 빈 리스트, 로딩 상태 유지)
      final cached = await cache.loadPerformances(
        category: _category,
        region: _region,
      );
      if (cached.isNotEmpty) {
        state = AsyncData((cached, true));
      }
      // 캐시도 없으면 AsyncLoading 유지 → shimmer 계속
    }
  }
}
