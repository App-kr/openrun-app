import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _cities = [];
  String _category = 'all';
  bool _loadedPrefs = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cities = prefs.getStringList('selected_cities') ?? [];
      _category = prefs.getString('selected_category') ?? 'all';
      _loadedPrefs = true;
    });
  }

  String get _categoryLabel => switch (_category) {
    'classic' => '클래식',
    'gugak' => '국악',
    _ => '전체',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: _loadedPrefs
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionHeader('관심 설정'),
                _SettingsTile(
                  icon: Icons.music_note_rounded,
                  title: '장르',
                  subtitle: _categoryLabel,
                  onTap: () => context.go('/genre'),
                ),
                _SettingsTile(
                  icon: Icons.place_outlined,
                  title: '지역',
                  subtitle: _cities.isEmpty ? '미설정' : _cities.join(', '),
                  onTap: () => context.go('/city?category=$_category'),
                ),
                const SizedBox(height: 24),
                _SectionHeader('앱 정보'),
                const _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: '버전',
                  subtitle: '1.0.0',
                ),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: '온보딩 초기화',
                  subtitle: '장르·지역 설정 다시 하기',
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('onboarding_complete');
                    if (!mounted) return;
                    context.go('/genre');
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary) : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
