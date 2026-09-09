import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keySelectedYear = 'selectedyear';
  static const _keyCurrentYear = 'currentyear';
  static const _keySelectedTrackOffAllYears = 'selectedtracksofallyears';
  static const _keySelectedFavoritesOffAllYears = 'selectedfavoritesofallyears';
  static const _keyNow = 'now';



  static const _keySelectedPersonsOffAllYears = 'selectedpersonsofallyears';
  static const _keySelectedEventsOffAllYears = 'selectedeventsofallyears';

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
    if (tmpvalue == null) return false;
    return bool.tryParse(tmpvalue) ?? (tmpvalue.toLowerCase() == 'true');
  }

  static Future setSelectedFavoritesOfAllYears(bool value) async {
    await _storage.write(key: _keySelectedFavoritesOffAllYears, value: value.toString());
  }

  static Future<bool?> getSelectedFavoritesOfAllYears() async {
    var tmpvalue = await _storage.read(key: _keySelectedFavoritesOffAllYears);
    if (tmpvalue == null) return false;
    return bool.tryParse(tmpvalue) ?? (tmpvalue.toLowerCase() == 'true');
  }

  static Future setSelectedPersonsOfAllYears(bool value) async {
    await _storage.write(key: _keySelectedPersonsOffAllYears, value: value.toString());
  }

  static Future<bool?> getSelectedPersonsOfAllYears() async {
    var tmpvalue = await _storage.read(key: _keySelectedPersonsOffAllYears);
    if (tmpvalue == null) return false;
    return bool.tryParse(tmpvalue) ?? (tmpvalue.toLowerCase() == 'true');
  }

  static Future setSelectedEventsOfAllYears(bool value) async {
    await _storage.write(key: _keySelectedEventsOffAllYears, value: value.toString());
  }

  static Future<bool?> getSelectedEventsOfAllYears() async {
    var tmpvalue = await _storage.read(key: _keySelectedEventsOffAllYears);
    if (tmpvalue == null) return false;
    return bool.tryParse(tmpvalue) ?? (tmpvalue.toLowerCase() == 'true');
  }

  static Future setNow(bool value) async {
    await _storage.write(key: _keyNow, value: value.toString());
  }

  static Future<bool?> getNow() async {
    var tmpvalue = await _storage.read(key: _keyNow);
    if (tmpvalue == null) return false;
    return bool.tryParse(tmpvalue) ?? (tmpvalue.toLowerCase() == 'true');
  }
}
