import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AppErrorWidget extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  final int maxRetries;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.maxRetries = 3,
  });

  @override
  State<AppErrorWidget> createState() => _AppErrorWidgetState();
}

class _AppErrorWidgetState extends State<AppErrorWidget> {
  Timer? _timer;
  int _countdown = 10;
  int _retriesLeft = 0;

  @override
  void initState() {
    super.initState();
    _retriesLeft = widget.maxRetries;
    if (widget.onRetry != null && _retriesLeft > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 10);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        if (_retriesLeft > 0) {
          setState(() => _retriesLeft--);
          widget.onRetry!();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRetry = widget.onRetry != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_outlined, size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            const Text(
              '서버 준비 중입니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              '잠시 후 다시 시도해주세요.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (canRetry && _retriesLeft > 0) ...[
              const SizedBox(height: 24),
              Text(
                '$_countdown초 후 자동 재시도 ($_retriesLeft회 남음)',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _timer?.cancel();
                  setState(() {
                    _retriesLeft--;
                    _countdown = 10;
                  });
                  widget.onRetry!();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('지금 재시도'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ] else if (canRetry && _retriesLeft <= 0) ...[
              const SizedBox(height: 24),
              const Text(
                '서버에 연결할 수 없습니다.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _retriesLeft = widget.maxRetries);
                  _startTimer();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('다시 시도'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
