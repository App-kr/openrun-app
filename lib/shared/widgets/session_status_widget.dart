import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SessionStatusOverlay extends StatefulWidget {
  final ApiService api;
  const SessionStatusOverlay({super.key, required this.api});

  @override
  State<SessionStatusOverlay> createState() => _SessionStatusOverlayState();
}

class _SessionStatusOverlayState extends State<SessionStatusOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  bool _visible = false;

  bool? _serverOk;
  int _totalPerfs = 0;
  int _noPriceCount = 0;
  int _noPosterCount = 0;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    final serverOk = await widget.api.pingHealth();
    if (!mounted) return;

    int total = 0, noPrice = 0, noPoster = 0;
    if (serverOk) {
      try {
        final perfs = await widget.api.fetchPerformances(limit: 500);
        total = perfs.length;
        noPrice = perfs.where((p) => p.priceInfo == null || p.priceInfo!.isEmpty).length;
        noPoster = perfs.where((p) => p.posterUrl == null || p.posterUrl!.isEmpty).length;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _serverOk = serverOk;
      _totalPerfs = total;
      _noPriceCount = noPrice;
      _noPosterCount = noPoster;
      _visible = true;
    });
    _slideCtrl.forward();

    // 5초 후 자동 닫기
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _slideCtrl.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final isOk = _serverOk == true;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOk ? Icons.circle : Icons.circle,
                                  size: 10,
                                  color: isOk ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOk ? '서버 연결됨' : '서버 준비 중 \u00b7 자동 재시도 중',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (isOk) ...[
                              const SizedBox(height: 8),
                              Text(
                                '공연 $_totalPerfs개 로드',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
                              ),
                              if (_noPriceCount > 0 || _noPosterCount > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '확인 필요: 가격미수집 $_noPriceCount개 \u00b7 포스터없음 $_noPosterCount개',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF999999)),
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
