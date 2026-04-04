import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../src.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final List<MediaItem>? playlist;
  final int startIndex;

  const VideoPlayerPage({
    super.key,
    this.playlist,
    this.startIndex = 0,
  });

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  bool _isSeeking = false;
  Timer? _seekDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setOrientation();
  }

  void _initializePlayer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(playerControllerProvider);

      if (widget.playlist != null && widget.playlist!.isNotEmpty) {
        controller.playlist
            .setItems(widget.playlist!, startIndex: widget.startIndex);
        final currentItem = controller.playlist.currentItem;
        if (currentItem != null) {
          controller.playMedia(currentItem, autoPlay: true);
        }
      }
    });
  }

  void _setOrientation() {
    if (PlatformUtils.isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    _seekDebounceTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleSeek(Duration position) {
    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        ref.read(playerControllerProvider).seek(position);
      }
    });
  }

  void _handleVolumeChange(double volume) {
    ref.read(playerControllerProvider).setVolume(volume);
  }

  void _handleSpeedChange(double speed) {
    ref.read(playerControllerProvider).setSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(playerControllerProvider);
    final state = controller.state;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: UniversalPlatform.isWindows && !state.isFullscreen
          ? WindowsAppBar(
              title: state.currentItem?.title,
              onBackBefore: () {
                controller.pause();
              },
            )
          : null,
      body: _buildPlayerBody(controller, state),
    );
  }

  Widget _buildPlayerBody(PlayerController controller, PlayerState state) {
    return VolumeBrightnessGesture(
      onVolumeChange: _handleVolumeChange,
      child: PlayerGestureDetector(
        onTap: controller.toggleControls,
        onDoubleTap: controller.togglePlayPause,
        onDoubleTapLeft: () => controller.seekBackward(),
        onDoubleTapRight: () => controller.seekForward(),
        onMouseMove: () {
          if (PlatformUtils.isDesktop) {
            controller.showControls();
          }
        },
        onHorizontalDragUpdate: (delta) {
          if (!_isSeeking) {
            setState(() => _isSeeking = true);
          }
          final seekAmount = Duration(milliseconds: (delta.dx * 100).toInt());
          final newPosition = state.position + seekAmount;
          _handleSeek(newPosition);
        },
        onHorizontalDragEnd: () {
          setState(() => _isSeeking = false);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMediaContent(controller, state),
            if (state.isLoading)
              const PlayerLoadingIndicator(message: 'Loading...'),
            if (state.hasError)
              PlayerErrorWidget(
                message: state.errorMessage ?? 'Unknown error',
                onRetry: () {
                  if (state.currentItem != null) {
                    controller.playMedia(state.currentItem!);
                  }
                },
              ),
            if (state.isBuffering && !state.isLoading)
              const BufferingIndicator(),
            PlayerControls(
              state: state,
              visible: controller.controlsVisible,
              onPlayPause: controller.togglePlayPause,
              onPrevious: controller.previous,
              onNext: controller.next,
              onSeek: _handleSeek,
              onToggleFullscreen: () {
                controller.toggleFullscreen();
                _handleFullscreenChange(state.isFullscreen);
              },
              onToggleMute: controller.toggleMute,
              onVolumeChange: _handleVolumeChange,
              onSpeedChange: _handleSpeedChange,
              onToggleLock: controller.toggleLock,
              onCyclePlayMode: controller.cyclePlayMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(PlayerController controller, PlayerState state) {
    if (state.currentItem == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            '未选择媒体',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (state.currentItem!.type == MediaType.video) {
      return VideoPlayerView(
        controller: controller.videoController,
        state: state,
      );
    } else {
      return AudioPlayerView(
        state: state,
      );
    }
  }

  void _handleFullscreenChange(bool isFullscreen) {
    if (isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
