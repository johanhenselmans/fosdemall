// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Fosdem';

  @override
  String get navEvents => 'Événements';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navTracks => 'Parcours';

  @override
  String get navPersons => 'Intervenants';

  @override
  String get navYears => 'Années';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get titleTracksAllYears => 'parcours de toutes les années';

  @override
  String titleTrackForAllYears(String track) {
    return '$track - parcours pour toutes les années';
  }

  @override
  String get titleFavoritesAllYears => 'favoris de toutes les années';

  @override
  String get titlePersonsAllYears => 'intervenants de toutes les années';

  @override
  String get btnBack => 'Retour';

  @override
  String get btnBackToEvent => 'Retour à l\'événement';

  @override
  String get btnLaunchExternalApp => 'Ouvrir l\'application externe';

  @override
  String get btnOpenVideoExternally => 'Ouvrir la vidéo à l\'extérieur';

  @override
  String get searchEvents => 'Rechercher des événements';

  @override
  String get searchFavorites => 'Rechercher des favoris';

  @override
  String get searchTracks => 'Rechercher des parcours';

  @override
  String get searchPersons => 'Rechercher des intervenants';

  @override
  String get searchConferences => 'Rechercher des conférences';

  @override
  String get loadingEvents => 'Chargement des événements...';

  @override
  String get loadingFavorites => 'Chargement des favoris...';

  @override
  String get loadingTracks => 'Chargement des parcours...';

  @override
  String get loadingPersons => 'Chargement des intervenants...';

  @override
  String get loadingConferences => 'Chargement des conférences...';

  @override
  String get settingFavoritesAllYears =>
      'Afficher les favoris de toutes les années';

  @override
  String get settingTracksAllYears =>
      'Afficher les parcours de toutes les années';

  @override
  String get settingPersonsAllYears =>
      'Afficher les intervenants de toutes les années';

  @override
  String get videoFormatNoticeTitle => 'Avis sur le format vidéo';

  @override
  String get videoFormatNoticeContent =>
      'iOS ne peut lire les vidéos AV1/webm que sur l\'iPhone 15 ou ultérieur. Vous pouvez retourner à l\'événement pour choisir un lien MP4 ou ouvrir la vidéo WebM dans une application externe.';

  @override
  String get noItemsFound => 'Aucun élément trouvé';
}
