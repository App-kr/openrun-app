import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/performance.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/cache_service.dart';

part 'performances_provider.g.dart';

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

    // ── STEP 1: 캐시 즉시 확인 ────────────────────────────────────────
    final cached = await cache.loadPerformances(category: category, region: region);

    if (cached.isNotEmpty) {
      // 캐시 히트 → 즉시 반환 + 백그라운드 갱신
      _scheduleBackgroundRefresh(api, cache);
      return (cached, true);
    }

    // ── STEP 2: 캐시 없음 → API 호출 (실패 시 자동 재시도 루프) ────────
    for (var attempt = 0; ; attempt++) {
      if (_disposed) return (const <Performance>[], false); // provider 재빌드 → 종료

      try {
        final fresh = await api.fetchPerformances(
          category: _category,
          region: _region,
        );
        // 성공 → 캐시 저장 후 반환
        cache.savePerformances(fresh, category: category, region: region)
            .catchError((_) {});
        return (fresh, false);
      } catch (_) {
        if (_disposed) return (const <Performance>[], false);
        // 실패 → 지수 백오프 후 재시도 (shimmer 계속 표시)
        final delay = _retryDelays[attempt.clamp(0, _retryDelays.length - 1)];
        await Future.delayed(Duration(seconds: delay));
      }
    }
  }

  /// 백그라운드 갱신 — 로딩 스피너 없이 조용히 교체
  void _scheduleBackgroundRefresh(ApiService api, CacheService cache) {
    Future.delayed(const Duration(milliseconds: 150), () async {
      if (_disposed) return;
      try {
        final fresh = await api.fetchPerformances(
          category: _category,
          region: _region,
        );
        if (_disposed || state.isLoading) return;
        cache.savePerformances(fresh, category: _category, region: _region)
            .catchError((_) {});
        state = AsyncData((fresh, false));
      } catch (_) {
        // 백그라운드 실패 → 캐시 유지, 무시
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
