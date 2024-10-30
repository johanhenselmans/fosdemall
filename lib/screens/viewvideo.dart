import 'package:flutter/material.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';                      // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';          // Provides [VideoController] & [Video] etc.

import '../utils/constants.dart';

class ViewVideo extends StatefulWidget {
  SettingsController settingscontroller;

  String videoURL = "";
  static const routeName = 'viewvideo';

  ViewVideo(
      {super.key, required this.settingscontroller, required this.videoURL});

  @override
  _ViewVideoState createState() => _ViewVideoState();
}

class _ViewVideoState extends State<ViewVideo> {
  late final player = Player();
  late final controller = VideoController(player);

  void _goback() async {

    GoRouter.of(context).pop();
    //GoRouter.of(context).go('/');
  }

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.videoURL));
  }

  @override
  Widget build(BuildContext context) {
    double aheight = MediaQuery.of(context).size.height;
    double awidth = MediaQuery.of(context).size.width;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      aheight = MediaQuery.of(context).size.height * 11 / 13.0;
    }else {
      aheight = MediaQuery.of(context).size.width * 9.0 / 16.0;
    };
    return SafeArea(
      child: Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
          ElevatedButton(
            style: fosdemElevatedButtonStyle,
            child: const Row(
              children: [
                Icon(Icons.arrow_back_outlined, color: fosdemColorButtonTekst),
                Text(
                  "Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fosdemColorButtonTekst),
                ),
              ],
            ),
            onPressed: () => _goback(),
          ),
        ]
          ),
          Expanded(child:ListView(padding: const EdgeInsets.all(6), children: [
            SizedBox(
                width: awidth,
                height: aheight,
              child:
              Video(controller: controller),
            ),


          ])
          )
        ]),
      ),
    );
  }

  @override
  void dispose() async {
    player.dispose();
    super.dispose();
  }
}
