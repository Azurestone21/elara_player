import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import '../components/components.dart';

class PlayerPage extends ConsumerStatefulWidget {
  final List<MediaItem>? playlist;
  final int startIndex;

  const PlayerPage({
    super.key,
    this.playlist,
    this.startIndex = 0,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
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
        controller.playlist.setItems(widget.playlist!, startIndex: widget.startIndex);
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
          ? _buildWindowsAppBar()
          : null,
      body: _buildPlayerBody(controller, state),
    );
  }

  PreferredSizeWidget _buildWindowsAppBar() {
    final controller = ref.watch(playerControllerProvider);
    final state = controller.state;

    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1)),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
              padding: EdgeInsets.zero,
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // Draggable area with title
            Expanded(
              child: GestureDetector(
                onPanStart: (details) => windowManager.startDragging(),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      state.currentItem?.title ?? 'Elara Player',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Window controls
            Row(
              children: [
                IconButton(
                  onPressed: () => windowManager.minimize(),
                  icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                IconButton(
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                  icon: const Icon(Icons.square_outlined, size: 16, color: Colors.white),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                IconButton(
                  onPressed: () => windowManager.close(),
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ],
        ),
      ),
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
