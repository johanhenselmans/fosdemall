// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Fosdem';

  @override
  String get navEvents => 'Evenementen';

  @override
  String get navFavorites => 'Favorieten';

  @override
  String get navTracks => 'Tracks';

  @override
  String get navPersons => 'Sprekers';

  @override
  String get navYears => 'Jaren';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get titleTracksAllYears => 'tracks van alle jaren';

  @override
  String titleTrackForAllYears(String track) {
    return '$track - track voor alle jaren';
  }

  @override
  String get titleFavoritesAllYears => 'favorieten van alle jaren';

  @override
  String get titlePersonsAllYears => 'sprekers van alle jaren';

  @override
  String get btnBack => 'Terug';

  @override
  String get btnBackToEvent => 'Terug naar evenement';

  @override
  String get btnLaunchExternalApp => 'Externe app openen';

  @override
  String get btnOpenVideoExternally => 'Video extern openen';

  @override
  String get searchEvents => 'Zoek evenementen';

  @override
  String get searchFavorites => 'Zoek favorieten';

  @override
  String get searchTracks => 'Zoek tracks';

  @override
  String get searchPersons => 'Zoek sprekers';

  @override
  String get searchConferences => 'Zoek conferenties';

  @override
  String get loadingEvents => 'Evenementen laden...';

  @override
  String get loadingFavorites => 'Favorieten laden...';

  @override
  String get loadingTracks => 'Tracks laden...';

  @override
  String get loadingPersons => 'Sprekers laden...';

  @override
  String get loadingConferences => 'Conferenties laden...';

  @override
  String get settingFavoritesAllYears => 'Toon favorieten van alle jaren';

  @override
  String get settingTracksAllYears => 'Toon tracks van alle jaren';

  @override
  String get settingPersonsAllYears => 'Toon sprekers van alle jaren';

  @override
  String get videoFormatNoticeTitle => 'Videoformaat melding';

  @override
  String get videoFormatNoticeContent =>
      'iOS kan alleen AV1/webm afspelen op iPhone 15 of nieuwer. U kunt teruggaan naar het evenement voor een MP4-link of de WebM-video in een externe app of browser openen.';

  @override
  String get noItemsFound => 'Geen items gevonden';
}
