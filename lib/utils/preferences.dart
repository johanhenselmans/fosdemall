import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static final Preferences _instance = Preferences.internal();

  Preferences.internal();

  factory Preferences() => _instance;

  late SharedPreferences prefs;
  bool? soundEnabled;
  bool? updatedToSQL;
  bool? useTestSite;
  int? currentYear;
  int? selectedYear;

  Future<void> loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool('SoundEnabled');
    updatedToSQL = prefs.getBool('updatedToSQL');
    useTestSite = prefs.getBool('useTestSite');
    currentYear = prefs.getInt('currentYear');
    selectedYear = prefs.getInt('selectedYear');
  }

  bool? getSoundEnabled() {
    soundEnabled = prefs.getBool('SoundEnabled');
    return soundEnabled;
  }

  void setSoundEnabled(bool newvalue) {
    prefs.setBool('SoundEnabled', newvalue);
  }


  void setCurrentYear(int newvalue) {
    prefs.setInt('currentYear', newvalue);
  }

  int? getCurrentYear() {
    currentYear = prefs.getInt('currentYear');
    return currentYear;
  }

  int? getSelectedYear() {
    selectedYear = prefs.getInt('selectedYear');
    return selectedYear;
  }

  void setSelectedYear(int newvalue) {
    prefs.setInt('selectedYear', newvalue);
  }

  bool? getUpdatedToSQL() {
    updatedToSQL = prefs.getBool('updatedToSQL');
    return updatedToSQL;
  }

  void setUpdatedToSQL(bool newvalue) {
    prefs.setBool('updatedToSQL', newvalue);
  }

  bool? getUseTestSite() {
    updatedToSQL = prefs.getBool('useTestSite');
    return updatedToSQL;
  }

  void setUseTestSite(bool newvalue) {
    prefs.setBool('useTestSite', newvalue);
  }

  bool getInitialPersonsScraped() {
    try {
      return prefs.getBool('initialPersonsScraped') ?? false;
    } catch (_) {
      return false;
    }
  }

  void setInitialPersonsScraped(bool newvalue) async {
    try {
      prefs.setBool('initialPersonsScraped', newvalue);
    } catch (_) {
      final sp = await SharedPreferences.getInstance();
      sp.setBool('initialPersonsScraped', newvalue);
    }
  }

}
