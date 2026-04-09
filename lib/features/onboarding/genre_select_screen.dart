import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class GenreSelectScreen extends StatelessWidget {
  const GenreSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('어떤 공연을\n좋아하세요?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3)),
              const SizedBox(height: 8),
              const Text('관심 장르를 선택해 맞춤 알림을 받아보세요.',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              _GenreCard(
                title: '클래식',
                subtitle: '오케스트라 · 실내악 · 성악',
                emoji: '🎻',
                borderColor: AppColors.classicBorder,
                bgColor: AppColors.classicBg,
                textColor: AppColors.classicText,
                onTap: () => context.go('/city?category=classic'),
              ),
              const SizedBox(height: 16),
              _GenreCard(
                title: '국악',
                subtitle: '국립국악원 · 시립국악단',
                emoji: '🥁',
                borderColor: AppColors.gugakBorder,
                bgColor: AppColors.gugakBg,
                textColor: AppColors.gugakText,
                onTap: () => context.go('/city?category=gugak'),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.go('/city?category=all'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.divider),
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('전체 보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color borderColor;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _GenreCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.borderColor,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7))),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: borderColor, size: 18),
          ],
        ),
      ),
    );
  }
}
