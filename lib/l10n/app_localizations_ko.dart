// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'OpenRun';

  @override
  String get appTagline => '공연 티켓 오픈 알림';

  @override
  String get appSubtitle => '국립·시립 클래식 & 국악 공연';

  @override
  String get genreQuestion => '어떤 공연을\n좋아하세요?';

  @override
  String get genreSubtitle => '관심 장르를 선택해 맞춤 알림을 받아보세요.';

  @override
  String get classic => '클래식';

  @override
  String get classicSubtitle => '오케스트라 · 실내악 · 성악';

  @override
  String get gugak => '국악';

  @override
  String get gugakSubtitle => '국립국악원 · 시립국악단';

  @override
  String get viewAll => '전체 보기';

  @override
  String get cityTitle => '지역 선택';

  @override
  String get cityQuestion => '공연을 보고 싶은 지역을\n선택해주세요.';

  @override
  String get citySubtitle => '복수 선택 가능합니다.';

  @override
  String get activeRegions => '서비스 지역';

  @override
  String get comingSoon => '준비 중 (SOON)';

  @override
  String confirmSelection(int count) {
    return '선택 완료 ($count곳)';
  }

  @override
  String get openRunTitle => 'OpenRun';

  @override
  String get refresh => '새로고침';

  @override
  String get performances => '공연';

  @override
  String get myAlarms => '내 알림';

  @override
  String get settings => '설정';

  @override
  String get noPerformances => '공연 정보가 없습니다.';

  @override
  String get noAlarms => '설정된 알림이 없습니다.';

  @override
  String get noAlarmsHint => '공연 목록에서 🔔 버튼을 눌러 알림을 설정하세요.';

  @override
  String get serverPreparing => '서버 준비 중입니다';

  @override
  String get serverPreparingHint => '잠시 후 다시 시도해주세요.';

  @override
  String retryIn(int sec) {
    return '$sec초 후 자동 재시도';
  }

  @override
  String get retryNow => '지금 재시도';

  @override
  String get openNow => '예매하기';

  @override
  String daysUntilOpen(int days) {
    return '$days일 후 오픈';
  }

  @override
  String hoursMinutesUntilOpen(int h, int m) {
    return '$h시간 $m분 후';
  }

  @override
  String minutesSecondsUntilOpen(int m, int s) {
    return '$m분 $s초';
  }

  @override
  String get alarmOn => '알림 ON';

  @override
  String get alarm => '알림';

  @override
  String get setAlarmTitle => '알림 시간 선택';

  @override
  String get before10min => '10분 전';

  @override
  String get before1hr => '1시간 전';

  @override
  String get before24hr => '24시간 전';

  @override
  String get alarmSet => '알림이 설정되었습니다.';

  @override
  String get alarmCancelled => '알림이 취소되었습니다.';

  @override
  String get blockedUrl => '지원하지 않는 사이트';

  @override
  String get blockedUrlMessage => '이 예매 사이트는 검증된 목록에 없습니다.';

  @override
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String get offlineBanner => '오프라인 — 캐시 데이터 표시 중';

  @override
  String get interestSettings => '관심 설정';

  @override
  String get genre => '장르';

  @override
  String get region => '지역';

  @override
  String get notSet => '미설정';

  @override
  String get appInfo => '앱 정보';

  @override
  String get version => '버전';

  @override
  String get resetOnboarding => '온보딩 초기화';

  @override
  String get resetOnboardingSubtitle => '장르·지역 설정 다시 하기';

  @override
  String get hot => 'HOT';

  @override
  String get free => '수수료 0원';

  @override
  String get national => '국립';
}
