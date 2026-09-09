import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/settings_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '/Users/localadmin/Documents';
  });

  test('Test getEventsFromDb with selectedEventsFromAllYears', () async {
    final helper = DatabaseHelper();
    final controller = SettingsController(SettingsService());
    await controller.loadSettings();

    // 1. Single year query (2025)
    await controller.updateSelectedEventsOfAllYears(false);
    expect(controller.selectedEventsFromAllYears, isFalse);

    final events2025 = await helper.getEventsFromDb(
      2025,
      false,
      settingsController: controller,
    );
    expect(events2025, isNotEmpty);
    for (var ev in events2025.take(50)) {
      expect(ev.year, equals(2025));
    }
    print('2025 events count: ${events2025.length}');

    // 2. All years query
    await controller.updateSelectedEventsOfAllYears(true);
    expect(controller.selectedEventsFromAllYears, isTrue);

    final allEvents = await helper.getEventsFromDb(
      2025,
      false,
      settingsController: controller,
    );
    expect(allEvents.length, greaterThan(events2025.length));

    final yearsFound = allEvents.map((e) => e.year).toSet();
    print('All years events count: ${allEvents.length}, distinct years: $yearsFound');
    expect(yearsFound.length, greaterThan(1));
  });
}
