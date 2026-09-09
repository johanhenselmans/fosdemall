import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/settings_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Event createEvent({
  required String title,
  required String room,
  String track = '',
  int year = 2024,
}) {
  final e = Event('');
  e.title = title;
  e.room = room;
  e.track = track;
  e.year = year;
  return e;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '/Users/localadmin/Documents';
  });

  test('Event search filter matches room/location (e.g., Janson)', () {
    final event1 = createEvent(title: 'Keynote Welcome', room: 'Janson', track: 'Main', year: 2024);
    final event2 = createEvent(title: 'Python Web Frameworks', room: 'K.1.105 (La Fontaine)', track: 'Python', year: 2024);
    final event3 = createEvent(title: 'Rust in Linux Kernel', room: 'Janson', track: 'Rust', year: 2024);
    final event4 = createEvent(title: 'Opening Closing Words', room: 'Janson (Auditorium)', track: 'Main', year: 2024);
    final event5 = createEvent(title: 'PostgreSQL Internals', room: 'UB2.252A (Lameere)', track: 'PostgreSQL', year: 2023);

    final allEvents = [event1, event2, event3, event4, event5];

    // Filter function as implemented in eventlist.dart and favoriteslist.dart
    List<Event> filterEvents(String query, List<Event> list) {
      final q = query.toLowerCase();
      return list.where((element) {
        final title = element.title.toLowerCase();
        final track = element.track?.toLowerCase() ?? '';
        final yearStr = element.year?.toString() ?? '';
        final room = element.room?.toLowerCase() ?? '';
        return title.contains(q) ||
            track.contains(q) ||
            yearStr.contains(q) ||
            room.contains(q);
      }).toList();
    }

    // 1. Search with exact case "Janson"
    final resultsJanson = filterEvents('Janson', allEvents);
    expect(resultsJanson, containsAll([event1, event3, event4]));
    expect(resultsJanson, isNot(contains(event2)));
    expect(resultsJanson, isNot(contains(event5)));
    expect(resultsJanson.length, equals(3));

    // 2. Case-insensitive search "janson"
    final resultsLower = filterEvents('janson', allEvents);
    expect(resultsLower.length, equals(3));
    expect(resultsLower, containsAll([event1, event3, event4]));

    // 3. Case-insensitive search uppercase "JANSON"
    final resultsUpper = filterEvents('JANSON', allEvents);
    expect(resultsUpper.length, equals(3));
    expect(resultsUpper, containsAll([event1, event3, event4]));

    // 4. Search partial room name "La Fontaine"
    final resultsFontaine = filterEvents('La Fontaine', allEvents);
    expect(resultsFontaine.length, equals(1));
    expect(resultsFontaine.first, equals(event2));

    // 5. Search non-matching room
    final resultsNone = filterEvents('NonExistentRoom', allEvents);
    expect(resultsNone, isEmpty);
  });

  test('Integration test: Searching 2024 events in DB for Janson room', () async {
    final helper = DatabaseHelper();
    final controller = SettingsController(SettingsService());
    await controller.loadSettings();
    await controller.updateSelectedEventsOfAllYears(false);

    final events2024 = await helper.getEventsFromDb(
      2024,
      false,
      settingsController: controller,
    );
    expect(events2024, isNotEmpty);

    final q = 'janson';
    final jansonEvents = events2024.where((element) {
      final title = element.title.toLowerCase();
      final track = element.track?.toLowerCase() ?? '';
      final yearStr = element.year?.toString() ?? '';
      final room = element.room?.toLowerCase() ?? '';
      return title.contains(q) ||
          track.contains(q) ||
          yearStr.contains(q) ||
          room.contains(q);
    }).toList();

    expect(jansonEvents.length, equals(23));
    for (var ev in jansonEvents) {
      expect(ev.room?.toLowerCase(), contains('janson'));
    }
  });
}
