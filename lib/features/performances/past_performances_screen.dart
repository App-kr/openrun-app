import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../shared/services/api_service.dart';
import 'models/performance.dart';
import 'widgets/perf_card.dart';

/// 지난 공연 화면 — performance_at < 오늘
/// 에러 시 자동 재시도 (지수 백오프), 앱 복귀 시 자동 갱신
class PastPerformancesScreen extends ConsumerStatefulWidget {
  const PastPerformancesScreen({super.key});

  @override
  ConsumerState<PastPerformancesScreen> createState() =>
      _PastPerformancesScreenState();
}

class _PastPerformancesScreenState extends ConsumerState<PastPerformancesScreen>
    with WidgetsBindingObserver {
  List<Performance>? _perfs;
  bool _loading = true;
  bool _retrying = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  // 지수 백오프 딜레이 (초)
  static const _retryDelays = [2, 4, 8, 16, 30];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱이 포그라운드로 돌아오면 자동 갱신
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _perfs != null) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    _retryTimer?.cancel();
    if (!silent) {
      setState(() {
        _loading = true;
        _retrying = false;
      });
    }
    try {
      final api = ref.read(apiServiceProvider);
      final perfs = await api.fetchPastPerformances(limit: 100);
      if (!mounted) return;
      setState(() {
        _perfs = perfs;
        _loading = false;
        _retrying = false;
        _retryCount = 0;
      });
    } catch (_) {
      if (!mounted) return;
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    final delay = _retryDelays[_retryCount.clamp(0, _retryDelays.length - 1)];
    _retryCount++;
    setState(() {
      _loading = false;
      _retrying = true;
    });
    _retryTimer = Timer(Duration(seconds: delay), () {
      if (!mounted) return;
      _load(silent: _perfs != null); // 데이터 있으면 화면 유지하며 백그라운드 갱신
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('지난 공연'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        // 재시도 중 상태 표시 (앱바 하단 얇은 줄)
        bottom: _retrying
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 첫 로드 중
    if (_loading && _perfs == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '지난 공연을 불러오는 중...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // 데이터 없고 재시도 중 — 자동으로 다시 불러오는 중임을 조용히 표시
    if (_perfs == null && _retrying) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            Text(
              '서버 연결 중...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withAlpha(180),
              ),
            ),
          ],
        ),
      );
    }

    final perfs = _perfs ?? [];

    if (perfs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_outlined,
                size: 52, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              '지난 공연이 없습니다.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                '총 ${perfs.length}건의 지난 공연',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => PerfCard(
                perf: perfs[i],
                isPast: true,
                onTap: () => ctx.push(
                  '/performances/${perfs[i].id}',
                  extra: perfs[i],
                ),
              ),
              childCount: perfs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
