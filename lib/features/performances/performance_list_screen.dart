import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../shared/services/api_service.dart';
import '../../shared/widgets/error_widget.dart';
import 'providers/performances_provider.dart';
import 'widgets/on_filter_bar.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/session_status_widget.dart';
import 'widgets/ad_banner_card.dart';
import 'widgets/perf_card.dart';

class PerformanceListScreen extends ConsumerStatefulWidget {
  const PerformanceListScreen({super.key});

  @override
  ConsumerState<PerformanceListScreen> createState() => _PerformanceListScreenState();
}

class _PerformanceListScreenState extends ConsumerState<PerformanceListScreen> {
  String _category = 'all';
  String _region = 'all';
  String _status = 'all';
  List<Map<String, dynamic>> _ads = [];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    final api = ref.read(apiServiceProvider);
    final ads = await api.fetchAds();
    if (mounted) setState(() => _ads = ads);
  }

  List<dynamic> _filterByStatus(List<dynamic> perfs) {
    if (_status == 'all') return perfs;
    final now = DateTime.now();
    return perfs.where((p) {
      final openAt = p.ticketOpenAt;
      if (_status == 'open') return openAt.isBefore(now);
      if (_status == 'soon') {
        final diff = openAt.difference(now);
        return !openAt.isBefore(now) && diff.inDays < 7;
      }
      // upcoming
      return openAt.difference(now).inDays >= 7;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final perfsAsync = ref.watch(
      performancesProvider(category: _category, region: _region),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Semantics(
          label: '택킷 앱',
          header: true,
          child: const Text('택킷'),
        ),
        actions: [
          Semantics(
            label: '알림 설정',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 설정 준비 중')),
                );
              },
            ),
          ),
          Semantics(
            label: '새로고침',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(performancesProvider(category: _category, region: _region).notifier).forceRefresh(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: OnFilterBar(
            selectedCategory: _category,
            selectedRegion: _region,
            selectedStatus: _status,
            onCategoryChanged: (v) => setState(() => _category = v),
            onRegionChanged: (v) => setState(() => _region = v),
            onStatusChanged: (v) => setState(() => _status = v),
          ),
        ),
      ),
      body: Stack(
        children: [
          perfsAsync.when(
        loading: () => _WakingLoadingList(
          onServerAwake: () => ref.read(performancesProvider(category: _category, region: _region).notifier).forceRefresh(),
          api: ref.read(apiServiceProvider),
        ),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.read(performancesProvider(category: _category, region: _region).notifier).forceRefresh(),
          maxRetries: 3,
        ),
        data: (result) {
          final perfs = _filterByStatus(result.$1);
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
                            onTap: () => ref.read(performancesProvider(category: _category, region: _region).notifier).forceRefresh(),
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
                  onRefresh: () async => ref.read(performancesProvider(category: _category, region: _region).notifier).forceRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    // +1 for "지난 공연 보기" footer
                    itemCount: perfs.length + (_ads.isNotEmpty ? (perfs.length ~/ 10) : 0) + 1,
                    itemBuilder: (ctx, i) {
                      final totalContentItems = perfs.length + (_ads.isNotEmpty ? (perfs.length ~/ 10) : 0);
                      // 마지막 슬롯 — 지난 공연 버튼
                      if (i == totalContentItems) {
                        return _PastPerformancesButton(onTap: () => ctx.push('/performances/past'));
                      }
                      // 매 11번째 슬롯 (인덱스 10, 21, 32...) 에 광고 삽입
                      if (_ads.isNotEmpty) {
                        final adSlots = i ~/ 11;
                        if (i % 11 == 10 && adSlots < _ads.length) {
                          return AdBannerCard(ad: _ads[adSlots % _ads.length]);
                        }
                        final perfIdx = i - adSlots - (i % 11 > 10 ? 1 : 0);
                        if (perfIdx >= 0 && perfIdx < perfs.length) {
                          return PerfCard(
                            perf: perfs[perfIdx],
                            onTap: () => ctx.push('/performances/${perfs[perfIdx].id}', extra: perfs[perfIdx]),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return PerfCard(
                        perf: perfs[i],
                        onTap: () => ctx.push('/performances/${perfs[i].id}', extra: perfs[i]),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
          SessionStatusOverlay(api: ref.read(apiServiceProvider)),
        ],
      ),
    );
  }
}

/// 지난 공연 보기 버튼 — 메인 목록 최하단
class _PastPerformancesButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PastPerformancesButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                '지난 공연 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
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
  bool _failed = false;
  int _pingAttempt = 0;
  int _elapsedSeconds = 0;
  static const _maxPings = 7; // 5s + 8s*6 ≈ 60s
  Timer? _bannerTimer;
  Timer? _pingTimer;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showWakeBanner = true);
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
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
      widget.onServerAwake();
      return;
    }
    if (_pingAttempt < _maxPings) {
      _pingTimer = Timer(const Duration(seconds: 8), _doPing);
    } else {
      setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() {
      _failed = false;
      _pingAttempt = 0;
      _elapsedSeconds = 0;
    });
    _schedulePing();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pingTimer?.cancel();
    _elapsedTimer?.cancel();
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!_failed)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      if (!_failed) const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _failed
                              ? '서버 연결에 실패했습니다.'
                              : '공연 정보를 불러오는 중입니다\n최초 실행 시 30초 소요될 수 있습니다',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.classicText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_failed)
                        TextButton(
                          onPressed: _retry,
                          child: const Text('재시도',
                              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  if (!_failed) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: null,
                      color: AppColors.accent,
                      backgroundColor: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_elapsedSeconds초 경과',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
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

