// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taekit';

  @override
  String get appTagline => 'Performance Ticket Open Alerts';

  @override
  String get appSubtitle => 'National & Municipal Classic / Gugak Performances';

  @override
  String get genreQuestion => 'What kind of performances\ndo you enjoy?';

  @override
  String get genreSubtitle => 'Select your genre for personalized alerts.';

  @override
  String get classic => 'Classic Music';

  @override
  String get classicSubtitle => 'Orchestra · Chamber · Vocal';

  @override
  String get gugak => 'Traditional Korean Music';

  @override
  String get gugakSubtitle => 'National Gugak Center · Municipal Gugak';

  @override
  String get viewAll => 'View All';

  @override
  String get cityTitle => 'Select Region';

  @override
  String get cityQuestion => 'Which cities would you like\nto follow?';

  @override
  String get citySubtitle => 'Multiple selection allowed.';

  @override
  String get activeRegions => 'Service Regions';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String confirmSelection(int count) {
    return 'Confirm ($count)';
  }

  @override
  String get openRunTitle => 'Taekit';

  @override
  String get refresh => 'Refresh';

  @override
  String get performances => 'Performances';

  @override
  String get myAlarms => 'My Alarms';

  @override
  String get settings => 'Settings';

  @override
  String get noPerformances => 'No performances found.';

  @override
  String get noAlarms => 'No alarms set.';

  @override
  String get noAlarmsHint => 'Tap 🔔 in the list to set an alarm.';

  @override
  String get serverPreparing => 'Server is waking up';

  @override
  String get serverPreparingHint => 'Please wait a moment.';

  @override
  String retryIn(int sec) {
    return 'Retrying in ${sec}s';
  }

  @override
  String get retryNow => 'Retry Now';

  @override
  String get openNow => 'Book Now';

  @override
  String daysUntilOpen(int days) {
    return 'Opens in $days days';
  }

  @override
  String hoursMinutesUntilOpen(int h, int m) {
    return 'Opens in ${h}h ${m}m';
  }

  @override
  String minutesSecondsUntilOpen(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String get alarmOn => 'Alarm ON';

  @override
  String get alarm => 'Alarm';

  @override
  String get setAlarmTitle => 'Set Alarm';

  @override
  String get before10min => '10 minutes before';

  @override
  String get before1hr => '1 hour before';

  @override
  String get before24hr => '24 hours before';

  @override
  String get alarmSet => 'Alarm set.';

  @override
  String get alarmCancelled => 'Alarm cancelled.';

  @override
  String get blockedUrl => 'Unsupported Site';

  @override
  String get blockedUrlMessage =>
      'This booking site is not in our verified list.';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get offlineBanner => 'Offline — showing cached data';

  @override
  String get interestSettings => 'Preferences';

  @override
  String get genre => 'Genre';

  @override
  String get region => 'Region';

  @override
  String get notSet => 'Not set';

  @override
  String get appInfo => 'App Info';

  @override
  String get version => 'Version';

  @override
  String get resetOnboarding => 'Reset Preferences';

  @override
  String get resetOnboardingSubtitle => 'Redo genre & region setup';

  @override
  String get hot => 'HOT';

  @override
  String get free => 'Free Entry';

  @override
  String get national => 'National';
}
