import 'dart:async';
import 'dart:io';
import 'package:elara_player/src/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/services.dart';

class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({
    required this.time,
    required this.text,
  });
}

class MusicDetailPage extends ConsumerStatefulWidget {
  const MusicDetailPage({super.key});

  @override
  ConsumerState<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends ConsumerState<MusicDetailPage> {
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  final ScrollController _lyricScrollController = ScrollController();
  Timer? _seekDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _lyricScrollController.dispose();
    _seekDebounceTimer?.cancel();
    super.dispose();
  }

  void _loadLyrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(playerControllerProvider);
      final currentItem = controller.state.currentItem;
      if (currentItem != null && currentItem.type == MediaType.audio) {
        _parseLyricFile(currentItem);
      }
    });
  }

  Future<void> _parseLyricFile(MediaItem item) async {
    if (!item.isLocal) {
      // 网络音乐暂时不支持歌词
      setState(() {
        _lyrics = [];
      });
      return;
    }

    // 获取音乐文件路径，查找同名的 .lrc 文件
    final musicPath = item.uri;
    final lrcPath = _getLrcPath(musicPath);

    if (lrcPath == null) {
      setState(() {
        _lyrics = [];
      });
      return;
    }

    final file = File(lrcPath);
    if (!await file.exists()) {
      setState(() {
        _lyrics = [];
      });
      return;
    }

    try {
      final content = await file.readAsString();
      final lyrics = _parseLrcContent(content);
      setState(() {
        _lyrics = lyrics;
      });
    } catch (e) {
      setState(() {
        _lyrics = [];
      });
    }
  }

  String? _getLrcPath(String musicPath) {
    // 获取文件目录和文件名（不含扩展名）
    final dir = path.dirname(musicPath);
    final fileNameWithoutExt = path.basenameWithoutExtension(musicPath);

    // 构建 lrc 文件路径
    final lrcPath = path.join(dir, '$fileNameWithoutExt.lrc');
    return lrcPath;
  }

  List<LyricLine> _parseLrcContent(String content) {
    final List<LyricLine> lyrics = [];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 匹配时间标签 [mm:ss.xx] 或 [mm:ss.xxx]
      final regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
      final match = regExp.firstMatch(trimmedLine);

      if (match != null) {
        final minutes = int.tryParse(match.group(1)!) ?? 0;
        final seconds = int.tryParse(match.group(2)!) ?? 0;
        final milliseconds = int.tryParse(match.group(3)!) ?? 0;
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          final totalMilliseconds =
              minutes * 60 * 1000 + seconds * 1000 + milliseconds;
          lyrics.add(LyricLine(
            time: Duration(milliseconds: totalMilliseconds),
            text: text,
          ));
        }
      }
    }

    // 按时间排序
    lyrics.sort((a, b) => a.time.compareTo(b.time));
    return lyrics;
  }

  void _updateCurrentLyric(Duration position) {
    if (_lyrics.isEmpty) return;

    int newIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= position) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = newIndex;
      });
      _scrollToCurrentLyric();
    }
  }

  void _scrollToCurrentLyric() {
    if (_lyrics.isEmpty || _currentLyricIndex < 0) return;

    // 检查 ScrollController 是否已经附加到 scroll view
    if (!_lyricScrollController.hasClients) return;

    // 计算需要滚动的位置，使当前歌词显示在中间
    const itemHeight = 40.0; // 每行歌词的高度
    final viewportHeight = _lyricScrollController.position.viewportDimension;
    final targetOffset = (_currentLyricIndex * itemHeight) -
        (viewportHeight / 2) +
        (itemHeight / 2);

    _lyricScrollController.animateTo(
      targetOffset.clamp(0.0, _lyricScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(playerControllerProvider);
    final state = controller.state;

    // 更新当前歌词
    _updateCurrentLyric(state.position);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE4E8EC),
            ],
          ),
        ),
        child: Column(
          children: [
            // Windows 标题栏
            _buildWindowsAppBar(state),
            // 上半部分：歌曲信息和歌词
            Expanded(
              flex: 3,
              child: _buildUpperSection(state),
            ),
            // 下半部分：控制栏
            _buildControlSection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsAppBar(PlayerState state) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, size: 16, color: Colors.grey[800]),
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
                    state.currentItem?.title ?? 'Music Detail',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Window controls
          const WindowControls(),
        ],
      ),
    );
  }

  Widget _buildUpperSection(PlayerState state) {
    return Row(
      children: [
        // 左边：歌曲封面、名称、歌手
        Expanded(
          flex: 1,
          child: _buildSongInfo(state),
        ),
        // 右边：歌词
        Expanded(
          flex: 1,
          child: _buildLyricsView(),
        ),
      ],
    );
  }

  Widget _buildSongInfo(PlayerState state) {
    final item = state.currentItem;

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 歌曲封面
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildAlbumCover(item),
            ),
          ),
          const SizedBox(height: 32),
          // 歌曲名称
          Text(
            item?.title ?? 'Unknown Title',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // 歌手
          Text(
            item?.artist ?? 'Unknown Artist',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCover(MediaItem? item) {
    if (item?.thumbnailUrl != null && item!.thumbnailUrl!.isNotEmpty) {
      if (item.isLocal) {
        return Image.file(
          File(item.thumbnailUrl!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultCover(),
        );
      } else {
        return Image.network(
          item.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultCover(),
        );
      }
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(
        Icons.music_note,
        size: 100,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildLyricsView() {
    if (_lyrics.isEmpty) {
      return Center(
        child: Text(
          '暂无歌词',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: ListView.builder(
        controller: _lyricScrollController,
        itemCount: _lyrics.length,
        itemBuilder: (context, index) {
          final isCurrent = index == _currentLyricIndex;
          return Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              _lyrics[index].text,
              style: TextStyle(
                fontSize: isCurrent ? 18 : 14,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? Colors.grey[800] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlSection(PlayerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条和时间
          Row(
            children: [
              // 当前时间
              Text(
                _formatDuration(state.position),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              // 进度条
              Expanded(
                child: ProgressBar(
                  position: state.position,
                  duration: state.duration,
                  buffered: state.buffered,
                  onSeek: _handleSeek,
                ),
              ),
              const SizedBox(width: 16),
              // 总时间
              Text(
                _formatDuration(state.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 播放模式
              IconButton(
                onPressed: () =>
                    ref.read(playerControllerProvider).cyclePlayMode(),
                icon: Icon(
                  _getPlayModeIcon(state.playMode),
                  color: Colors.grey[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 24),
              // 上一首
              IconButton(
                onPressed: () => ref.read(playerControllerProvider).previous(),
                icon: Icon(
                  Icons.skip_previous,
                  color: Colors.grey[800],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // 播放/暂停
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: IconButton(
                  onPressed: () =>
                      ref.read(playerControllerProvider).togglePlayPause(),
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 下一首
              IconButton(
                onPressed: () => ref.read(playerControllerProvider).next(),
                icon: Icon(
                  Icons.skip_next,
                  color: Colors.grey[800],
                  size: 32,
                ),
              ),
              const SizedBox(width: 24),
              // 音量控制
              _buildVolumeControl(state),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(PlayerState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => ref.read(playerControllerProvider).toggleMute(),
          icon: Icon(
            state.isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.grey[700],
            size: 20,
          ),
        ),
        SizedBox(
          width: 100,
          child: Slider(
            value: state.isMuted ? 0 : state.volume,
            onChanged: _handleVolumeChange,
            activeColor: Colors.grey[700],
            inactiveColor: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return Icons.repeat;
      case PlayMode.loop:
        return Icons.repeat;
      case PlayMode.singleLoop:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
