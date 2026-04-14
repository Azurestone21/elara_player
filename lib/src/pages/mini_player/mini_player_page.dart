// widgets/mini_player.dart
import 'package:flutter/material.dart';
import '../../services/player_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback onRestore;

  const MiniPlayer({
    super.key,
    required this.onRestore,
  });

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _isHovering = false;
  double windowHeight = 72;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerController = ref.watch(playerControllerProvider);
    final state = playerController.state;
    final mediaItem = state.currentItem;
    final isPlaying = state.isPlaying;

    return DragToMoveArea(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Container(
          height: windowHeight,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // 主内容：封面 + 歌曲信息
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    _buildCover(mediaItem?.thumbnailUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mediaItem?.title ?? '未播放',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mediaItem?.artist ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 悬浮控制栏（从下往上滑动）
              if (_isHovering)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  right: 0,
                  bottom: 0,
                  width: 250,
                  height: windowHeight,
                  child: _buildControlBar(isPlaying),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String? coverUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: coverUrl != null
          ? Image.asset(coverUrl, width: 48, height: 48, fit: BoxFit.cover)
          : Container(
              width: 48,
              height: 48,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
    );
  }

  Widget _buildControlBar(bool isPlaying) {
    final playerController = ref.watch(playerControllerProvider);
    return Container(
      width: 250,
      height: windowHeight,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            onPressed: playerController.previous,
          ),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: playerController.togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: playerController.next,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: widget.onRestore,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
