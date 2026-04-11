import 'package:flutter/material.dart';

enum BadgeType { hot, free, national }

class BadgeWidget extends StatelessWidget {
  final BadgeType type;

  const BadgeWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final config = switch (type) {
      BadgeType.hot => (
          label: 'HOT',
          bg: const Color(0xFFDC2626),
          fg: Colors.white,
        ),
      BadgeType.free => (
          label: '무료 Free',
          bg: const Color(0xFF16A34A),
          fg: Colors.white,
        ),
      BadgeType.national => (
          label: '국립',
          bg: const Color(0xFF1D4ED8),
          fg: Colors.white,
        ),
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
