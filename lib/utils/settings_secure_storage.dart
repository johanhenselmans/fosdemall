import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keySelectedYear = 'selectedyear';
  static const _keyCurrentYear = 'currentyear';
  static const _keySelectedTrackOffAllYears = 'selectedtracksofallyears';
  static const _keySelectedFavoritesOffAllYears = 'selectedfavoritesofallyears';
  static const _keyNow = 'now';



  static Future setSelectedYear(String value) async {
    await _storage.write(key: _keySelectedYear, value: value);
  }

  static Future<String?> getSelectedYear() async {
    final value = await _storage.read(key: _keySelectedYear);
    return value ?? "";
  }

  static Future setCurrentYear(String value) async {
    await _storage.write(key: _keyCurrentYear, value: value);
  }

  static Future<String?> getCurrentYear() async {
    final value = await _storage.read(key: _keyCurrentYear);
    return value ?? "";
  }

  static Future setSelectedTrackOfAllYears(bool value) async {
    await _storage.write(key: _keySelectedTrackOffAllYears, value: value.toString());
  }

  static Future<bool?> getSelectedTrackOfAllYears() async {
    var tmpvalue = await _storage.read(key: _keySelectedTrackOffAllYears);
    tmpvalue ??= "false";
    bool value = bool.fromEnvironment(tmpvalue, defaultValue: false);
    return value;
  }

  static Future setSelectedFavoritesOfAllYears(bool value) async {
    await _storage.write(key: _keySelectedFavoritesOffAllYears, value: value.toString());
  }

  static Future<bool?> getSelectedFavoritesOfAllYears() async {
    var tmpvalue = await _storage.read(key: _keySelectedTrackOffAllYears);
    tmpvalue ??= "false";
    bool value = bool.fromEnvironment(tmpvalue, defaultValue: false);
    return value;
  }

  static Future setNow(bool value) async {
    await _storage.write(key: _keyNow, value: value.toString());
  }

  static Future<bool?> getNow() async {
    var tmpvalue = await _storage.read(key: _keyNow);
    tmpvalue ??= "false";
    bool value = bool.fromEnvironment(tmpvalue, defaultValue: false);
    return value;
  }

}
