import 'dart:math';

/// Manages shuffled icon lists per genre to avoid consecutive repeats.
class GenreIconProvider {
  GenreIconProvider._();
  static final GenreIconProvider instance = GenreIconProvider._();

  static const _classicIcons = [
    'assets/icons/classic/conductor.png',
    'assets/icons/classic/violin.png',
    'assets/icons/classic/cello.png',
    'assets/icons/classic/clef_treble.png',
    'assets/icons/classic/clef_bass.png',
    'assets/icons/classic/trumpet.png',
    'assets/icons/classic/piano.png',
    'assets/icons/classic/forte.png',
    'assets/icons/classic/quarter_note.png',
    'assets/icons/classic/harp.png',
  ];

  static const _gugakIcons = [
    'assets/icons/gugak/janggu.png',
    'assets/icons/gugak/daegeum.png',
  ];

  final List<String> _classicShuffled = [];
  final List<String> _gugakShuffled = [];
  int _classicIdx = 0;
  int _gugakIdx = 0;
  final _rand = Random();

  void _ensureShuffled(List<String> source, List<String> dest) {
    if (dest.isEmpty) {
      dest.addAll(source);
      dest.shuffle(_rand);
    }
  }

  String nextIcon(String category) {
    if (category == 'gugak') {
      _ensureShuffled(_gugakIcons, _gugakShuffled);
      final icon = _gugakShuffled[_gugakIdx % _gugakShuffled.length];
      _gugakIdx++;
      // Re-shuffle when exhausted
      if (_gugakIdx >= _gugakShuffled.length) {
        _gugakIdx = 0;
        _gugakShuffled.shuffle(_rand);
      }
      return icon;
    } else {
      _ensureShuffled(_classicIcons, _classicShuffled);
      final icon = _classicShuffled[_classicIdx % _classicShuffled.length];
      _classicIdx++;
      if (_classicIdx >= _classicShuffled.length) {
        _classicIdx = 0;
        _classicShuffled.shuffle(_rand);
      }
      return icon;
    }
  }
}
