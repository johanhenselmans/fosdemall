import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/screens/location_view.dart';
import 'package:fosdem/utils/room_locations.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('RoomLocationHelper Tests', () {
    test('Resolves Janson room correctly', () {
      final info = RoomLocationHelper.getLocationInfo('Janson');
      expect(info.buildingCode, equals('J'));
      expect(info.buildingName, contains('Auditoire Paul-Émile Janson'));
      expect(info.coordinates.latitude, closeTo(50.8131, 0.001));
      expect(info.coordinates.longitude, closeTo(4.3794, 0.001));
      expect(info.roomAssetPath, equals('assets/maps/Janson.png'));
      expect(info.campusAssetPath, equals('assets/maps/ulb_solbosch.png'));
    });

    test('Resolves Building K rooms correctly', () {
      final info1 = RoomLocationHelper.getLocationInfo('K.1.105 (La Fontaine)');
      expect(info1.buildingCode, equals('K'));
      expect(info1.roomAssetPath, equals('assets/maps/K.1.105 (La Fontaine).png'));

      final info2 = RoomLocationHelper.getLocationInfo('K.3.201');
      expect(info2.buildingCode, equals('K'));
      expect(info2.roomAssetPath, equals('assets/maps/K.3.201.png'));
    });

    test('Resolves Building H rooms correctly', () {
      final info1 = RoomLocationHelper.getLocationInfo('H.1302 (Depage)');
      expect(info1.buildingCode, equals('H'));
      expect(info1.roomAssetPath, equals('assets/maps/H.1302 (Depage).png'));

      final info2 = RoomLocationHelper.getLocationInfo('Ferrer');
      expect(info2.buildingCode, equals('H'));
      expect(info2.roomAssetPath, isNotNull);
    });

    test('Resolves Building U rooms correctly', () {
      final info1 = RoomLocationHelper.getLocationInfo('UB2.252A (Lameere)');
      expect(info1.buildingCode, equals('U'));
      expect(info1.roomAssetPath, equals('assets/maps/UB2.252A (Lameere).png'));

      final info2 = RoomLocationHelper.getLocationInfo('Chavanne');
      expect(info2.buildingCode, equals('U'));
      expect(info2.roomAssetPath, isNotNull);
    });

    test('Resolves Building AW rooms correctly', () {
      final info = RoomLocationHelper.getLocationInfo('AW1.120');
      expect(info.buildingCode, equals('AW'));
      expect(info.roomAssetPath, equals('assets/maps/AW1.120.png'));
    });

    test('Handles unknown and online rooms with fallback campus center', () {
      final info = RoomLocationHelper.getLocationInfo('D.python');
      expect(info.buildingCode, equals('Campus'));
      expect(info.roomAssetPath, isNull);
      expect(info.campusAssetPath, equals('assets/maps/ulb_solbosch.png'));
    });

    test('Generates valid map and navigation URLs', () {
      final info = RoomLocationHelper.getLocationInfo('Janson');
      expect(info.openStreetMapUrl, contains('https://www.openstreetmap.org/?mlat=50.8131'));
      expect(info.openStreetMapDirectionsUrl, contains('https://www.openstreetmap.org/directions'));
      expect(info.googleMapsDirectionsUrl, contains('https://www.google.com/maps/dir'));
      expect(info.appleMapsDirectionsUrl, contains('https://maps.apple.com'));
      expect(info.geoUri.scheme, equals('geo'));
    });
  });

  group('LocationView Widget Tests', () {
    testWidgets('Renders LocationView with OSM, Room Plan, and Campus Map tabs', (WidgetTester tester) async {
      final controller = SettingsController(SettingsService());
      await controller.loadSettings();

      final event = Event('');
      event.title = 'Keynote';
      event.room = 'Janson';

      await tester.pumpWidget(
        MaterialApp(
          home: LocationView(
            event: event,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header info
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Room: Janson'), findsWidgets);
      expect(find.textContaining('Auditoire Paul-Émile Janson'), findsWidgets);

      // Check tabs
      expect(find.text('OpenStreetMap'), findsOneWidget);
      expect(find.text('Room Plan'), findsOneWidget);
      expect(find.text('Campus Map'), findsOneWidget);

      // Check action buttons in OSM tab
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('OSM'), findsOneWidget);

      // Tap 'Room Plan' tab
      await tester.tap(find.text('Room Plan'));
      await tester.pumpAndSettle();
      expect(find.text('Room Floor Plan: Janson'), findsOneWidget);

      // Tap 'Campus Map' tab
      await tester.tap(find.text('Campus Map'));
      await tester.pumpAndSettle();
      expect(find.text('ULB Solbosch Campus Terrain'), findsOneWidget);
    });
  });
}
