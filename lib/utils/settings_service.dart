import 'package:flutter/material.dart';
import 'settings_secure_storage.dart';

/// A service that stores and retrieves user settings.
///
/// By default, this class does not persist user settings. If you'd like to
/// persist the user settings locally, use the shared_preferences package. If
/// you'd like to store settings on a web server, use the http package.
class SettingsService {
  /// Loads the User's preferred ThemeMode from local or remote storage.
  Future<ThemeMode> themeMode() async => ThemeMode.system;

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
  }


  Future<String?> getSelectedYear() async {
    return UserSecureStorage.getSelectedYear();
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateSelectedYear(String ayear) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    UserSecureStorage.setSelectedYear(ayear);
  }


  Future<String?> getCurrentYear() async {
    return UserSecureStorage.getCurrentYear();
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateCurrentYear(String ayear) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    UserSecureStorage.setCurrentYear(ayear);
  }


  Future<bool?> getSelectedTracksOffAllYears() async {
    return UserSecureStorage.getSelectedTrackOfAllYears();
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateSelectedTracksOffAllYears(bool avalue) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    UserSecureStorage.setSelectedTrackOfAllYears(avalue);
  }

  Future<bool?> getSelectedFavoritesOffAllYears() async {
    return UserSecureStorage.getSelectedFavoritesOfAllYears();
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateSelectedFavoritesOffAllYears(bool avalue) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    UserSecureStorage.setSelectedFavoritesOfAllYears(avalue);
  }

  Future<bool?> getSelectedPersonsOffAllYears() async {
    return UserSecureStorage.getSelectedPersonsOfAllYears();
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateSelectedPersonsOffAllYears(bool avalue) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    UserSecureStorage.setSelectedPersonsOfAllYears(avalue);
  }

  Future<bool?> getSelectedEventsOffAllYears() async {
    return UserSecureStorage.getSelectedEventsOfAllYears();
  }

  /// Persists the user's preferred events of all years setting.
  Future<void> updateSelectedEventsOffAllYears(bool avalue) async {
    UserSecureStorage.setSelectedEventsOfAllYears(avalue);
  }

  Future<bool?> getNow() async {
    return UserSecureStorage.getNow();
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateNow(bool avalue) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
    UserSecureStorage.setNow(avalue);
  }
}
