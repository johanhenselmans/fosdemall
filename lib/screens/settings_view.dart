import 'package:flutter/material.dart';
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

  int _tapcount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleSettingsChanged);
    isFavoritesChecked = widget.controller.selectedFavoritesFromAllYears;
    isTracksChecked = widget.controller.selectedTracksFromAllYears;
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
