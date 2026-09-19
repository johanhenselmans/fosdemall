import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  Timer? _timer;
  double? _dragValue;
  double? _pendingSeekTarget;
  bool _isDragging = false;

  bool get _useVlcPlayer => !kIsWeb;

  void _goback() async {
    GoRouter.of(context).pop();
  }

  void _checkPendingSeek() {
    if (_pendingSeekTarget != null) {
      final posMs = _position.inMilliseconds.toDouble();
      if ((posMs - _pendingSeekTarget!).abs() < 1000) {
        _pendingSeekTarget = null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (_useVlcPlayer) {
      _initVlcPlayer();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initVideoPlayer();
        }
      });
    }
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _checkPendingSeek();
      if (!_isDragging && _isPlaying) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _initVlcPlayer() {
    try {
      final cleanUrl = widget.videoURL.trim();
      _vlcPlayerController = VlcPlayerController(
        mediaSource: VlcMediaSource(uri: Uri.parse(cleanUrl)),
        autoPlay: true,
      );
      _vlcPlayerController!.addListener(() {
        if (mounted) {
          if (_vlcPlayerController!.value.hasError) {
            setState(() {
              _hasError = true;
            });
          } else {
            _checkPendingSeek();
            if (!_isDragging) {
              setState(() {});
            }
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
    final cleanUrl = widget.videoURL.trim();

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(cleanUrl));
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
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  bool get _isPlaying {
    if (_useVlcPlayer) {
      final state = _vlcPlayerController?.value.state;
      return state == VlcPlaybackState.playing ||
          state == VlcPlaybackState.buffering;
    }
    return _videoPlayerController?.value.isPlaying ?? false;
  }

  bool get _canRenderPlayer {
    if (_useVlcPlayer) {
      return _vlcPlayerController != null;
    }
    return _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized;
  }

  bool get _isInitialized {
    if (_useVlcPlayer) {
      if (_vlcPlayerController == null || !_vlcPlayerController!.isAttached) {
        return false;
      }
      final val = _vlcPlayerController!.value;
      if (val.hasError) return false;
      return val.isReady ||
          val.duration > Duration.zero ||
          val.position > Duration.zero ||
          val.state == VlcPlaybackState.playing ||
          val.state == VlcPlaybackState.buffering ||
          val.state == VlcPlaybackState.paused;
    }
    return _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized;
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
    if (_useVlcPlayer) {
      if (_vlcPlayerController != null && _vlcPlayerController!.isAttached) {
        setState(() {
          _isPlaying
              ? _vlcPlayerController!.pause()
              : _vlcPlayerController!.play();
        });
      }
    } else if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      setState(() {
        _videoPlayerController!.value.isPlaying
            ? _videoPlayerController!.pause()
            : _videoPlayerController!.play();
      });
    }
  }

  void _onSeekStart(double value) {
    _isDragging = true;
    setState(() {
      _dragValue = value;
    });
  }

  void _onSeekChanged(double value) {
    setState(() {
      _dragValue = value;
    });
  }

  void _onSeekEnd(double value) async {
    final target = Duration(milliseconds: value.toInt());
    setState(() {
      _isDragging = false;
      _dragValue = null;
      _pendingSeekTarget = value;
    });
    if (_useVlcPlayer) {
      if (_vlcPlayerController != null && _vlcPlayerController!.isAttached) {
        await _vlcPlayerController!.seekTo(target);
      }
    } else if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      await _videoPlayerController!.seekTo(target);
    }
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _pendingSeekTarget == value) {
        setState(() {
          _pendingSeekTarget = null;
        });
      }
    });
  }

  void _seekTo(int milliseconds) {
    final target = Duration(milliseconds: milliseconds);
    if (_useVlcPlayer) {
      if (_vlcPlayerController != null && _vlcPlayerController!.isAttached) {
        _vlcPlayerController!.seekTo(target);
      }
    } else if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.seekTo(target);
    }
  }

  Future<void> _launchExternal() async {
    final uri = Uri.parse(widget.videoURL.trim());
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
                        : (_canRenderPlayer
                            ? Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        _buildVideoWidget(),
                                        if (!_isInitialized)
                                          const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        else
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
                                  Builder(builder: (context) {
                                    final maxDurationMs =
                                        _duration.inMilliseconds.toDouble();
                                    final currentMs = (_dragValue ??
                                            _pendingSeekTarget ??
                                            _position.inMilliseconds.toDouble())
                                        .clamp(
                                          0.0,
                                          maxDurationMs > 0 ? maxDurationMs : 1.0,
                                        );
                                    final canSeek =
                                        _isInitialized && maxDurationMs > 0;
                                    final displayedPosition = Duration(
                                      milliseconds: currentMs.toInt(),
                                    );

                                    return Column(
                                      children: [
                                        Slider(
                                          value: canSeek ? currentMs : 0.0,
                                          min: 0.0,
                                          max: maxDurationMs > 0
                                              ? maxDurationMs
                                              : 1.0,
                                          onChangeStart:
                                              canSeek ? _onSeekStart : null,
                                          onChanged:
                                              canSeek ? _onSeekChanged : null,
                                          onChangeEnd:
                                              canSeek ? _onSeekEnd : null,
                                        ),
                                        // Time played and total time underneath
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(
                                                  displayedPosition,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(_duration),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
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
