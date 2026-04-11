import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class OnFilterBar extends StatelessWidget {
  final String selectedCategory;
  final String selectedRegion;
  final String selectedStatus;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onStatusChanged;

  const OnFilterBar({
    super.key,
    required this.selectedCategory,
    required this.selectedRegion,
    required this.selectedStatus,
    required this.onCategoryChanged,
    required this.onRegionChanged,
    required this.onStatusChanged,
  });

  static const _categories = [
    ('all', '전체'),
    ('classic', '클래식'),
    ('gugak', '국악'),
  ];

  static const _regions = [
    ('all', '전체'),
    ('서울', '서울'),
    ('부산', '부산'),
    ('대구', '대구'),
    ('인천', '인천'),
    ('광주', '광주'),
    ('대전', '대전'),
    ('경남', '경남'),
    ('경기', '경기'),
  ];

  static const _statuses = [
    ('all', '전체'),
    ('open', '오픈중'),
    ('soon', '예매대기'),
    ('upcoming', '공연예정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterRow(
            items: _categories,
            selected: selectedCategory,
            onSelected: onCategoryChanged,
          ),
          const SizedBox(height: 5),
          _FilterRow(
            items: _regions,
            selected: selectedRegion,
            onSelected: onRegionChanged,
          ),
          const SizedBox(height: 5),
          _FilterRow(
            items: _statuses,
            selected: selectedStatus,
            onSelected: onStatusChanged,
            activeColors: const {
              'open': Color(0xFFD32F2F),
              'soon': Color(0xFFF57C00),
              'upcoming': Color(0xFF90A4AE),
            },
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, Color>? activeColors;

  const _FilterRow({
    required this.items,
    required this.selected,
    required this.onSelected,
    this.activeColors,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) {
          final (value, label) = item;
          final isSelected = selected == value;
          final activeColor = activeColors?[value] ?? AppColors.accent;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? activeColor : AppColors.divider,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
