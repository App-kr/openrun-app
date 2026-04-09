import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../shared/services/api_service.dart';
import '../../shared/widgets/error_widget.dart';
import 'providers/performances_provider.dart';
import 'widgets/on_filter_bar.dart';
import 'widgets/perf_card.dart';

class PerformanceListScreen extends ConsumerStatefulWidget {
  const PerformanceListScreen({super.key});

  @override
  ConsumerState<PerformanceListScreen> createState() => _PerformanceListScreenState();
}

class _PerformanceListScreenState extends ConsumerState<PerformanceListScreen> {
  String _category = 'all';
  String _region = 'all';

  @override
  Widget build(BuildContext context) {
    final perfsAsync = ref.watch(
      performancesProvider(category: _category, region: _region),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Semantics(
          label: 'OpenRun 앱',
          header: true,
          child: const Text('OpenRun'),
        ),
        actions: [
          Semantics(
            label: '새로고침',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(performancesProvider),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: OnFilterBar(
            selectedCategory: _category,
            selectedRegion: _region,
            onCategoryChanged: (v) => setState(() => _category = v),
            onRegionChanged: (v) => setState(() => _region = v),
          ),
        ),
      ),
      body: perfsAsync.when(
        loading: () => _WakingLoadingList(
          onServerAwake: () => ref.invalidate(performancesProvider),
          api: ref.read(apiServiceProvider),
        ),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(performancesProvider),
          maxRetries: 3,
        ),
        data: (result) {
          final perfs = result.$1;
          final isFromCache = result.$2;

          if (perfs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, size: 52, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('공연 정보가 없습니다.',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return Column(
            children: [
              if (isFromCache)
                Material(
                  color: AppColors.gugakBg,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.gugakText),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              '오프라인 — 캐시 데이터 표시 중',
                              style: TextStyle(fontSize: 12, color: AppColors.gugakText),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.invalidate(performancesProvider),
                            child: const Text(
                              '새로고침',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gugakText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(performancesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: perfs.length,
                    itemBuilder: (_, i) => PerfCard(perf: perfs[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Loading skeleton that pings /health in the background.
/// After 5s shows "서버 연결 중..." banner.
/// Retries health ping at 10s intervals up to 3 times, then triggers onServerAwake.
class _WakingLoadingList extends StatefulWidget {
  final VoidCallback onServerAwake;
  final ApiService api;

  const _WakingLoadingList({required this.onServerAwake, required this.api});

  @override
  State<_WakingLoadingList> createState() => _WakingLoadingListState();
}

class _WakingLoadingListState extends State<_WakingLoadingList> {
  bool _showWakeBanner = false;
  int _pingAttempt = 0;
  static const _maxPings = 3;
  Timer? _bannerTimer;
  Timer? _pingTimer;

  @override
  void initState() {
    super.initState();
    // Show banner after 5s
    _bannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showWakeBanner = true);
    });
    // Start pinging
    _schedulePing();
  }

  void _schedulePing() {
    _pingTimer = Timer(const Duration(seconds: 5), () async {
      await _doPing();
    });
  }

  Future<void> _doPing() async {
    if (!mounted) return;
    _pingAttempt++;
    final ok = await widget.api.pingHealth();
    if (!mounted) return;
    if (ok) {
      // Server awake — refresh provider to trigger actual data load
      widget.onServerAwake();
      return;
    }
    if (_pingAttempt < _maxPings) {
      _pingTimer = Timer(const Duration(seconds: 10), _doPing);
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showWakeBanner)
          Material(
            color: AppColors.classicBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '서버 연결 중... (${_pingAttempt}/$_maxPings)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.classicText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: AppColors.divider,
            highlightColor: AppColors.white,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => Container(
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
