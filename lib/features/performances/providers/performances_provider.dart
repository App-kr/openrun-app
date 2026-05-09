import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/performance.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/cache_service.dart';

part 'performances_provider.g.dart';

/// Stale-while-revalidate: 캐시 즉시 표시 → 백그라운드 API 갱신
/// 캐시 없을 때만 서버 응답 대기 (콜드스타트 UX 최소화)
@riverpod
class Performances extends _$Performances {
  String _category = 'all';
  String _region = 'all';

  @override
  Future<(List<Performance>, bool)> build({
    String category = 'all',
    String region = 'all',
  }) async {
    _category = category;
    _region = region;

    final cache = ref.watch(cacheServiceProvider);
    final api = ref.watch(apiServiceProvider);

    // 1. 캐시 즉시 로드
    final cached = await cache.loadPerformances(category: category, region: region);

    if (cached.isNotEmpty) {
      // 캐시 있으면 즉시 표시 + 백그라운드 갱신 예약
      _scheduleBackgroundRefresh(api, cache);
      return (cached, true);
    }

    // 2. 캐시 없으면 서버 대기 (최초 실행)
    try {
      final fresh = await api.fetchPerformances(category: category, region: region);
      return (fresh, false);
    } catch (e) {
      rethrow;
    }
  }

  /// 백그라운드에서 API 호출 후 로딩 없이 state 교체
  void _scheduleBackgroundRefresh(ApiService api, CacheService cache) {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final fresh = await api.fetchPerformances(
          category: _category,
          region: _region,
        );
        // 로딩 스피너 없이 데이터만 교체
        if (!state.isLoading) {
          state = AsyncData((fresh, false));
        }
      } catch (_) {
        // 백그라운드 갱신 실패 → 캐시 유지 (무시)
      }
    });
  }

  /// 강제 새로고침 (pull-to-refresh용)
  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    final api = ref.read(apiServiceProvider);
    try {
      final fresh = await api.fetchPerformances(category: _category, region: _region);
      state = AsyncData((fresh, false));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
