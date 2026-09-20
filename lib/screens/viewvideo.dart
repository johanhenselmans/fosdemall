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
  Timer? _controlsTimer;
  double? _dragValue;
  double? _pendingSeekTarget;
  bool _isDragging = false;
  bool _showControls = true;
  bool _hasTriggeredInitialControlsHide = false;
  final GlobalKey _vlcPlayerKey = GlobalKey();

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
      if (!_hasTriggeredInitialControlsHide && _isPlaying) {
        _hasTriggeredInitialControlsHide = true;
        _resetControlsTimer();
      }
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isPlaying) {
      _resetControlsTimer();
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying && !_isDragging) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_useVlcPlayer) {
      if (_vlcPlayerController != null && _vlcPlayerController!.isAttached) {
        setState(() {
          if (_isPlaying) {
            _vlcPlayerController!.pause();
            _showControls = true;
            _controlsTimer?.cancel();
          } else {
            _vlcPlayerController!.play();
            _resetControlsTimer();
          }
        });
      }
    } else if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      setState(() {
        if (_videoPlayerController!.value.isPlaying) {
          _videoPlayerController!.pause();
          _showControls = true;
          _controlsTimer?.cancel();
        } else {
          _videoPlayerController!.play();
          _resetControlsTimer();
        }
      });
    }
  }

  void _onSeekStart(double value) {
    _controlsTimer?.cancel();
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
    _resetControlsTimer();
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
          key: _vlcPlayerKey,
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

  Widget _buildBackButton() {
    return ElevatedButton(
      style: fosdemElevatedButtonStyle,
      onPressed: _goback,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_outlined, color: fosdemColorButtonTekst),
          SizedBox(width: 4),
          Text(
            "Back",
            textAlign: TextAlign.center,
            style: TextStyle(color: fosdemColorButtonTekst),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
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
    );
  }

  Widget _buildControls({bool isDarkOverlay = false}) {
    final textColor = isDarkOverlay ? Colors.white : null;
    return Builder(builder: (context) {
      final maxDurationMs = _duration.inMilliseconds.toDouble();
      final currentMs = (_dragValue ??
              _pendingSeekTarget ??
              _position.inMilliseconds.toDouble())
          .clamp(
        0.0,
        maxDurationMs > 0 ? maxDurationMs : 1.0,
      );
      final canSeek = _isInitialized && maxDurationMs > 0;
      final displayedPosition = Duration(
        milliseconds: currentMs.toInt(),
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: canSeek ? currentMs : 0.0,
            min: 0.0,
            max: maxDurationMs > 0 ? maxDurationMs : 1.0,
            onChangeStart: canSeek ? _onSeekStart : null,
            onChanged: canSeek ? _onSeekChanged : null,
            onChangeEnd: canSeek ? _onSeekEnd : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(displayedPosition),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: isLandscape ? Colors.black : null,
      body: SafeArea(
        child: Column(
          children: [
            // Top back button row in portrait; zero height in landscape
            if (isLandscape)
              const SizedBox.shrink()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBackButton(),
                ],
              ),

            // Video + controls stack: same widget element path in both portrait and landscape
            Expanded(
              key: const ValueKey('video_expanded_container'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full video widget (base layer)
                  Center(
                    child: _hasError
                        ? _buildErrorWidget()
                        : (_canRenderPlayer
                            ? _buildVideoWidget()
                            : const Center(
                                child: CircularProgressIndicator(),
                              )),
                  ),

                  // Tap overlay on top of the native video view
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleControls,
                    ),
                  ),

                  // Center Play/Pause button
                  if (_canRenderPlayer && !_hasError)
                    AnimatedOpacity(
                      opacity:
                          _showControls || !_isPlaying || _hasError ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: IgnorePointer(
                        ignoring: !_showControls && _isPlaying && !_hasError,
                        child: Center(
                          child: !_isInitialized
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    iconSize: 56.0,
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                ),
                        ),
                      ),
                    ),

                  // Overlaid Back Button in Landscape (Top-Left)
                  if (isLandscape)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBackButton(),
                    ),

                  // Overlaid Seekbar & Timestamp in Landscape (Bottom)
                  if (isLandscape && _canRenderPlayer && !_hasError)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 8,
                      child: AnimatedOpacity(
                        opacity: _showControls || !_isPlaying || _hasError
                            ? 1.0
                            : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: !_showControls && _isPlaying && !_hasError,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildControls(isDarkOverlay: true),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom controls in portrait; zero height in landscape
            if (isLandscape)
              const SizedBox.shrink()
            else if (_canRenderPlayer && !_hasError)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 8.0,
                ),
                child: _buildControls(),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controlsTimer?.cancel();
    _videoPlayerController?.dispose();
    _vlcPlayerController?.dispose();
    super.dispose();
  }
}
