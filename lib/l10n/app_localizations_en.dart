// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fosdem';

  @override
  String get navEvents => 'Events';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navTracks => 'Tracks';

  @override
  String get navPersons => 'Persons';

  @override
  String get navYears => 'Years';

  @override
  String get navSettings => 'Settings';

  @override
  String get titleTracksAllYears => 'tracks of all years';

  @override
  String titleTrackForAllYears(String track) {
    return '$track - track for all years';
  }

  @override
  String get titleFavoritesAllYears => 'favorites of all years';

  @override
  String get titlePersonsAllYears => 'persons of all years';

  @override
  String get btnBack => 'Back';

  @override
  String get btnBackToEvent => 'Back to Event';

  @override
  String get btnLaunchExternalApp => 'Launch External App';

  @override
  String get btnOpenVideoExternally => 'Open Video Externally';

  @override
  String get searchEvents => 'Search Events';

  @override
  String get searchFavorites => 'Search Favorites';

  @override
  String get searchTracks => 'Search Tracks';

  @override
  String get searchPersons => 'Search Persons';

  @override
  String get searchConferences => 'Search Conferences';

  @override
  String get loadingEvents => 'Loading events...';

  @override
  String get loadingFavorites => 'Loading favorites...';

  @override
  String get loadingTracks => 'Loading tracks...';

  @override
  String get loadingPersons => 'Loading persons...';

  @override
  String get loadingConferences => 'Loading conferences...';

  @override
  String get settingFavoritesAllYears => 'Display favorites of all years';

  @override
  String get settingTracksAllYears => 'Display tracks of all years';

  @override
  String get settingPersonsAllYears => 'Display persons of all years';

  @override
  String get videoFormatNoticeTitle => 'Video Format Notice';

  @override
  String get videoFormatNoticeContent =>
      'iOS can only play AV1/webm on iPhone 15 or later. You can choose to go back to the event for an MP4 link or launch the WebM video in an external app or browser.';

  @override
  String get noItemsFound => 'No items found';
}
