import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fosdem/utils//style.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

//import 'package:flutter_localizations/flutter_localizations.dart';

class DebugPage extends StatefulWidget with ChangeNotifier {
  SettingsController controller;

  DebugPage({super.key, required this.controller, this.title});

  static const String routeName = "/debugpage";

  final String? title;

  @override
  DebugPageState createState() => DebugPageState();
}

/// // 1. After the page has been created, register it with the app routes
/// routes: <String, WidgetBuilder>{
///   DebugPage.routeName: (BuildContext context) => new DebugPage(title: "DebugPage"),
/// },
///
/// // 2. Then this could be used to navigate to the page.
/// Navigator.pushNamed(context, DebugPage.routeName);
///

class DebugPageState extends State<DebugPage> {
  int rc = 0;
  String version = "";
  String buildNumber = "";
  String packageName = "";
  String appName = "";

  @override
  initState() {
    super.initState();
    widget.controller.addListener(_handleSettingsChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSettingsChanged);
    //widget.controller.removeListener(_handleWoodyChanged);
    super.dispose();
  }

  void _handleSettingsChanged() {
    setState(() {});
  }

  void _displayAlert(String aText) {
    var alert = AlertDialog(
      title: const Text("Debug"),
      content: Text(aText),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
  }

  Future<String> _showVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

//     PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    return "Version: $version build: $buildNumber\n Package Name:\n $packageName";
//    });

//     return Text("empty version");
    /*
     return Text(
       "Version: $version build: $buildNumber Package: $packageName",
       textAlign: TextAlign.center,
     );
     */
    /*
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
     */
  }

  void _goback() {
    GoRouter.of(context).pushReplacement('/');

//    GoRouter.of(context).pop();
    //GoRouter.of(context).go('/');
  }

  @override
  Widget build(BuildContext context) {
    //String? serverIP;
    //String? serverName;
    return SafeArea(
      child: Scaffold(
        //restorationId: 'debug_page',
        body: SimpleGestureDetector(
          onHorizontalSwipe: (SwipeDirection direction) {
            if (direction == SwipeDirection.right) {
              _goback();
            }
          },
          swipeConfig: const SimpleSwipeConfig(
            verticalThreshold: 40.0,
            horizontalThreshold: 40.0,
            swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
          ),
          child:
          Column(
            children:[
          //ListView(
              //padding: const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 38),
          //    padding: const EdgeInsets.all(24),
          //    children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: fosdemElevatedButtonStyle,
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_outlined),
                            Text(
                              "Back",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        onPressed: () => _goback(),
                      ),
                    ]),
                Container(
                  alignment: Alignment.topLeft,
                  //padding:  EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: <Widget>[
                          ListView(
                              shrinkWrap: true,
                              children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                "This is a debug page for the FOSDEM app}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                widget.controller.SelectedTrack,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                widget.controller.fosdemSelectedYear,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: FutureBuilder<String>(
                                  future: _showVersion(),
                                  // a Future<String> or null
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else {
                                      return Text(
                                        '${snapshot.data}',
                                        textAlign: TextAlign.center,
                                      );
                                    }
                                  }),
                            ),
                          ]),

                      ]),
                ),
              ]),
       // ]),

      ),
      ),
    );
  }
}
