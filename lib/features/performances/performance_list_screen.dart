import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import 'providers/performances_provider.dart';
import 'widgets/on_filter_bar.dart';
import 'package:go_router/go_router.dart';
import '../../shared/services/api_service.dart';
import 'widgets/ad_banner_card.dart';
import 'widgets/perf_card.dart';

class PerformanceListScreen extends ConsumerStatefulWidget {
  const PerformanceListScreen({super.key});

  @override
  ConsumerState<PerformanceListScreen> createState() =>
      _PerformanceListScreenState();
}

class _PerformanceListScreenState extends ConsumerState<PerformanceListScreen>
    with WidgetsBindingObserver {
  String _category = 'all';
  String _region = 'all';
  String _status = 'all';
  List<Map<String, dynamic>> _ads = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAds();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱이 포그라운드로 복귀할 때 shimmer 없이 조용히 데이터 갱신
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(performancesProvider(
                  category: _category, region: _region)
              .notifier)
          .silentRefresh();
    }
  }

  Future<void> _loadAds() async {
    final api = ref.read(apiServiceProvider);
    final ads = await api.fetchAds().catchError((_) => <Map<String, dynamic>>[]);
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
              onPressed: () => context.go('/alarms'),
            ),
          ),
          Semantics(
            label: '새로고침',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref
                  .read(performancesProvider(
                          category: _category, region: _region)
                      .notifier)
                  .forceRefresh(),
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
            // ── 로딩: shimmer ─────────────────────────────────────────
            loading: () => const _ShimmerList(),
            // ── 에러: 발생하지 않음 (provider가 내부 처리)
            //         만약 발생해도 shimmer만 표시, 버튼 없음 ───────────
            error: (_, __) => const _ShimmerList(),
            // ── 데이터 ───────────────────────────────────────────────
            data: (result) {
              final perfs = _filterByStatus(result.$1);

              // 빈 리스트 = 아직 로딩 중 (재시도 루프 실행 중)
              if (result.$1.isEmpty) return const _ShimmerList();

              // 필터 결과 없음
              if (perfs.isEmpty) {
                return _EmptyFilter(
                  onReset: () => setState(() {
                    _category = 'all';
                    _region = 'all';
                    _status = 'all';
                  }),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => ref
                          .read(performancesProvider(
                                  category: _category, region: _region)
                              .notifier)
                          .forceRefresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: perfs.length +
                            (_ads.isNotEmpty ? (perfs.length ~/ 10) : 0) +
                            1,
                        itemBuilder: (ctx, i) {
                          final adCount =
                              _ads.isNotEmpty ? (perfs.length ~/ 10) : 0;
                          final total = perfs.length + adCount;

                          // 마지막 슬롯 — 지난 공연 버튼
                          if (i == total) {
                            return _PastButton(
                              onTap: () => ctx.push('/performances/past'),
                            );
                          }

                          // 광고 슬롯
                          if (_ads.isNotEmpty) {
                            final adSlots = i ~/ 11;
                            if (i % 11 == 10 && adSlots < _ads.length) {
                              return AdBannerCard(
                                  ad: _ads[adSlots % _ads.length]);
                            }
                            final pi =
                                i - adSlots - (i % 11 > 10 ? 1 : 0);
                            if (pi >= 0 && pi < perfs.length) {
                              return PerfCard(
                                perf: perfs[pi],
                                onTap: () => ctx.push(
                                    '/performances/${perfs[pi].id}',
                                    extra: perfs[pi]),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          return PerfCard(
                            perf: perfs[i],
                            onTap: () => ctx.push(
                                '/performances/${perfs[i].id}',
                                extra: perfs[i]),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // SessionStatusOverlay 비활성화 — 내부 로그로만 관리
        ],
      ),
    );
  }
}

// ── 공유 shimmer ──────────────────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 128,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── 필터 결과 없음 ────────────────────────────────────────────────────────────
class _EmptyFilter extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyFilter({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 52, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('해당 조건의 공연이 없습니다.',
              style: TextStyle(
                  fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onReset,
            child: const Text('필터 초기화'),
          ),
        ],
      ),
    );
  }
}

// ── 지난 공연 버튼 ────────────────────────────────────────────────────────────
class _PastButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PastButton({required this.onTap});

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
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded,
                  size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                '지난 공연 보기',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B)),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
