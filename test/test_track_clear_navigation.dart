import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem/screens/scaffold.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/settings_service.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  testWidgets('Moving to another menu item clears SelectedTrack', (WidgetTester tester) async {
    final settingsController = SettingsController(SettingsService());
    await settingsController.loadSettings();

    // Set a selected track
    await settingsController.updateSelectedTrack('Python');
    expect(settingsController.SelectedTrack, equals('Python'));

    final router = GoRouter(
      initialLocation: '/eventlist',
      routes: [
        GoRoute(
          path: '/:tab(eventlist|favoriteslist|tracklist|personlist|conferencelist|settings)',
          builder: (context, state) {
            final tab = ScaffoldTab.values.firstWhere(
                (e) => e.toString() == 'ScaffoldTab.${state.pathParameters['tab']!}');
            return FosdemScaffold(
              selectedTab: tab,
              settingsController: settingsController,
              child: Text('Content for ${state.pathParameters['tab']}'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial state: on eventlist with track 'Python'
    expect(find.text('Content for eventlist'), findsOneWidget);
    expect(settingsController.SelectedTrack, equals('Python'));

    // Tap 'Favorites' (index 1)
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    // Verify track selection was cleared and we moved to favoriteslist
    expect(settingsController.SelectedTrack, equals(''));
    expect(find.text('Content for favoriteslist'), findsOneWidget);

    // Set track again
    await settingsController.updateSelectedTrack('Rust');
    expect(settingsController.SelectedTrack, equals('Rust'));

    // Tap 'Tracks' (index 2)
    await tester.tap(find.text('Tracks'));
    await tester.pumpAndSettle();

    expect(settingsController.SelectedTrack, equals(''));
    expect(find.text('Content for tracklist'), findsOneWidget);

    // Set track again and tap 'Events' (index 0) to clear it directly
    await settingsController.updateSelectedTrack('Go');
    expect(settingsController.SelectedTrack, equals('Go'));

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(settingsController.SelectedTrack, equals(''));
    expect(find.text('Content for eventlist'), findsOneWidget);
  });
}
