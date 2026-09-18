// Copyright 2021, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fosdem/l10n/app_localizations.dart';
import 'package:fosdem/utils/style.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/widgets/fosdem_app_bar.dart';

/// The enum for scaffold tab.
enum ScaffoldTab {eventlist, favoriteslist, tracklist, personlist, conferencelist, settings }

class FosdemScaffold extends StatelessWidget {
  const FosdemScaffold({
    required this.selectedTab,
    required this.child,
    required this.settingsController,
    super.key,
  });

  final ScaffoldTab selectedTab;
  final Widget child;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final routeState = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(routeState);
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, _) {
        final title = _getTitle(selectedTab, settingsController, l10n);
        return Scaffold(
          body: Stack(
            children: [
              Container(
                padding: EdgeInsets.only(top: AppBar().preferredSize.height),
                child: child,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FosdemAppBar(title),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex,
            onTap: (int value) => _onItemTapped(value, context),
            selectedItemColor: bottomNavigationBarSelectedItemColor,
            unselectedItemColor: bottomNavigationBarUnselectedItemColor,
            items: [
              BottomNavigationBarItem(
                label: l10n?.navEvents ?? 'Events',
                icon: const Icon(Icons.chat_outlined),
              ),
              BottomNavigationBarItem(
                label: l10n?.navFavorites ?? 'Favorites',
                icon: const Icon(Icons.favorite),
              ),
              BottomNavigationBarItem(
                label: l10n?.navTracks ?? 'Tracks',
                icon: const Icon(Icons.add_road),
              ),
              BottomNavigationBarItem(
                label: l10n?.navPersons ?? 'Persons',
                icon: const Icon(Icons.people),
              ),
              BottomNavigationBarItem(
                label: l10n?.navYears ?? 'Years',
                icon: const Icon(Icons.view_agenda),
              ),
              BottomNavigationBarItem(
                label: l10n?.navSettings ?? 'Settings',
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTitle(ScaffoldTab tab, SettingsController controller, AppLocalizations? l10n) {
    switch (tab) {
      case ScaffoldTab.eventlist:
        if (controller.SelectedTrack != "") {
          if (controller.selectedTracksFromAllYears == true) {
            return l10n?.titleTrackForAllYears(controller.SelectedTrack) ??
                "${controller.SelectedTrack} - track for all years";
          } else {
            return "FOSDEM ${controller.fosdemSelectedYear} - ${controller.SelectedTrack}";
          }
        }
        if (controller.selectedEventsFromAllYears == true) {
          return l10n?.titleTracksAllYears ?? "events of all years";
        }
        return "FOSDEM ${controller.fosdemSelectedYear}";
      case ScaffoldTab.tracklist:
        if (controller.selectedTracksFromAllYears == true) {
          return l10n?.titleTracksAllYears ?? "tracks of all years";
        }
        return "FOSDEM ${controller.fosdemSelectedYear}";
      case ScaffoldTab.personlist:
        if (controller.selectedPersonsFromAllYears == true) {
          return l10n?.titlePersonsAllYears ?? "persons of all years";
        }
        return "FOSDEM ${controller.fosdemSelectedYear}";
      case ScaffoldTab.conferencelist:
        return "FOSDEM ${controller.fosdemSelectedYear}";
      case ScaffoldTab.favoriteslist:
        if (controller.selectedFavoritesFromAllYears == true) {
          return l10n?.titleFavoritesAllYears ?? "favorites of all years";
        }
        return "FOSDEM ${controller.fosdemSelectedYear}";
      case ScaffoldTab.settings:
        return l10n?.navSettings ?? "Settings";
    }
  }

  int _getSelectedIndex(String pathTemplate) {
    if (pathTemplate.startsWith('/eventlist')) return 0;
    if (pathTemplate == '/favoriteslist') return 1;
    if (pathTemplate == '/tracklist') return 2;
    if (pathTemplate == '/personlist') return 3;
    if (pathTemplate == '/conferencelist') return 4;
    if (pathTemplate == '/settings') return 5;
    return 0;
  }

  void _onItemTapped(int value, BuildContext context) {
    if (settingsController.SelectedTrack.isNotEmpty) {
      settingsController.updateSelectedTrack('');
    }
    switch (ScaffoldTab.values[value]) {
      case ScaffoldTab.eventlist:
        context.go('/eventlist');
        break;
      case ScaffoldTab.favoriteslist:
        context.go('/favoriteslist');
        break;
      case ScaffoldTab.tracklist:
        context.go('/tracklist');
        break;
      case ScaffoldTab.personlist:
        context.go('/personlist');
        break;
      case ScaffoldTab.conferencelist:
        context.go('/conferencelist');
        break;
      case ScaffoldTab.settings:
        context.go('/settings');
        break;
    }
  }
}
