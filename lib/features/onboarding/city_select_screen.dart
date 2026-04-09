import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class CitySelectScreen extends StatefulWidget {
  final String category;
  const CitySelectScreen({super.key, required this.category});

  @override
  State<CitySelectScreen> createState() => _CitySelectScreenState();
}

class _CitySelectScreenState extends State<CitySelectScreen> {
  final Set<String> _selected = {};

  static const _activeCities = ['서울', '부산', '대구', '인천', '광주', '대전'];
  static const _soonCities = ['통영', '창원', '전주', '수원'];

  Future<void> _confirm() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역을 하나 이상 선택해주세요.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_cities', _selected.toList());
    await prefs.setString('selected_category', widget.category);
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/performances');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('지역 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('공연을 보고 싶은 지역을\n선택해주세요.',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.4)),
                  const SizedBox(height: 6),
                  const Text('복수 선택 가능합니다.',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 28),
                  const _SectionLabel('서비스 지역'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _activeCities.map((city) => _CityChip(
                      label: city,
                      selected: _selected.contains(city),
                      onTap: () => setState(() {
                        _selected.contains(city) ? _selected.remove(city) : _selected.add(city);
                      }),
                    )).toList(),
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('준비 중 (SOON)'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _soonCities.map((city) => _CityChip(
                      label: city,
                      selected: false,
                      soon: true,
                      onTap: () {},
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ElevatedButton(
              onPressed: _confirm,
              child: Text('선택 완료 (${_selected.length}곳)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5));
  }
}

class _CityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool soon;
  final VoidCallback onTap;

  const _CityChip({required this.label, required this.selected, this.soon = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: soon ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.classicBg : (soon ? AppColors.background : AppColors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.accent : (soon ? AppColors.textSecondary.withOpacity(0.5) : AppColors.textPrimary),
                      )),
                ],
              ),
            ),
            if (soon)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('SOON', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                ),
              ),
            if (selected)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }
}
