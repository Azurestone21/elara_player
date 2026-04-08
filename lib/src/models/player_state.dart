import 'package:flutter/foundation.dart';
import 'media_item.dart';

enum PlayerStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

@immutable
class PlayerState {
  final PlayerStatus status;
  final MediaItem? currentItem;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final double volume;
  final double speed;
  final bool isMuted;
  final bool isFullscreen;
  final bool isLocked;
  final String? errorMessage;
  final bool isShuffleEnabled;
  final PlayMode playMode;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentItem,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.isMuted = false,
    this.isFullscreen = false,
    this.isLocked = false,
    this.errorMessage,
    this.isShuffleEnabled = false,
    this.playMode = PlayMode.sequence,
  });

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isPaused => status == PlayerStatus.paused;
  bool get isLoading => status == PlayerStatus.loading;
  bool get isBuffering => status == PlayerStatus.buffering;
  bool get hasError => status == PlayerStatus.error;
  bool get isIdle => status == PlayerStatus.idle;
  bool get isCompleted => status == PlayerStatus.completed;
  bool get hasPrevious => true;
  bool get hasNext => true;

  double get progress => duration.inMilliseconds > 0
      ? position.inMilliseconds / duration.inMilliseconds
      : 0.0;

  double get bufferedProgress => duration.inMilliseconds > 0
      ? buffered.inMilliseconds / duration.inMilliseconds
      : 0.0;

  PlayerState copyWith({
    PlayerStatus? status,
    MediaItem? currentItem,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    double? volume,
    double? speed,
    bool? isMuted,
    bool? isFullscreen,
    bool? isLocked,
    String? errorMessage,
    bool? isShuffleEnabled,
    PlayMode? playMode,
    bool clearError = false,
    bool clearCurrentItem = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      isMuted: isMuted ?? this.isMuted,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isLocked: isLocked ?? this.isLocked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      playMode: playMode ?? this.playMode,
    );
  }

  @override
  String toString() {
    return 'PlayerState(status: $status, position: $position, duration: $duration, volume: $volume, speed: $speed)';
  }
}
