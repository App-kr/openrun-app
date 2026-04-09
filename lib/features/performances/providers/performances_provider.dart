import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/performance.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/cache_service.dart';

part 'performances_provider.g.dart';

@riverpod
Future<(List<Performance>, bool)> performances(
  PerformancesRef ref, {
  String category = 'all',
  String region = 'all',
}) async {
  final api = ref.watch(apiServiceProvider);
  final cache = ref.watch(cacheServiceProvider);

  // Try to load fresh from API
  try {
    final fresh = await api.fetchPerformances(category: category, region: region);
    return (fresh, false); // (data, isFromCache)
  } catch (_) {
    // Fallback to cache
    final cached = await cache.loadPerformances(category: category, region: region);
    if (cached.isNotEmpty) return (cached, true);
    rethrow;
  }
}
