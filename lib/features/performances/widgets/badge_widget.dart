import 'package:flutter/material.dart';
import '../../../core/theme.dart';

enum BadgeType { hot, free, national }

class BadgeWidget extends StatelessWidget {
  final BadgeType type;

  const BadgeWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final config = switch (type) {
      BadgeType.hot => (label: 'HOT', bg: AppColors.hot.withOpacity(0.1), fg: AppColors.hot),
      BadgeType.free => (label: '수수료 0원', bg: AppColors.free.withOpacity(0.1), fg: AppColors.free),
      BadgeType.national => (label: '국립', bg: AppColors.national.withOpacity(0.1), fg: AppColors.national),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: config.fg),
      ),
    );
  }
}
