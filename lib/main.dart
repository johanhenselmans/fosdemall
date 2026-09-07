import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/models/event.dart';
import 'package:fosdem/screens/conferencelist.dart';
import 'package:fosdem/screens/debug_page.dart';
import 'package:fosdem/screens/event_view.dart';
import 'package:fosdem/screens/eventlist.dart';
import 'package:fosdem/screens/favoriteslist.dart';
import 'package:fosdem/screens/scaffold.dart';
import 'package:fosdem/screens/settings_view.dart';
import 'package:fosdem/screens/tracklist.dart';
import 'package:fosdem/screens/viewvideo.dart';
import 'package:fosdem/utils/preferences.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/settings_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SettingsController settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // set the preferences
  Preferences prefs = Preferences();
  await prefs.loadPreferences();

  DateTime now = DateTime.now();
  int currentyear = now.year;
  await settingsController.updateCurrentYear(currentyear.toString());
  await settingsController.updateSelectedYear(currentyear.toString());
//  XMLDatasource datasource = XMLDatasource();
//  await datasource.getEvents(MAINURL, currentyear.toString());
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)  {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
    // this step, it will use the sqlite version available on the system.
    databaseFactory = databaseFactoryFfi;
  }
  DatabaseHelper dbhelper = DatabaseHelper();
  WidgetsFlutterBinding.ensureInitialized();

  dbhelper.updateEventsFromInternet(year: currentyear.toString());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProxyProvider<DatabaseHelper, Event>(
            create: (context) => Event(""),
            update: (context, dbhelper, event) {
              if (event == null) throw ArgumentError.notNull('event');
              return event;
            }),
        ChangeNotifierProvider(create: (context) => Event("")),
        ChangeNotifierProxyProvider<Event, DatabaseHelper>(
            create: (context) => DatabaseHelper(),
            update: (context, event, databasehelper) {
              if (databasehelper == null) {
                throw ArgumentError.notNull('databasehelper');
              }
              return databasehelper;
            }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: App(settingsController: settingsController),
      ),
    ),
  );
}

class App extends StatefulWidget {
  final SettingsController settingsController;

  const App({
    super.key,
    required this.settingsController,
  });

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // todo: implement restoreState for you app
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _getSelectedTabPage(ScaffoldTab tab) {
    switch (tab) {
      case ScaffoldTab.eventlist:
        return EventList(
          settingsController: widget.settingsController,
        );
      case ScaffoldTab.favoriteslist:
        return FavoritesList(
          settingsController: widget.settingsController,
        );
      case ScaffoldTab.tracklist:
        return TrackList(settingsController: widget.settingsController);
      case ScaffoldTab.conferencelist:
        return ConferenceList(settingsController: widget.settingsController);
      case ScaffoldTab.settings:
        return SettingsView(controller: widget.settingsController);
    }
//    return EventList(
    //     settingsController: widget.settingsController,
    //   );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Fosdem',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'app',
      localizationsDelegates:  AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      // restorationId set for the route automatically
      GoRoute(
        path:
            '/:tab(eventlist|favoriteslist|tracklist|conferencelist|settings)',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final tab = ScaffoldTab.values.firstWhere(
              (e) => e.toString() == 'ScaffoldTab.${state.pathParameters['tab']!}');
          final selectedTabPage = _getSelectedTabPage(tab);
          return MaterialPage<void>(
            key: state.pageKey,
            // 3
            child: FosdemScaffold(
              selectedTab: tab,
              settingsController: widget.settingsController,
              child: selectedTabPage,
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
              path: 'eventview',
              builder: (BuildContext context, GoRouterState state) {
                return EventView(
                    event: widget.settingsController.SelectedEvent,
                    controller: widget.settingsController);
              })
        ],
      ),
      GoRoute(
          path: '/eventview',
          builder: (BuildContext context, GoRouterState state) {
            return EventView(
                event: widget.settingsController.SelectedEvent,
                controller: widget.settingsController);
          }),
      GoRoute(
          path: '/viewvideo',
          builder: (BuildContext context, GoRouterState state) {
            return ViewVideo(
                videoURL: widget.settingsController.SelectedVideo,
                settingscontroller: widget.settingsController);
          }),
      GoRoute(
          path: '/debug',
          builder: (BuildContext context, GoRouterState state) {
            return DebugPage(controller:  widget.settingsController);

          })
    ],
    // redirect to the login page if the user is not logged in
    redirect: (BuildContext context, GoRouterState state) {
      if (state.uri.toString() == '' || state.uri.toString() == '/') {
        return '/eventlist';
      }
      // no need to redirect at all
      return null;
    },
  );
}
