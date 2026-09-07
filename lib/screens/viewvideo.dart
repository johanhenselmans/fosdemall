import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../utils/constants.dart';

class ViewVideo extends StatefulWidget {
  final SettingsController settingscontroller;
  final String videoURL;

  static const routeName = 'viewvideo';

  const ViewVideo(
      {super.key, required this.settingscontroller, required this.videoURL});

  @override
  _ViewVideoState createState() => _ViewVideoState();
}

class _ViewVideoState extends State<ViewVideo> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _dialogShown = false;

  void _goback() async {
    GoRouter.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initPlayer();
      }
    });
  }

  Future<void> _initPlayer() async {
    final isWebM = widget.videoURL.toLowerCase().contains('.webm') ||
                   widget.videoURL.toLowerCase().contains('av1');

    if (Platform.isIOS && isWebM) {
      _showIosWebmPopup();
      return;
    }

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoURL));
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        _controller!.play();
      }
    } catch (e) {
      print("Video initialization error: $e");
      if (mounted) {
        if (Platform.isIOS && isWebM) {
          _showIosWebmPopup();
        } else {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
  }

  void _showIosWebmPopup() {
    if (_dialogShown) return;
    _dialogShown = true;

    final parentContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Video Format Notice"),
          content: const Text(
            "iOS can only play AV1/webm on iPhone 15 or later. Please go back to the event and choose the MP4 video link.",
          ),
          actions: <Widget>[
            ElevatedButton(
              style: fosdemElevatedButtonStyle,
              child: const Text(
                "Back to Event",
                style: TextStyle(color: fosdemColorButtonTekst),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (parentContext.mounted) {
                  GoRouter.of(parentContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchExternal() async {
    final uri = Uri.parse(widget.videoURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      GoRouter.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    double aheight = MediaQuery.of(context).size.height;
    double awidth = MediaQuery.of(context).size.width;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      aheight = MediaQuery.of(context).size.height * 11 / 13.0;
    } else {
      aheight = MediaQuery.of(context).size.width * 9.0 / 16.0;
    }
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(6),
                children: [
                  SizedBox(
                    width: awidth,
                    height: aheight,
                    child: _hasError
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Failed to load video format on this device.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: fosdemElevatedButtonStyle,
                                  onPressed: _launchExternal,
                                  child: const Text("Open Video Externally"),
                                ),
                              ],
                            ),
                          )
                        : (_controller != null && _controller!.value.isInitialized
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: _controller!.value.aspectRatio,
                                    child: VideoPlayer(_controller!),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _controller!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 50.0,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _controller!.value.isPlaying
                                            ? _controller!.pause()
                                            : _controller!.play();
                                      });
                                    },
                                  ),
                                ],
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
