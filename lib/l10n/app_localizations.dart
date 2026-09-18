import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

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
    Locale('fr'),
    Locale('nl'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Fosdem'**
  String get appTitle;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get navTracks;

  /// No description provided for @navPersons.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get navPersons;

  /// No description provided for @navYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get navYears;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @titleTracksAllYears.
  ///
  /// In en, this message translates to:
  /// **'tracks of all years'**
  String get titleTracksAllYears;

  /// No description provided for @titleTrackForAllYears.
  ///
  /// In en, this message translates to:
  /// **'{track} - track for all years'**
  String titleTrackForAllYears(String track);

  /// No description provided for @titleFavoritesAllYears.
  ///
  /// In en, this message translates to:
  /// **'favorites of all years'**
  String get titleFavoritesAllYears;

  /// No description provided for @titlePersonsAllYears.
  ///
  /// In en, this message translates to:
  /// **'persons of all years'**
  String get titlePersonsAllYears;

  /// No description provided for @btnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btnBack;

  /// No description provided for @btnBackToEvent.
  ///
  /// In en, this message translates to:
  /// **'Back to Event'**
  String get btnBackToEvent;

  /// No description provided for @btnLaunchExternalApp.
  ///
  /// In en, this message translates to:
  /// **'Launch External App'**
  String get btnLaunchExternalApp;

  /// No description provided for @btnOpenVideoExternally.
  ///
  /// In en, this message translates to:
  /// **'Open Video Externally'**
  String get btnOpenVideoExternally;

  /// No description provided for @searchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search Events'**
  String get searchEvents;

  /// No description provided for @searchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Search Favorites'**
  String get searchFavorites;

  /// No description provided for @searchTracks.
  ///
  /// In en, this message translates to:
  /// **'Search Tracks'**
  String get searchTracks;

  /// No description provided for @searchPersons.
  ///
  /// In en, this message translates to:
  /// **'Search Persons'**
  String get searchPersons;

  /// No description provided for @searchConferences.
  ///
  /// In en, this message translates to:
  /// **'Search Conferences'**
  String get searchConferences;

  /// No description provided for @loadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Loading events...'**
  String get loadingEvents;

  /// No description provided for @loadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Loading favorites...'**
  String get loadingFavorites;

  /// No description provided for @loadingTracks.
  ///
  /// In en, this message translates to:
  /// **'Loading tracks...'**
  String get loadingTracks;

  /// No description provided for @loadingPersons.
  ///
  /// In en, this message translates to:
  /// **'Loading persons...'**
  String get loadingPersons;

  /// No description provided for @loadingConferences.
  ///
  /// In en, this message translates to:
  /// **'Loading conferences...'**
  String get loadingConferences;

  /// No description provided for @settingFavoritesAllYears.
  ///
  /// In en, this message translates to:
  /// **'Display favorites of all years'**
  String get settingFavoritesAllYears;

  /// No description provided for @settingTracksAllYears.
  ///
  /// In en, this message translates to:
  /// **'Display tracks of all years'**
  String get settingTracksAllYears;

  /// No description provided for @settingPersonsAllYears.
  ///
  /// In en, this message translates to:
  /// **'Display persons of all years'**
  String get settingPersonsAllYears;

  /// No description provided for @videoFormatNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Format Notice'**
  String get videoFormatNoticeTitle;

  /// No description provided for @videoFormatNoticeContent.
  ///
  /// In en, this message translates to:
  /// **'iOS can only play AV1/webm on iPhone 15 or later. You can choose to go back to the event for an MP4 link or launch the WebM video in an external app or browser.'**
  String get videoFormatNoticeContent;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;
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
      <String>['en', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
