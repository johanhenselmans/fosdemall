import 'package:flutter/material.dart';
import 'package:fosdem/data/database_helper.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:fosdem/utils/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
//class SettingsView extends StatelessWidget {

class SettingsView extends StatefulWidget with ChangeNotifier {
  SettingsController controller;

  SettingsView({super.key, required this.controller});

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {

  String currentYear = "";
  String selectedYear = "";
  bool isFavoritesChecked = false;
  bool isTracksChecked = false;
  bool isPersonsChecked = false;
  bool isEventsChecked = false;
  bool isNowChecked = false;
  bool _isScraping = false;
  String _scrapeProgressText = '';
  bool _initialScraped = false;

  int _tapcount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleSettingsChanged);
    isFavoritesChecked = widget.controller.selectedFavoritesFromAllYears;
    isTracksChecked = widget.controller.selectedTracksFromAllYears;
    isPersonsChecked = widget.controller.selectedPersonsFromAllYears;
    isEventsChecked = widget.controller.selectedEventsFromAllYears;
    isNowChecked = widget.controller.selectedNow;
    _checkInitialScraped();
  }

  Future<void> _checkInitialScraped() async {
    final done = await DatabaseHelper().isInitialPersonsScraped();
    if (mounted) {
      setState(() {
        _initialScraped = done;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSettingsChanged);
    //widget.controller.removeListener(_handleFosdemChanged);
    super.dispose();
  }

  void _handleSettingsChanged() {
    if (widget.controller.fosdemCurrentYear != "") {
      currentYear = widget.controller.fosdemCurrentYear;
    }
    selectedYear = widget.controller.fosdemSelectedYear;
    isFavoritesChecked = widget.controller.selectedFavoritesFromAllYears;
    isTracksChecked = widget.controller.selectedTracksFromAllYears;
    isPersonsChecked = widget.controller.selectedPersonsFromAllYears;
    isEventsChecked = widget.controller.selectedEventsFromAllYears;
    isNowChecked = widget.controller.selectedNow;
    setState(() {});
  }

/*
  void _handleFosdemChanged() {
    ServerAddress? anAddress;
    anAddress = fosdemServers.getCurrentFosdem();
    //fosdemServers.getCurrentFosdem().then((value) => anAddress = value);
    if (!anAddress.serverIP!.isEmpty) {
      if (this.mounted) {
        setState(() {
          serverName = anAddress?.serverName;
          serverIP = anAddress?.serverIP;
        });
      }
    }
  }
*/
  Future<PackageInfo> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }

  void _countTaps() {
    _tapcount++;
    if (_tapcount > 4) {
      _tapcount = 0;
      GoRouter.of(context).go('/debug');
    }
  }

  void gotoCurrentConference() {
    widget.controller.updateSelectedYear(widget.controller.fosdemCurrentYear);
    widget.controller.updateSelectedTrack('');
    GoRouter.of(context).pushReplacement('/eventlist');
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String lastYear = now.year.toString();

    //});
    return ListView(
      //padding: const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 38),
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.sensor_door_rounded, size: 32),
        const Text("Chosen Fosdem Year:",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        Text(widget.controller.fosdemSelectedYear, textAlign: TextAlign.center),
        //Text("server: ${widget.controller.fosdemServerIP}",
        //    textAlign: TextAlign.center),
        const SizedBox(
          height: 20,
        ),
        Text("Last Fosdem: $lastYear",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text("Current Fosdem: ${widget.controller.fosdemCurrentYear}",
            textAlign: TextAlign.center),
        ElevatedButton(
          style: fosdemElevatedButtonStyle,
          child: const Text(
            "Go To Current FosDem",
            textAlign: TextAlign.center,
            style: TextStyle(color: fosdemColorButtonTekst)
          ),
          onPressed: () => gotoCurrentConference(),
        ),
        const SizedBox(
          height: 20,
        ),
        CheckboxListTile(
            title: const Text("Display events starting from now"),
            value: isNowChecked,
            onChanged: (bool? value) {
              setState(() {
                isNowChecked = value!;
              });
              if (isNowChecked) {
                widget.controller.updateNow(true);
              } else {
                widget.controller.updateNow(false);
              }
            }),
        const SizedBox(
          height: 20,
        ),
        CheckboxListTile(
            title: const Text("Display favorites of all years in the favorites list"),
            value: isFavoritesChecked,
            onChanged: (bool? value) {
              setState(() {
                isFavoritesChecked = value!;
              });
              if (isFavoritesChecked) {
                widget.controller.updateSelectedFavoritesOfAllYears(true);
              } else {
                widget.controller.updateSelectedFavoritesOfAllYears(false);
              }
            }),
        const SizedBox(
          height: 20,
        ),
        CheckboxListTile(
            title: const Text("Display tracks of all years in the tracks list"),
            value: isTracksChecked,
            onChanged: (bool? value) {
              setState(() {
                isTracksChecked = value!;
              });
              if (isTracksChecked) {
                widget.controller.updateSelectedTracksOfAllYears(true);
              } else {
                widget.controller.updateSelectedTracksOfAllYears(false);
              }
            }),
        const SizedBox(
          height: 20,
        ),
        CheckboxListTile(
            title: const Text("Display persons of all years in the persons list"),
            value: isPersonsChecked,
            onChanged: (bool? value) {
              setState(() {
                isPersonsChecked = value!;
              });
              if (isPersonsChecked) {
                widget.controller.updateSelectedPersonsOfAllYears(true);
              } else {
                widget.controller.updateSelectedPersonsOfAllYears(false);
              }
            }),
        const SizedBox(
          height: 20,
        ),
        CheckboxListTile(
            title: const Text("Display events of all years in the event list"),
            value: isEventsChecked,
            onChanged: (bool? value) {
              setState(() {
                isEventsChecked = value!;
              });
              if (isEventsChecked) {
                widget.controller.updateSelectedEventsOfAllYears(true);
              } else {
                widget.controller.updateSelectedEventsOfAllYears(false);
              }
            }),
        const SizedBox(
          height: 20,
        ),
        if (!_initialScraped) ...[
          ElevatedButton(
            style: fosdemElevatedButtonStyle,
            onPressed: _isScraping
                ? null
                : () async {
                    setState(() {
                      _isScraping = true;
                      _scrapeProgressText = 'Starting initial scraper since 2013...';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting initial scraping of all speakers since 2013...'),
                      ),
                    );
                    try {
                      await DatabaseHelper().scrapePersonsSince2013(
                        startYear: 2013,
                        onProgress: (msg, prog) {
                          if (mounted) {
                            setState(() {
                              _scrapeProgressText = msg;
                            });
                          }
                        },
                      );
                      final done = await DatabaseHelper().isInitialPersonsScraped();
                      if (mounted) {
                        setState(() {
                          _initialScraped = done;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully scraped all speakers since 2013!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error scraping speakers: $e'),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isScraping = false;
                          _scrapeProgressText = '';
                        });
                      }
                    }
                  },
            child: _isScraping
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _scrapeProgressText.isNotEmpty ? _scrapeProgressText : "Scraping speakers...",
                          style: const TextStyle(color: fosdemColorButtonTekst, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "Initial Scraping: All Speakers Since 2013",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: fosdemColorButtonTekst),
                  ),
          ),
        ] else ...[
          ElevatedButton(
            style: fosdemElevatedButtonStyle,
            onPressed: _isScraping
                ? null
                : () async {
                    setState(() {
                      _isScraping = true;
                      _scrapeProgressText = 'Refreshing events for $currentYear...';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Refreshing events for $currentYear...'),
                      ),
                    );
                    try {
                      await DatabaseHelper().refreshCurrentYearEvents(
                        onProgress: (msg) {
                          if (mounted) {
                            setState(() {
                              _scrapeProgressText = msg;
                            });
                          }
                        },
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully refreshed events for $currentYear!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error refreshing events: $e'),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isScraping = false;
                          _scrapeProgressText = '';
                        });
                      }
                    }
                  },
            child: _isScraping && _scrapeProgressText.contains('events')
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _scrapeProgressText,
                          style: const TextStyle(color: fosdemColorButtonTekst, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text(
                    "Refresh Events for Current Year ($currentYear)",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: fosdemColorButtonTekst),
                  ),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
            style: fosdemElevatedButtonStyle,
            onPressed: _isScraping
                ? null
                : () async {
                    setState(() {
                      _isScraping = true;
                      _scrapeProgressText = 'Refreshing persons for $currentYear...';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Refreshing persons for $currentYear...',
                        ),
                      ),
                    );
                    try {
                      await DatabaseHelper().refreshCurrentYearPersons(
                        onProgress: (msg, prog) {
                          if (mounted) {
                            setState(() {
                              _scrapeProgressText = msg;
                            });
                          }
                        },
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully refreshed persons for $currentYear!',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error refreshing persons: $e'),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isScraping = false;
                          _scrapeProgressText = '';
                        });
                      }
                    }
                  },
            child: _isScraping && (_scrapeProgressText.contains('speakers') || _scrapeProgressText.contains('persons'))
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _scrapeProgressText,
                          style: const TextStyle(color: fosdemColorButtonTekst, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text(
                    "Refresh Persons for Current Year ($currentYear)",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: fosdemColorButtonTekst),
                  ),
          ),
        ],
        const SizedBox(
          height: 40,
        ),
        GestureDetector(
          onTap: _countTaps,
          child: FutureBuilder<PackageInfo>(
              future: getPackageInfo(),
              builder:
                  (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                if (snapshot.hasData) {
                  PackageInfo? packageInfo = snapshot.data;
                  return Column(children: [
                    Text("App: ${packageInfo!.appName}"),
                    Text("Package: ${packageInfo.packageName}"),
                    Text(
                        "Version:  ${packageInfo.version}, build ${packageInfo.buildNumber}"),
                  ]);
                } else if (snapshot.hasError) {
                  return const Text('I could not find a version of the app');
                } else {
                  List<Widget> children;
                  children = const <Widget>[
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Awaiting result...'),
                    ),
                  ];
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    ),
                  );
                }
              }),
        )
      ],
    );
  }
}
