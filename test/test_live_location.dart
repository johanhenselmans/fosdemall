import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/screens/location_view.dart';
import 'package:fosdem/utils/room_locations.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/settings_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('Live Location Distance Calculation Tests', () {
    test('Calculates distance from user position to campus buildings accurately', () {
      const distance = Distance();

      // User standing near Solbosch tram stop (50.81244, 4.37921)
      const userPos = LatLng(50.81244, 4.37921);

      // Distance to Building J (Janson)
      final metersToJ = distance.as(LengthUnit.Meter, userPos, RoomLocationHelper.buildingJCoordinates);
      expect(metersToJ, greaterThan(50));
      expect(metersToJ, lessThan(120));

      // Distance to Building K
      final metersToK = distance.as(LengthUnit.Meter, userPos, RoomLocationHelper.buildingKCoordinates);
      expect(metersToK, greaterThan(200));
      expect(metersToK, lessThan(400));

      // Distance formatting logic
      String formatDistance(double meters) {
        if (meters < 1000) {
          return '${meters.round()} m away';
        } else {
          return '${(meters / 1000).toStringAsFixed(1)} km away';
        }
      }

      expect(formatDistance(85.3), equals('85 m away'));
      expect(formatDistance(1250.0), equals('1.3 km away'));
    });
  });

  group('LocationView Live Location UI Tests', () {
    testWidgets('Renders LocationView with My Location button and map controls', (WidgetTester tester) async {
      final controller = SettingsController(SettingsService());
      await controller.loadSettings();

      final event = Event('');
      event.title = 'Building K Talk';
      event.room = 'K.1.105 (La Fontaine)';

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
      expect(find.text('Room: K.1.105 (La Fontaine)'), findsWidgets);
      expect(find.textContaining('Building K'), findsWidgets);

      // Check "My Location" FloatingActionButton
      expect(find.byTooltip('My Location'), findsOneWidget);
      expect(find.byIcon(Icons.location_searching), findsOneWidget);

      // Check navigation buttons in card
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('OSM'), findsOneWidget);
    });
  });
}
