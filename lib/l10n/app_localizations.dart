import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenRun'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Performance Ticket Open Alerts'**
  String get appTagline;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'National & Municipal Classic / Gugak Performances'**
  String get appSubtitle;

  /// No description provided for @genreQuestion.
  ///
  /// In en, this message translates to:
  /// **'What kind of performances\ndo you enjoy?'**
  String get genreQuestion;

  /// No description provided for @genreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your genre for personalized alerts.'**
  String get genreSubtitle;

  /// No description provided for @classic.
  ///
  /// In en, this message translates to:
  /// **'Classic Music'**
  String get classic;

  /// No description provided for @classicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Orchestra · Chamber · Vocal'**
  String get classicSubtitle;

  /// No description provided for @gugak.
  ///
  /// In en, this message translates to:
  /// **'Traditional Korean Music'**
  String get gugak;

  /// No description provided for @gugakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'National Gugak Center · Municipal Gugak'**
  String get gugakSubtitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @cityTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get cityTitle;

  /// No description provided for @cityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which cities would you like\nto follow?'**
  String get cityQuestion;

  /// No description provided for @citySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple selection allowed.'**
  String get citySubtitle;

  /// No description provided for @activeRegions.
  ///
  /// In en, this message translates to:
  /// **'Service Regions'**
  String get activeRegions;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm ({count})'**
  String confirmSelection(int count);

  /// No description provided for @openRunTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenRun'**
  String get openRunTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @performances.
  ///
  /// In en, this message translates to:
  /// **'Performances'**
  String get performances;

  /// No description provided for @myAlarms.
  ///
  /// In en, this message translates to:
  /// **'My Alarms'**
  String get myAlarms;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @noPerformances.
  ///
  /// In en, this message translates to:
  /// **'No performances found.'**
  String get noPerformances;

  /// No description provided for @noAlarms.
  ///
  /// In en, this message translates to:
  /// **'No alarms set.'**
  String get noAlarms;

  /// No description provided for @noAlarmsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap 🔔 in the list to set an alarm.'**
  String get noAlarmsHint;

  /// No description provided for @serverPreparing.
  ///
  /// In en, this message translates to:
  /// **'Server is waking up'**
  String get serverPreparing;

  /// No description provided for @serverPreparingHint.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment.'**
  String get serverPreparingHint;

  /// No description provided for @retryIn.
  ///
  /// In en, this message translates to:
  /// **'Retrying in {sec}s'**
  String retryIn(int sec);

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry Now'**
  String get retryNow;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get openNow;

  /// No description provided for @daysUntilOpen.
  ///
  /// In en, this message translates to:
  /// **'Opens in {days} days'**
  String daysUntilOpen(int days);

  /// No description provided for @hoursMinutesUntilOpen.
  ///
  /// In en, this message translates to:
  /// **'Opens in {h}h {m}m'**
  String hoursMinutesUntilOpen(int h, int m);

  /// No description provided for @minutesSecondsUntilOpen.
  ///
  /// In en, this message translates to:
  /// **'{m}m {s}s'**
  String minutesSecondsUntilOpen(int m, int s);

  /// No description provided for @alarmOn.
  ///
  /// In en, this message translates to:
  /// **'Alarm ON'**
  String get alarmOn;

  /// No description provided for @alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// No description provided for @setAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Alarm'**
  String get setAlarmTitle;

  /// No description provided for @before10min.
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get before10min;

  /// No description provided for @before1hr.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get before1hr;

  /// No description provided for @before24hr.
  ///
  /// In en, this message translates to:
  /// **'24 hours before'**
  String get before24hr;

  /// No description provided for @alarmSet.
  ///
  /// In en, this message translates to:
  /// **'Alarm set.'**
  String get alarmSet;

  /// No description provided for @alarmCancelled.
  ///
  /// In en, this message translates to:
  /// **'Alarm cancelled.'**
  String get alarmCancelled;

  /// No description provided for @blockedUrl.
  ///
  /// In en, this message translates to:
  /// **'Unsupported Site'**
  String get blockedUrl;

  /// No description provided for @blockedUrlMessage.
  ///
  /// In en, this message translates to:
  /// **'This booking site is not in our verified list.'**
  String get blockedUrlMessage;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing cached data'**
  String get offlineBanner;

  /// No description provided for @interestSettings.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get interestSettings;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @resetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset Preferences'**
  String get resetOnboarding;

  /// No description provided for @resetOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Redo genre & region setup'**
  String get resetOnboardingSubtitle;

  /// No description provided for @hot.
  ///
  /// In en, this message translates to:
  /// **'HOT'**
  String get hot;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free Entry'**
  String get free;

  /// No description provided for @national.
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get national;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
