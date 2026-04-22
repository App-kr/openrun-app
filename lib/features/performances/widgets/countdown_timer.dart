import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime openAt;
  final String? bookingUrl;
  final VoidCallback? onBook;
  /// When false (card view), hides the "예매하기" button and shows plain text instead.
  final bool showBookButton;

  const CountdownTimer({
    super.key,
    required this.openAt,
    this.bookingUrl,
    this.onBook,
    this.showBookButton = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    final diff = widget.openAt.difference(now);
    if (mounted) setState(() => _remaining = diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Already open
    if (_remaining.isNegative || _remaining == Duration.zero) {
      if (widget.showBookButton) {
        return Semantics(
          label: '예매하기 버튼',
          button: true,
          child: GestureDetector(
            onTap: widget.onBook,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.open,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '예매하기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      } else {
        return const Text(
          '오픈중',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.open,
          ),
        );
      }
    }

    final String label;
    final Color color;
    final bool bold;

    if (_remaining.inDays >= 7) {
      label = '${_remaining.inDays}일 후 오픈';
      color = AppColors.textSecondary;
      bold = false;
    } else if (_remaining.inHours >= 1) {
      final h = _remaining.inHours;
      final m = _remaining.inMinutes % 60;
      label = '$h시간 $m분 후';
      color = AppColors.textSecondary;
      bold = false;
    } else {
      final m = _remaining.inMinutes;
      final s = _remaining.inSeconds % 60;
      label = '$m분 ${s.toString().padLeft(2, '0')}초';
      color = AppColors.urgent;
      bold = true;
    }

    return Semantics(
      label: '티켓 오픈까지 $label',
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
