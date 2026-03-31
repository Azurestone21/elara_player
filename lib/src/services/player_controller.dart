import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';
import '../models/models.dart';
import 'playlist_service.dart';

/// 播放器控制器提供者，用于全局访问播放器实例
final playerControllerProvider =
    ChangeNotifierProvider<PlayerController>((ref) {
  return PlayerController();
});

/// 播放器控制器类，负责管理音频和视频的播放
class PlayerController extends ChangeNotifier {
  /// 播放列表服务
  final PlaylistService _playlist = PlaylistService();

  /// 视频播放器控制器
  mk.Player? _videoPlayer;
  VideoController? _videoController;

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
  VideoController? get videoController => _videoController;

  /// 状态流，用于监听播放器状态变化
  Stream<PlayerState> get stateStream => _stateController.stream;
  final _stateController = StreamController<PlayerState>.broadcast();

  /// 视频播放器监听器订阅
  List<StreamSubscription> _videoPlayerSubscriptions = [];

  /// 防止play方法递归调用的标志
  bool _isPlaying = false;

  /// 防止playMedia方法递归调用的标志
  bool _isPlayingMedia = false;

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
    if (_isPlayingMedia) return;

    try {
      _isPlayingMedia = true;
      await disposeCurrentPlayer(); // 释放当前播放器

      // 更新状态为加载中
      _updateState(_state.copyWith(
        status: PlayerStatus.loading,
        currentItem: item,
        position: Duration.zero,
        duration: Duration.zero,
        buffered: Duration.zero,
        clearError: true,
      ));

      // 根据媒体类型初始化对应的播放器
      if (item.type == MediaType.video) {
        await _initVideoPlayer(item, autoPlay: autoPlay);
      } else {
        await _initAudioPlayerSource(item, autoPlay: autoPlay);
      }
    } catch (e) {
      _handleError('Failed to play media: $e');
    } finally {
      _isPlayingMedia = false;
    }
  }

  /// 初始化视频播放器
  /// [item] 媒体项
  /// [autoPlay] 是否自动播放
  Future<void> _initVideoPlayer(MediaItem item, {bool autoPlay = true}) async {
    // 创建局部变量来存储播放器实例，避免在异步操作中被意外修改
    mk.Player? localPlayer;
    VideoController? localController;
    List<StreamSubscription> localSubscriptions = [];

    try {
      // 释放现有的视频播放器
      if (_videoPlayer != null) {
        await _videoPlayer!.dispose();
        _videoPlayer = null;
      }
      if (_videoController != null) {
        _videoController = null;
      }

      // 清除之前的订阅
      for (var subscription in _videoPlayerSubscriptions) {
        subscription.cancel();
      }
      _videoPlayerSubscriptions.clear();

      // 创建新的播放器
      localPlayer = mk.Player();
      localController = VideoController(localPlayer);

      // 监听视频播放器状态变化
      localSubscriptions.add(localPlayer.stream.playing.listen((playing) {
        if (_disposed || _videoPlayer == null) return;
        _updateState(_state.copyWith(
            status: playing ? PlayerStatus.playing : PlayerStatus.paused));
      }));

      // 监听播放位置变化
      localSubscriptions.add(localPlayer.stream.position.listen((position) {
        if (_disposed || _videoPlayer == null) return;
        _updateState(_state.copyWith(position: position));
      }));

      // 监听时长变化
      localSubscriptions.add(localPlayer.stream.duration.listen((duration) {
        if (_disposed || _videoPlayer == null) return;
        _updateState(_state.copyWith(duration: duration ?? Duration.zero));
      }));

      // 监听播放完成
      localSubscriptions.add(localPlayer.stream.completed.listen((completed) {
        if (_disposed || _videoPlayer == null) return;
        if (completed) {
          _onPlaybackComplete();
        }
      }));

      // 设置播放源
      await localPlayer.open(mk.Media(item.uri));

      // 设置音量和播放速度
      // media_kit的音量范围是0-100，所以需要将0-1的音量值转换为0-100
      final mediaKitVolume = _state.isMuted ? 0.0 : _state.volume * 100;
      await localPlayer.setVolume(mediaKitVolume);
      await localPlayer.setRate(_state.speed);

      if (_disposed) {
        await localPlayer.dispose();
        for (var subscription in localSubscriptions) {
          subscription.cancel();
        }
        return;
      }

      // 将局部变量赋值给成员变量
      _videoPlayer = localPlayer;
      _videoController = localController;
      _videoPlayerSubscriptions = localSubscriptions;

      _updateState(_state.copyWith(
        status: autoPlay ? PlayerStatus.playing : PlayerStatus.paused,
        duration: _videoPlayer!.state.duration ?? Duration.zero,
      ));

      if (autoPlay) {
        try {
          await _videoPlayer!.play();
          WakelockPlus.enable();
        } catch (e) {
          // Don't throw here, just log the error and continue
          print('开始播放错误: $e');
        }
      }

      _startPositionTimer();
    } catch (e) {
      _handleError('初始化视频播放器失败: $e');

      // 释放局部播放器实例
      if (localPlayer != null) {
        await localPlayer.dispose();
      }

      // 取消局部订阅
      for (var subscription in localSubscriptions) {
        subscription.cancel();
      }

      // 确保成员变量被重置
      _videoPlayer = null;
      _videoController = null;

      rethrow;
    }
  }

  Future<void> _initAudioPlayerSource(MediaItem item,
      {bool autoPlay = true}) async {
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

  Future<void> play() async {
    if (_state.currentItem == null || _isPlaying) return;

    try {
      _isPlaying = true;
      if (_state.currentItem!.type == MediaType.video && _videoPlayer != null) {
        // 检查_videoPlayer是否仍然有效
        try {
          // 再次检查_videoPlayer是否为null，因为可能在异步操作期间被释放
          if (_videoPlayer != null) {
            // 使用局部变量来确保在异步操作中不会被修改
            final player = _videoPlayer;
            if (player != null) {
              await player.play();
            } else {
              await playMedia(_state.currentItem!);
            }
          } else {
            await playMedia(_state.currentItem!);
          }
        } catch (e) {
          // 如果播放器已被释放，重新初始化
          if (e.toString().contains('has been disposed')) {
            await playMedia(_state.currentItem!);
          } else {
            _handleError('播放视频失败: $e');
          }
        }
      } else if (_state.currentItem!.type == MediaType.audio &&
          _audioPlayer != null) {
        await _audioPlayer!.resume();
      }
    } catch (e) {
      _handleError('Failed to play: $e');
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> pause() async {
    try {
      if (_videoPlayer != null) {
        try {
          await _videoPlayer!.pause();
        } catch (e) {
          // 如果播放器已被释放，忽略错误
          if (!e.toString().contains('has been disposed')) {
            _handleError('暂停视频失败: $e');
          }
        }
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
      if (_state.currentItem?.type == MediaType.video && _videoPlayer != null) {
        try {
          await _videoPlayer!.seek(position);
        } catch (e) {
          // 如果播放器已被释放，忽略错误
          if (!e.toString().contains('has been disposed')) {
            _handleError('视频跳转失败: $e');
          }
        }
      } else if (_state.currentItem?.type == MediaType.audio &&
          _audioPlayer != null) {
        await _audioPlayer!.seek(position);
      }
      _updateState(_state.copyWith(position: position));
    } catch (e) {
      _handleError('Failed to seek: $e');
    }
  }

  Future<void> seekForward(
      [Duration amount = const Duration(seconds: 10)]) async {
    await seek(_state.position + amount);
  }

  Future<void> seekBackward(
      [Duration amount = const Duration(seconds: 10)]) async {
    await seek(_state.position - amount);
  }

  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);

    try {
      // media_kit的音量范围是0-100，所以需要将0-1的音量值转换为0-100
      final mediaKitVolume = _state.isMuted ? 0.0 : volume * 100;
      if (_videoPlayer != null) {
        await _videoPlayer!.setVolume(mediaKitVolume);
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(_state.isMuted ? 0.0 : volume);
      }
      _updateState(_state.copyWith(volume: volume));
    } catch (e) {
      _handleError('Failed to set volume: $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    speed = speed.clamp(0.5, 2.0);

    try {
      if (_videoPlayer != null) {
        await _videoPlayer!.setRate(speed);
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
    // media_kit的音量范围是0-100，所以需要将0-1的音量值转换为0-100
    final mediaKitVolume = newMuted ? 0.0 : _state.volume * 100;
    final audioVolume = newMuted ? 0.0 : _state.volume;

    try {
      if (_videoPlayer != null) {
        await _videoPlayer!.setVolume(mediaKitVolume);
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(audioVolume);
      }
      _updateState(_state.copyWith(isMuted: newMuted));
    } catch (e) {
      _handleError('Failed to toggle mute: $e');
    }
  }

  /// 下一个项目
  Future<void> next() async {
    final currentItem = _playlist.currentItem;

    // 如果当前没有项目，直接返回
    if (currentItem == null) return;

    // 调用next()方法获取下一个项目
    final nextItem = _playlist.next(
      mode: _state.playMode,
      shuffle: _state.isShuffleEnabled,
    );

    if (nextItem == null) {
      // 没有更多项目了
      await pause();
      // 暂停播放后，更新状态为暂停
      _updateState(_state.copyWith(status: PlayerStatus.paused));
    } else {
      // 如果是循环模式，当到达列表末尾时会回到开头，需要检查是否回到了起点，避免无限循环
      if (_state.playMode == PlayMode.loop && currentItem == nextItem) {
        return;
      }
      await playMedia(nextItem);
    }
  }

  /// 上一个项目
  Future<void> previous() async {
    if (_state.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
    } else {
      final currentItem = _playlist.currentItem;

      if (currentItem == null) return;

      // 调用previous()方法获取上一个项目
      final prevItem = _playlist.previous(
        mode: _state.playMode,
        shuffle: _state.isShuffleEnabled,
      );
      if (prevItem == null) {
        // 没有更多项目了
        await pause();
        // 暂停播放后，更新状态为暂停
        _updateState(_state.copyWith(status: PlayerStatus.paused));
      } else {
        await playMedia(prevItem);
      }
    }
  }

  void toggleFullscreen() async {
    final newFullscreen = !_state.isFullscreen;
    _updateState(_state.copyWith(isFullscreen: newFullscreen));

    if (UniversalPlatform.isWindows) {
      if (newFullscreen) {
        await windowManager.setFullScreen(true);
      } else {
        await windowManager.setFullScreen(false);
      }
    }
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

    // 取消所有视频播放器监听器订阅
    for (var subscription in _videoPlayerSubscriptions) {
      subscription.cancel();
    }
    _videoPlayerSubscriptions.clear();

    if (_videoPlayer != null) {
      await _videoPlayer!.dispose();
      _videoPlayer = null;
    }
    if (_videoController != null) {
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

    // 取消所有视频播放器监听器订阅
    for (var subscription in _videoPlayerSubscriptions) {
      subscription.cancel();
    }
    _videoPlayerSubscriptions.clear();

    _videoPlayer?.dispose();
    _videoController = null;
    _audioPlayer?.dispose();

    WakelockPlus.disable();
    super.dispose();
  }
}
