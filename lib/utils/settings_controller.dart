import 'package:flutter/material.dart' show ChangeNotifier, ThemeMode;
import 'package:fosdem/models/event.dart';

import 'package:fosdem/utils/settings_service.dart' show SettingsService;

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class SettingsController with ChangeNotifier {

  SettingsController(this._settingsService);

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService _settingsService;

  // Make ThemeMode a private variable so it is not updated directly without
  // also persisting the changes with the SettingsService.
  late ThemeMode _themeMode;

  // Allow Widgets to read the user's preferred ThemeMode.
  ThemeMode get themeMode => _themeMode;

  late String _fosdemSelectedYear;
  String get fosdemSelectedYear => _fosdemSelectedYear;
  late String _fosdemCurrentYear;
  String get fosdemCurrentYear => _fosdemCurrentYear;
  late String _searchEvent = '';
  String get searchEvent => _searchEvent;
  late final String _searchTrack = '';
  String get searchTrack => _searchTrack;
  late Event _SelectedEvent;
  Event get SelectedEvent => _SelectedEvent;
  late String _SelectedVideo;
  String get SelectedVideo => _SelectedVideo;
  String _SelectedTrack = '';
  String get SelectedTrack => _SelectedTrack;
  bool _selectedTracksFromAllYears = false;
  bool get selectedTracksFromAllYears => _selectedTracksFromAllYears;
  bool _selectedFavoritesFromAllYears = false;
  bool get selectedFavoritesFromAllYears => _selectedFavoritesFromAllYears;
  bool _selectedNow = false;
  bool get selectedNow => _selectedNow;

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _fosdemSelectedYear = (await _settingsService.getSelectedYear())!;

    _fosdemCurrentYear = (await _settingsService.getCurrentYear())!;
//    _selectedEvent = (await _settingsService.getSelectedEvent())!;
    // Important! Inform listeners a change has occurred.
    _selectedTracksFromAllYears = (await _settingsService.getSelectedTracksOffAllYears())!;
    _selectedFavoritesFromAllYears = (await _settingsService.getSelectedFavoritesOffAllYears())!;
    _selectedNow = (await _settingsService.getNow())!;
    notifyListeners();
  }

  /// Update and persist the seearchEvent.
  Future<void> updateSearchEvent(String? anEvent) async {
    if (anEvent == null) return;
    //if (newFosdemPassword == null) return;

    // Otherwise, store the new fosdemWifiName in memory
    _searchEvent = anEvent;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    //await _settingsService.updateSelectedYear(aYear);
  }


  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    // Do not perform any work if new and old ThemeMode are identical
    if (newThemeMode == _themeMode) return;

    // Otherwise, store the new ThemeMode in memory
    _themeMode = newThemeMode;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateThemeMode(newThemeMode);
  }

  /// Update and persist the SelectedEvent.
  Future<void> updateSelectedEvent(Event? anEvent) async {
    if (anEvent == null) return;
    //if (newFosdemPassword == null) return;

    // Otherwise, store the new fosdemWifiName in memory
    _SelectedEvent = anEvent;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    // await _settingsService.updateSelectedEvent(anEvent);
  }

  /// Update and persist the SelectedTrack.
  Future<void> updateSelectedTrack(String? aTrack) async {
    if (aTrack == null) return;
    //if (newFosdemPassword == null) return;

    // Otherwise, store the new fosdemWifiName in memory
    _SelectedTrack = aTrack;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    // await _settingsService.updateSelectedTrack(aTrack);
  }


  /// Update and persist the SelectedVideo.
  Future<void> updateSelectedVideo(String? aVideoURL) async {
    if (aVideoURL == null) return;
    //if (newFosdemPassword == null) return;

    // Otherwise, store the new fosdemWifiName in memory
    _SelectedVideo = aVideoURL;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    // await _settingsService.updateSelectedEvent(anEvent);
  }



  /// Update and persist the SelectedYear.
  Future<void> updateSelectedYear(String? aYear) async {
    if (aYear == null) return;
    //if (newFosdemPassword == null) return;

    // Otherwise, store the new fosdemWifiName in memory
    _fosdemSelectedYear = aYear;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateSelectedYear(aYear);
  }
  Future<void> updateCurrentYear(String? aYear) async {
    if (aYear == null) return;
    //if (newFosdemPassword == null) return;

    // Otherwise, store the new fosdemWifiName in memory
    _fosdemCurrentYear = aYear;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateCurrentYear(aYear);
  }

  Future<void> updateSelectedTracksOfAllYears(bool? aBool) async {
    if (aBool == null) return;
    //if (newFosdemPassword == null) return;

    // Otherwise, store the new fosdemWifiName in memory
    _selectedTracksFromAllYears = aBool;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateSelectedTracksOffAllYears(aBool);
  }

  Future<void> updateSelectedFavoritesOfAllYears(bool? aBool) async {
    if (aBool == null) return;

    // Otherwise, store the new value in memory
    _selectedFavoritesFromAllYears = aBool;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateSelectedFavoritesOffAllYears(aBool);
  }

  Future<void> updateNow(bool? aBool) async {
    if (aBool == null) return;

    // Otherwise, store the new value in memory
    _selectedNow = aBool;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await _settingsService.updateNow(aBool);
  }



}
