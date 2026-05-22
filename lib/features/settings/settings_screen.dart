import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../features/alarms/alarm_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _cities = [];
  String _category = 'all';
  String _soundMode = 'auto';
  bool _loadedPrefs = false;

  static const _allCities = [
    '서울', '경기', '부산', '인천', '광주', '대전', '대구', '기타',
  ];

  static const _soundModes = [
    ('auto',    '자동 (장르별)',    Icons.auto_awesome_rounded),
    ('gugak',   '국악 알림음',      Icons.music_note_rounded),
    ('classic', '클래식 알림음',    Icons.piano_rounded),
    ('default', '기본 알림음',      Icons.notifications_rounded),
    ('silent',  '무음',             Icons.notifications_off_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cities     = prefs.getStringList('selected_cities') ?? [];
      _category   = prefs.getString('selected_category') ?? 'all';
      _soundMode  = prefs.getString(AlarmService.soundPrefKey) ?? 'auto';
      _loadedPrefs = true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_cities', _cities);
    await prefs.setString('selected_category', _category);
    // soundMode는 AlarmService.setSoundMode가 별도 저장
  }

  // ── 장르 선택 ─────────────────────────────────────────────
  Future<void> _showGenrePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GenrePicker(current: _category),
    );
    if (result != null && mounted) {
      setState(() => _category = result);
      await _savePrefs();
    }
  }

  // ── 지역 선택 ─────────────────────────────────────────────
  Future<void> _showCityPicker() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CityPicker(current: List.from(_cities), allCities: _allCities),
    );
    if (result != null && mounted) {
      setState(() => _cities = result);
      await _savePrefs();
    }
  }

  // ── 알림음 선택 ───────────────────────────────────────────
  Future<void> _showSoundPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SoundPicker(current: _soundMode, modes: _soundModes),
    );
    if (result != null && mounted) {
      setState(() => _soundMode = result);
      await AlarmService.instance.setSoundMode(result);
    }
  }

  Future<void> _showPrivacyPolicy(BuildContext context) async {
    final html = await rootBundle.loadString('assets/privacy_policy.html');
    if (!mounted) return;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('개인정보처리방침',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _stripHtml(html),
                  style: const TextStyle(
                    fontSize: 14, height: 1.7, color: Color(0xFF333333)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String get _categoryLabel => switch (_category) {
    'classic' => '클래식',
    'gugak'   => '국악',
    _         => '전체',
  };

  String get _soundModeLabel {
    for (final m in _soundModes) {
      if (m.$1 == _soundMode) return m.$2;
    }
    return '자동 (장르별)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: _loadedPrefs
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── 관심 설정 ─────────────────────────────────
                const _SectionHeader('관심 설정'),
                _SettingsTile(
                  icon: Icons.music_note_rounded,
                  title: '장르',
                  subtitle: _categoryLabel,
                  onTap: _showGenrePicker,
                ),
                _SettingsTile(
                  icon: Icons.place_outlined,
                  title: '지역',
                  subtitle: _cities.isEmpty ? '미설정 (전체)' : _cities.join(', '),
                  onTap: _showCityPicker,
                ),
                const SizedBox(height: 24),

                // ── 알림 설정 ─────────────────────────────────
                const _SectionHeader('알림 설정'),
                _SettingsTile(
                  icon: Icons.volume_up_rounded,
                  title: '알림음',
                  subtitle: _soundModeLabel,
                  onTap: _showSoundPicker,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4, top: 2),
                  child: Text(
                    '국악·클래식 전용 알림음을 사용하려면 음원 파일을 추가하세요',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),

                // ── 앱 정보 ───────────────────────────────────
                const _SectionHeader('앱 정보'),
                const _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: '버전',
                  subtitle: '1.0.6',
                ),
                _SettingsTile(
                  icon: Icons.refresh_rounded,
                  title: '온보딩 초기화',
                  subtitle: '장르·지역 설정 다시 하기',
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('onboarding_complete');
                    await prefs.remove('selected_category');
                    await prefs.remove('selected_cities');
                    if (!mounted) return;
                    setState(() {
                      _category = 'all';
                      _cities = [];
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('설정이 초기화되었습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── 법적 정보 ─────────────────────────────────
                const _SectionHeader('법적 정보'),
                const _SettingsTile(
                  icon: Icons.copyright_rounded,
                  title: '개발자',
                  subtitle: '© 2026 Scarlett. All rights reserved.',
                ),
                const _SettingsTile(
                  icon: Icons.verified_outlined,
                  title: '특허출원',
                  subtitle: '출원번호 10-2026-0064854',
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보처리방침',
                  subtitle: '수집 항목 및 이용 안내',
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// ── 알림음 선택 BottomSheet ───────────────────────────────────────────────────
class _SoundPicker extends StatefulWidget {
  final String current;
  final List<(String, String, IconData)> modes;
  const _SoundPicker({required this.current, required this.modes});

  @override
  State<_SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends State<_SoundPicker> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('알림음 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '음원 파일(gugak_sound.mp3, classic_sound.mp3)을 추가하면 활성화됩니다',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...widget.modes.map((m) {
              final (value, label, icon) = m;
              final sel = _selected == value;
              return ListTile(
                leading: Icon(icon,
                    color: sel ? AppColors.accent : AppColors.textSecondary),
                title: Text(label,
                    style: TextStyle(
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? AppColors.accent : AppColors.textPrimary,
                    )),
                trailing: sel
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.accent, size: 20)
                    : null,
                onTap: () {
                  setState(() => _selected = value);
                  Navigator.pop(context, value);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── 장르 선택 BottomSheet ────────────────────────────────────────────────────
class _GenrePicker extends StatefulWidget {
  final String current;
  const _GenrePicker({required this.current});

  @override
  State<_GenrePicker> createState() => _GenrePickerState();
}

class _GenrePickerState extends State<_GenrePicker> {
  late String _selected;

  static const _genres = [
    ('all',     '전체',   Icons.apps_rounded),
    ('classic', '클래식', Icons.piano_rounded),
    ('gugak',   '국악',   Icons.music_note_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('장르 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._genres.map((g) {
              final (value, label, icon) = g;
              final selected = _selected == value;
              return ListTile(
                leading: Icon(icon,
                    color: selected ? AppColors.accent : AppColors.textSecondary),
                title: Text(label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? AppColors.accent : AppColors.textPrimary,
                    )),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.accent, size: 20)
                    : null,
                onTap: () {
                  setState(() => _selected = value);
                  Navigator.pop(context, value);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── 지역 선택 BottomSheet ────────────────────────────────────────────────────
class _CityPicker extends StatefulWidget {
  final List<String> current;
  final List<String> allCities;
  const _CityPicker({required this.current, required this.allCities});

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.current);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('지역 선택 (복수 가능)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text('완료',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.allCities.map((city) {
                final sel = _selected.contains(city);
                return FilterChip(
                  label: Text(city),
                  selected: sel,
                  onSelected: (v) {
                    setState(() {
                      if (v) _selected.add(city);
                      else _selected.remove(city);
                    });
                  },
                  selectedColor: AppColors.accent.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: sel ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: sel ? AppColors.accent : AppColors.divider,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_selected.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _selected.clear()),
                child: const Text('전체 해제',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── 공통 위젯 ──────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

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
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
