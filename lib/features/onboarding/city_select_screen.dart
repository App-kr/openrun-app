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
  final _searchController = TextEditingController();
  String _query = '';

  // (name, venueCount)
  static const _activeCities = [
    ('서울', '5개 공연장'),
    ('부산', '3개 공연장'),
    ('대구', '2개 공연장'),
    ('인천', '1개 공연장'),
    ('광주', '2개 공연장'),
    ('대전', '1개 공연장'),
  ];

  static const _soonCities = ['통영', '창원', '전주', '수원'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<(String, String)> get _filteredActive {
    if (_query.isEmpty) return _activeCities;
    return _activeCities
        .where((c) => c.$1.contains(_query))
        .toList();
  }

  List<String> get _filteredSoon {
    if (_query.isEmpty) return _soonCities;
    return _soonCities.where((c) => c.contains(_query)).toList();
  }

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
    final active = _filteredActive;
    final soon = _filteredSoon;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('지역 선택'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '도시 이름 검색...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Beta label ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                      SizedBox(width: 5),
                      Text(
                        '베타 서비스 · 6개 대도시',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── City grid ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active.isNotEmpty) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: active.map((city) => _CityChip(
                        name: city.$1,
                        count: city.$2,
                        selected: _selected.contains(city.$1),
                        onTap: () => setState(() {
                          _selected.contains(city.$1)
                              ? _selected.remove(city.$1)
                              : _selected.add(city.$1);
                        }),
                      )).toList(),
                    ),
                  ],

                  if (soon.isNotEmpty && _query.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 12),
                      child: Row(
                        children: [
                          Text(
                            'COMING SOON',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: soon.map((city) => _CityChip(
                        name: city,
                        count: '준비 중',
                        selected: false,
                        soon: true,
                        onTap: () {},
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: const Color(0xFF185FA5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              child: Text(
                _selected.isEmpty
                    ? '공연 보기 →'
                    : '${_selected.map((c) => c).join(', ')} 공연 보기 →',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String name;
  final String count;
  final bool selected;
  final bool soon;
  final VoidCallback onTap;

  const _CityChip({
    required this.name,
    required this.count,
    required this.selected,
    this.soon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: soon ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.classicBg
              : soon
                  ? AppColors.background
                  : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF185FA5)
                : AppColors.divider,
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFF185FA5).withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF185FA5)
                        : soon
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? AppColors.classicText
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (soon)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SOON',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                ),
              ),
            if (selected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF185FA5)),
              ),
          ],
        ),
      ),
    );
  }
}
