import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/models.dart';
import 'playlist_service.dart';

/// 播放器控制器提供者，用于全局访问播放器实例
final playerControllerProvider = ChangeNotifierProvider<PlayerController>((ref) {
  return PlayerController();
});

/// 播放器控制器类，负责管理音频和视频的播放
class PlayerController extends ChangeNotifier {
  /// 播放列表服务
  final PlaylistService _playlist = PlaylistService();
  /// 视频播放器控制器
  vp.VideoPlayerController? _videoController;
  /// 音频播放器
  ap.AudioPlayer? _audioPlayer;
  
  /// 播放器状态
  PlayerState _state = const PlayerState();
  /// 位置更新定时器
  Timer? _positionTimer;
  /// 控制栏隐藏定时器
  Timer? _hideControlsTimer;
  /// 控制栏是否可见
  bool _controlsVisible = true;
  /// 是否已释放
  bool _disposed = false;

  /// 获取当前播放器状态
  PlayerState get state => _state;
  /// 获取播放列表服务
  PlaylistService get playlist => _playlist;
  /// 获取控制栏是否可见
  bool get controlsVisible => _controlsVisible;
  /// 获取视频控制器
  vp.VideoPlayerController? get videoController => _videoController;

  /// 状态流，用于监听播放器状态变化
  Stream<PlayerState> get stateStream => _stateController.stream;
  final _stateController = StreamController<PlayerState>.broadcast();

  /// 构造函数，初始化音频播放器
  PlayerController() {
    _initAudioPlayer();
  }

  /// 初始化音频播放器
  void _initAudioPlayer() {
    _audioPlayer = ap.AudioPlayer();
    
    // 监听音频播放器状态变化
    _audioPlayer!.onPlayerStateChanged.listen((ap.PlayerState state) {
      switch (state) {
        case ap.PlayerState.playing:
          _updateState(_state.copyWith(status: PlayerStatus.playing));
          WakelockPlus.enable(); // 保持屏幕常亮
          break;
        case ap.PlayerState.paused:
          _updateState(_state.copyWith(status: PlayerStatus.paused));
          WakelockPlus.disable(); // 允许屏幕熄灭
          break;
        case ap.PlayerState.completed:
          _onPlaybackComplete(); // 播放完成回调
          break;
        case ap.PlayerState.stopped:
          _updateState(_state.copyWith(status: PlayerStatus.idle));
          WakelockPlus.disable(); // 允许屏幕熄灭
          break;
        case ap.PlayerState.disposed:
          break;
      }
    });

    // 监听播放位置变化
    _audioPlayer!.onPositionChanged.listen((position) {
      _updateState(_state.copyWith(position: position));
    });

    // 监听音频时长变化
    _audioPlayer!.onDurationChanged.listen((duration) {
      _updateState(_state.copyWith(duration: duration));
    });
  }

  /// 播放媒体文件
  /// [item] 媒体项
  /// [autoPlay] 是否自动播放
  Future<void> playMedia(MediaItem item, {bool autoPlay = true}) async {
    print('playMedia 被调用，项目: ${item.title}, 类型: ${item.type}, URI: ${item.uri}');
    try {
      print('正在释放当前播放器...');
      await disposeCurrentPlayer(); // 释放当前播放器
      print('当前播放器已释放');
      
      // 更新状态为加载中
      _updateState(_state.copyWith(
        status: PlayerStatus.loading,
        currentItem: item,
        position: Duration.zero,
        duration: Duration.zero,
        buffered: Duration.zero,
        clearError: true,
      ));
      print('状态已更新为加载中');

      // 根据媒体类型初始化对应的播放器
      if (item.type == MediaType.video) {
        print('正在初始化视频播放器...');
        await _initVideoPlayer(item, autoPlay: autoPlay);
        print('视频播放器已初始化');
      } else {
        print('正在初始化音频播放器...');
        await _initAudioPlayerSource(item, autoPlay: autoPlay);
        print('音频播放器已初始化');
      }
    } catch (e) {
      print('Error in playMedia: $e');
      _handleError('Failed to play media: $e');
    }
  }

