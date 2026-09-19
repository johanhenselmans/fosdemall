import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fosdem/utils/settings_controller.dart';
import 'package:fosdem/utils/style.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:vlc_player/vlc_player.dart';

import '../utils/constants.dart';

class ViewVideo extends StatefulWidget {
  final SettingsController settingscontroller;
  final String videoURL;

  static const routeName = 'viewvideo';

  const ViewVideo(
      {super.key, required this.settingscontroller, required this.videoURL});

  @override
  State<ViewVideo> createState() => _ViewVideoState();
}

class _ViewVideoState extends State<ViewVideo> {
  VideoPlayerController? _videoPlayerController;
  VlcPlayerController? _vlcPlayerController;
  bool _hasError = false;
  bool _dialogShown = false;
  Timer? _timer;

  bool get _useVlcPlayer =>
      Platform.isAndroid || Platform.isWindows || Platform.isLinux;

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
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isPlaying) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _initPlayer() async {
    if (_useVlcPlayer) {
      await _initVlcPlayer();
    } else {
      await _initVideoPlayer();
    }
  }

  Future<void> _initVlcPlayer() async {
    try {
      _vlcPlayerController = VlcPlayerController(
        mediaSource: VlcMediaSource(uri: Uri.parse(widget.videoURL)),
        autoPlay: true,
      );
      _vlcPlayerController!.addListener(() {
        if (mounted) {
          if (_vlcPlayerController!.value.hasError) {
            setState(() {
              _hasError = true;
            });
          } else {
            setState(() {});
          }
        }
      });
    } catch (e) {
      debugPrint("VLC initialization error: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _initVideoPlayer() async {
    final isWebM = widget.videoURL.toLowerCase().contains('.webm') ||
                   widget.videoURL.toLowerCase().contains('av1');

    if (Platform.isIOS && isWebM) {
      _showIosWebmPopup();
      return;
    }

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoURL));
      await _videoPlayerController!.initialize();
      _videoPlayerController!.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) {
        setState(() {});
        _videoPlayerController!.play();
      }
    } catch (e) {
      debugPrint("Video initialization error: $e");
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

  bool get _isPlaying {
    if (_useVlcPlayer) {
      return _vlcPlayerController?.value.isPlaying ?? false;
    }
    return _videoPlayerController?.value.isPlaying ?? false;
  }

  bool get _isInitialized {
    if (_useVlcPlayer) {
      return _vlcPlayerController != null && _vlcPlayerController!.value.isReady;
    }
    return _videoPlayerController != null && _videoPlayerController!.value.isInitialized;
  }

  Duration get _position {
    if (_useVlcPlayer) {
      return _vlcPlayerController?.value.position ?? Duration.zero;
    }
    return _videoPlayerController?.value.position ?? Duration.zero;
  }

  Duration get _duration {
    if (_useVlcPlayer) {
      return _vlcPlayerController?.value.duration ?? Duration.zero;
    }
    return _videoPlayerController?.value.duration ?? Duration.zero;
  }

  double get _aspectRatio {
    if (_useVlcPlayer) {
      final size = _vlcPlayerController?.value.videoSize;
      if (size != null && size.width > 0 && size.height > 0) {
        return size.width / size.height;
      }
      return 16.0 / 9.0;
    }
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      final ratio = _videoPlayerController!.value.aspectRatio;
      return ratio > 0 ? ratio : 16.0 / 9.0;
    }
    return 16.0 / 9.0;
  }

  void _togglePlayPause() {
    setState(() {
      if (_useVlcPlayer && _vlcPlayerController != null) {
        _vlcPlayerController!.value.isPlaying
            ? _vlcPlayerController!.pause()
            : _vlcPlayerController!.play();
      } else if (_videoPlayerController != null) {
        _videoPlayerController!.value.isPlaying
            ? _videoPlayerController!.pause()
            : _videoPlayerController!.play();
      }
    });
  }

  void _seekTo(int milliseconds) {
    final target = Duration(milliseconds: milliseconds);
    setState(() {
      if (_useVlcPlayer && _vlcPlayerController != null) {
        _vlcPlayerController!.seekTo(target);
      } else if (_videoPlayerController != null) {
        _videoPlayerController!.seekTo(target);
      }
    });
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
            "iOS can only play AV1/webm on iPhone 15 or later. You can choose to go back to the event for an MP4 link or launch the WebM video in an external app or browser.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Back to Event"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (parentContext.mounted) {
                  GoRouter.of(parentContext).pop();
                }
              },
            ),
            ElevatedButton(
              style: fosdemElevatedButtonStyle,
              child: const Text(
                "Launch External App",
                style: TextStyle(color: fosdemColorButtonTekst),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final uri = Uri.parse(widget.videoURL);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  Widget _buildVideoWidget() {
    if (_useVlcPlayer) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: VlcPlayer(
          controller: _vlcPlayerController!,
          fit: VlcVideoFit.contain,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: VideoPlayer(_videoPlayerController!),
    );
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
                    height: aheight + 80, // Extra height for slider and time labels
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
                                  child: const Text(
                                    "Open Video Externally",
                                    style: TextStyle(color: fosdemColorButtonTekst),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (_isInitialized
                            ? Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        _buildVideoWidget(),
                                        IconButton(
                                          icon: Icon(
                                            _isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 50.0,
                                          ),
                                          onPressed: _togglePlayPause,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Slider / Scrollbar to position inside video
                                  Slider(
                                    value: _position.inMilliseconds
                                        .toDouble()
                                        .clamp(
                                          0.0,
                                          _duration.inMilliseconds.toDouble() > 0
                                              ? _duration.inMilliseconds.toDouble()
                                              : 1.0,
                                        ),
                                    min: 0.0,
                                    max: _duration.inMilliseconds.toDouble() > 0
                                        ? _duration.inMilliseconds.toDouble()
                                        : 1.0,
                                    onChanged: (value) => _seekTo(value.toInt()),
                                  ),
                                  // Time played and total time underneath
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(_position),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _formatDuration(_duration),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
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
    _timer?.cancel();
    _videoPlayerController?.dispose();
    _vlcPlayerController?.dispose();
    super.dispose();
  }
}
