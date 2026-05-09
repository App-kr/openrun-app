import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../shared/services/api_service.dart';
import 'models/performance.dart';
import 'widgets/perf_card.dart';

/// 지난 공연 화면 — performance_at < 오늘인 공연 목록
class PastPerformancesScreen extends ConsumerStatefulWidget {
  const PastPerformancesScreen({super.key});

  @override
  ConsumerState<PastPerformancesScreen> createState() =>
      _PastPerformancesScreenState();
}

class _PastPerformancesScreenState
    extends ConsumerState<PastPerformancesScreen> {
  List<Performance>? _perfs;
  bool _loading = true;
  String? _error;
  final String _category = 'all';
  final String _region = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final perfs = await api.fetchPastPerformances(
        category: _category,
        region: _region,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _perfs = perfs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
            onPressed: _load,
          ),
        ],
      ),
      body: _build(),
    );
  }

  Widget _build() {
    if (_loading) {
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('공연 정보를 불러올 수 없습니다.'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('다시 시도'),
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
            Icon(Icons.event_available_outlined, size: 52, color: AppColors.textSecondary),
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
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