  /// 初始化视频播放器
  /// [item] 媒体项
  /// [autoPlay] 是否自动播放
  Future<void> _initVideoPlayer(MediaItem item, {bool autoPlay = true}) async {
    try {
      print('Initializing video player for: ${item.uri}');
      print('Is local: ${item.isLocal}, Is network: ${item.isNetwork}');
      
      // 释放现有的视频控制器
      if (_videoController != null) {
        _videoController!.removeListener(_onVideoEvent);
        await _videoController!.dispose();
        _videoController = null;
      }
      
      // 处理网络视频
      if (item.isNetwork) {
        print('创建网络视频控制器');
        try {
          _videoController = vp.VideoPlayerController.networkUrl(
            Uri.parse(item.uri),
            httpHeaders: item.headers ?? {},
          );
          _videoController!.addListener(_onVideoEvent);
          await _videoController!.initialize();
          
          if (!_videoController!.value.isInitialized) {
            throw Exception('网络视频控制器初始化失败');
          }
        } catch (e) {
          print('网络视频控制器错误: $e');
          if (_videoController != null) {
            await _videoController!.dispose();
            _videoController = null;
          }
          throw e;
        }
      } else {
        // 处理本地视频
        print('创建本地视频控制器');
        final file = File(item.uri);
        print('文件路径: ${item.uri}');
        print('文件存在: ${file.existsSync()}');
        if (!file.existsSync()) {
          throw Exception('文件不存在: ${item.uri}');
        }
        
        // 只使用 VideoPlayerController.file 方法初始化本地视频
        try {
          _videoController = vp.VideoPlayerController.file(file);
          _videoController!.addListener(_onVideoEvent);
          await _videoController!.initialize();
          
          if (!_videoController!.value.isInitialized) {
            throw Exception('本地视频控制器初始化失败');
          }
        } catch (e) {
          print('本地视频控制器错误: $e');
          if (_videoController != null) {
            await _videoController!.dispose();
            _videoController = null;
          }
          throw e;
        }
      }

      print('视频控制器已创建');
      print('视频控制器初始化成功');
      print('视频时长: ${_videoController!.value.duration}');
      print('视频宽高比: ${_videoController!.value.aspectRatio}');
      print('视频是否播放中: ${_videoController!.value.isPlaying}');
      print('视频是否有错误: ${_videoController!.value.hasError}');
      if (_videoController!.value.hasError) {
        print('视频错误: ${_videoController!.value.errorDescription}');
      }
      
      if (_disposed) {
        await _videoController!.dispose();
        _videoController = null;
        return;
      }

      await _videoController!.setVolume(_state.isMuted ? 0 : _state.volume);
      await _videoController!.setPlaybackSpeed(_state.speed);

      _updateState(_state.copyWith(
        status: autoPlay ? PlayerStatus.playing : PlayerStatus.paused,
        duration: _videoController!.value.duration,
      ));

      if (autoPlay) {
        print('开始视频播放...');
        try {
          await _videoController!.play();
          print('视频播放已开始');
          print('播放后 - 是否播放中: ${_videoController!.value.isPlaying}');
          print('播放后 - 是否有错误: ${_videoController!.value.hasError}');
          if (_videoController!.value.hasError) {
            print('播放后 - 错误: ${_videoController!.value.errorDescription}');
          }
          WakelockPlus.enable();
        } catch (e) {
          print('开始播放错误: $e');
          // Don't throw here, just log the error and continue
        }
      }

      _startPositionTimer();
    } catch (e) {
      print('初始化视频播放器错误: $e');
      _handleError('初始化视频播放器失败: $e');
      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }
      rethrow;
    }
  }

  Future<void> _initAudioPlayerSource(MediaItem item, {bool autoPlay = true}) async {
    ap.Source source;
    if (item.isNetwork) {
      source = ap.UrlSource(item.uri);
    } else {
      source = ap.DeviceFileSource(item.uri);
    }

    _updateState(_state.copyWith(
      status: PlayerStatus.buffering,
      duration: item.duration ?? Duration.zero,
    ));

    if (autoPlay) {
      await _audioPlayer!.play(source);
    } else {
      await _audioPlayer!.setSource(source);
      _updateState(_state.copyWith(status: PlayerStatus.paused));
    }

    _startPositionTimer();
  }

  /// 视频事件监听回调
  void _onVideoEvent() {
    if (_videoController == null || _disposed) return;

    final value = _videoController!.value;
    
    print('_onVideoEvent 被调用');
    print('视频值: isInitialized=${value.isInitialized}, isPlaying=${value.isPlaying}, hasError=${value.hasError}');
    if (value.hasError) {
      print('视频错误: ${value.errorDescription}');
    }
    
    PlayerStatus newStatus = _state.status;
    if (value.isInitialized) {
      if (value.hasError) {
        newStatus = PlayerStatus.error;
        _handleError('视频播放器错误: ${value.errorDescription}');
        // 不要重新初始化，因为这会导致无限循环
        // _reinitializeVideoPlayer();
      } else if (value.isBuffering) {
        newStatus = PlayerStatus.buffering;
      } else if (value.isPlaying) {
        newStatus = PlayerStatus.playing;
      } else if (_state.position >= _state.duration && _state.duration > Duration.zero) {
        newStatus = PlayerStatus.completed;
      } else {
        newStatus = PlayerStatus.paused;
      }
    } else {
      print('视频控制器未初始化');
      newStatus = PlayerStatus.loading;
      // 尝试重新初始化视频播放器
      _reinitializeVideoPlayer();
    }

    _updateState(_state.copyWith(
      status: newStatus,
      position: value.position,
      duration: value.duration,
      buffered: value.buffered.isNotEmpty 
          ? value.buffered.last.end 
          : Duration.zero,
    ));

    if (value.isPlaying) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    if (newStatus == PlayerStatus.completed) {
      _onPlaybackComplete();
    }
  }

  void _reinitializeVideoPlayer() {
    if (_disposed || _state.currentItem == null || _state.currentItem!.type != MediaType.video) {
      return;
    }
    
    // Only try to reinitialize if we haven't tried recently
    if (_lastReinitializeTime != null && DateTime.now().difference(_lastReinitializeTime!).inSeconds < 2) {
      return;
    }
    
    _lastReinitializeTime = DateTime.now();
    print('尝试重新初始化视频播放器...');
    
    // Create a new controller and initialize it
    final currentItem = _state.currentItem!;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        print('重新初始化视频播放器: ${currentItem}');
        
        // Dispose the current controller
        if (_videoController != null) {
          _videoController!.removeListener(_onVideoEvent);
          await _videoController!.dispose();
          _videoController = null;
        }
        
        // Create a new controller
        late vp.VideoPlayerController newController;
        bool initialized = false;
        
        if (currentItem.isNetwork) {
          newController = vp.VideoPlayerController.networkUrl(
            Uri.parse(currentItem.uri),
            httpHeaders: currentItem.headers ?? {},
          );
          _videoController = newController;
          _videoController!.addListener(_onVideoEvent);
          await _videoController!.initialize();
          initialized = _videoController!.value.isInitialized;
        } else {
          final file = File(currentItem.uri);
          if (file.existsSync()) {
            print('文件存在: ${currentItem.uri}');
            // Try different approaches for local files
            List<Function> initMethods = [
              () => vp.VideoPlayerController.file(file),
              () => vp.VideoPlayerController.networkUrl(Uri.file(currentItem.uri)),
              () => vp.VideoPlayerController.networkUrl(Uri.parse('file://${currentItem.uri}')),
            ];
            
            Exception? lastError;
            for (var method in initMethods) {
              try {
                print('尝试初始化方法: $method');
                newController = method();
                
                // Test if this controller works
                if (_videoController != null) {
                  _videoController!.removeListener(_onVideoEvent);
                  await _videoController!.dispose();
                }
                _videoController = newController;
                _videoController!.addListener(_onVideoEvent);
                await _videoController!.initialize();
                
                if (_videoController!.value.isInitialized) {
                  print('初始化成功，方法: $method');
                  initialized = true;
                  break;
                }
              } catch (e) {
                print('初始化方法失败: $e');
                lastError = e as Exception;
                if (_videoController != null) {
                  await _videoController!.dispose();
                  _videoController = null;
                }
              }
            }
          } else {
            print('文件不存在: ${currentItem.uri}');
            _handleError('文件不存在: ${currentItem.uri}');
            return;
          }
        }
        
        if (initialized && _videoController != null) {
          print('Video player reinitialized successfully');
          await _videoController!.setVolume(_state.isMuted ? 0 : _state.volume);
          await _videoController!.setPlaybackSpeed(_state.speed);
          
          // Update state to reflect that video player is initialized
          _updateState(_state.copyWith(
            status: _videoController!.value.isPlaying ? PlayerStatus.playing : PlayerStatus.paused,
            duration: _videoController!.value.duration,
            position: _videoController!.value.position,
          ));
          
          // If we were playing before, resume playback
          if (_state.status == PlayerStatus.playing) {
            await _videoController!.play();
          }
        } else {
          print('Failed to reinitialize video player');
          _handleError('Failed to reinitialize video player');
        }
      } catch (e) {
        print('Error reinitializing video player: $e');
        _handleError('Error reinitializing video player: $e');
      }
    });
  }
  
  DateTime? _lastReinitializeTime;

  Future<void> play() async {
    if (_state.currentItem == null) return;

    try {
      if (_state.currentItem!.type == MediaType.video && _videoController != null) {
        await _videoController!.play();
      } else if (_state.currentItem!.type == MediaType.audio && _audioPlayer != null) {
        await _audioPlayer!.resume();
      }
    } catch (e) {
      _handleError('Failed to play: $e');
    }
  }

  Future<void> pause() async {
    try {
      if (_videoController != null) {
        await _videoController!.pause();
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
      }
    } catch (e) {
      _handleError('Failed to pause: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    if (position < Duration.zero) position = Duration.zero;
    if (position > _state.duration) position = _state.duration;

    try {
      if (_state.currentItem?.type == MediaType.video && _videoController != null) {
        await _videoController!.seekTo(position);
      } else if (_state.currentItem?.type == MediaType.audio && _audioPlayer != null) {
        await _audioPlayer!.seek(position);
      }
      _updateState(_state.copyWith(position: position));
    } catch (e) {
      _handleError('Failed to seek: $e');
    }
  }

  Future<void> seekForward([Duration amount = const Duration(seconds: 10)]) async {
    await seek(_state.position + amount);
  }

  Future<void> seekBackward([Duration amount = const Duration(seconds: 10)]) async {
    await seek(_state.position - amount);
  }

  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    
    try {
      if (_videoController != null) {
        await _videoController!.setVolume(_state.isMuted ? 0 : volume);
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(_state.isMuted ? 0 : volume);
      }
      _updateState(_state.copyWith(volume: volume));
    } catch (e) {
      _handleError('Failed to set volume: $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    speed = speed.clamp(0.5, 2.0);
    
    try {
      if (_videoController != null) {
        await _videoController!.setPlaybackSpeed(speed);
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.setPlaybackRate(speed);
      }
      _updateState(_state.copyWith(speed: speed));
    } catch (e) {
      _handleError('Failed to set speed: $e');
    }
  }

  Future<void> toggleMute() async {
    final newMuted = !_state.isMuted;
    final volume = newMuted ? 0.0 : _state.volume;
    
    try {
      if (_videoController != null) {
        await _videoController!.setVolume(volume);
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(volume);
      }
      _updateState(_state.copyWith(isMuted: newMuted));
    } catch (e) {
      _handleError('Failed to toggle mute: $e');
    }
  }

  Future<void> next() async {
    final currentItem = _playlist.currentItem;
    
    // 如果当前没有项目，直接返回
    if (currentItem == null) return;
    
    // 如果当前播放的是音频，只寻找下一个音频项目
    if (currentItem.type == MediaType.audio) {
      
      // 遍历播放列表，找到下一个音频项目
      for (int i = 0; i < _playlist.length; i++) {
        // 调用原始的next()方法获取下一个项目
        final nextItem = _playlist.next(
          mode: _state.playMode,
          shuffle: _state.isShuffleEnabled,
        );
        
        if (nextItem == null) {
          // 没有更多项目了
          break;
        }
        
        if (nextItem.type == MediaType.audio) {
          // 找到音频项目，播放它
          await playMedia(nextItem);
          return;
        }
        
        // 如果是循环模式，当到达列表末尾时会回到开头
        // 所以需要检查是否回到了起点，避免无限循环
        if (_playlist.currentItem == currentItem) {
          // 已经循环了一圈，没有找到音频项目
          break;
        }
      }
    } else {
      // 其他类型（视频）正常寻找下一个项目
      final nextItem = _playlist.next(
        mode: _state.playMode,
        shuffle: _state.isShuffleEnabled,
      );
      if (nextItem != null) {
        await playMedia(nextItem);
      }
    }
  }

  Future<void> previous() async {
    if (_state.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
    } else {
      final prevItem = _playlist.previous(
        mode: _state.playMode,
        shuffle: _state.isShuffleEnabled,
      );
      if (prevItem != null) {
        await playMedia(prevItem);
      }
    }
  }

  void toggleFullscreen() {
    _updateState(_state.copyWith(isFullscreen: !_state.isFullscreen));
  }

  void setFullscreen(bool fullscreen) {
    if (_state.isFullscreen != fullscreen) {
      _updateState(_state.copyWith(isFullscreen: fullscreen));
    }
  }

  void toggleLock() {
    _updateState(_state.copyWith(isLocked: !_state.isLocked));
  }

  void toggleShuffle() {
    _updateState(_state.copyWith(isShuffleEnabled: !_state.isShuffleEnabled));
  }

  void setPlayMode(PlayMode mode) {
    _updateState(_state.copyWith(playMode: mode));
  }

  /// 设置播放列表项目
  void setPlaylistItems(List<MediaItem> items, {int startIndex = 0}) {
    _playlist.setItems(items, startIndex: startIndex);
    print('播放列表已更新，长度: ${items.length}, 开始索引: $startIndex');
  }

  void cyclePlayMode() {
    const modes = PlayMode.values;
    final nextIndex = (modes.indexOf(_state.playMode) + 1) % modes.length;
    setPlayMode(modes[nextIndex]);
  }

  void showControls() {
    if (!_controlsVisible) {
      _controlsVisible = true;
      notifyListeners();
    }
    _startHideControlsTimer();
  }

  void hideControls() {
    if (_controlsVisible && !_state.isLocked) {
      _controlsVisible = false;
      notifyListeners();
    }
  }

  void toggleControls() {
    if (_controlsVisible) {
      hideControls();
    } else {
      showControls();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_state.isPlaying && !_state.isLocked) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (!_disposed) hideControls();
      });
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_disposed) return;
      
      if (_state.currentItem?.type == MediaType.video && _videoController != null) {
        // Video position is handled by listener
      } else if (_state.currentItem?.type == MediaType.audio && _audioPlayer != null) {
        // Audio position is handled by listener
      }
    });
  }

  void _onPlaybackComplete() {
    switch (_state.playMode) {
      case PlayMode.singleLoop:
        seek(Duration.zero).then((_) => play());
        break;
      case PlayMode.loop:
      case PlayMode.sequence:
      case PlayMode.shuffle:
        next();
        break;
    }
  }

  void _updateState(PlayerState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_disposed) {
        notifyListeners();
        _stateController.add(_state);
      }
    }
  }

  void _handleError(String message) {
    _updateState(_state.copyWith(
      status: PlayerStatus.error,
      errorMessage: message,
    ));
  }

  Future<void> disposeCurrentPlayer() async {
    _positionTimer?.cancel();
    
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoEvent);
      await _videoController!.dispose();
      _videoController = null;
    }
    
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
    }
    
    WakelockPlus.disable();
  }

  @override
  void dispose() {
    _disposed = true;
    _positionTimer?.cancel();
    _hideControlsTimer?.cancel();
    _stateController.close();
    
    _videoController?.removeListener(_onVideoEvent);
    _videoController?.dispose();
    _audioPlayer?.dispose();
    
    WakelockPlus.disable();
    super.dispose();
  }
}
