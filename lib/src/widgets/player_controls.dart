import 'package:flutter/material.dart';
import '../models/models.dart';
import 'progress_bar.dart';

class PlayerControls extends StatelessWidget {
  final PlayerState state;
  final bool visible;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleMute;
  final ValueChanged<double>? onVolumeChange;
  final ValueChanged<double>? onSpeedChange;
  final VoidCallback? onToggleLock;
  final VoidCallback? onCyclePlayMode;

  const PlayerControls({
    super.key,
    required this.state,
    this.visible = true,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onSeek,
    this.onToggleFullscreen,
    this.onToggleMute,
    this.onVolumeChange,
    this.onSpeedChange,
    this.onToggleLock,
    this.onCyclePlayMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isLocked)
                _buildLockedControls()
              else ...[
                _buildTopBar(),
                const Spacer(),
                _buildProgressBar(),
                const SizedBox(height: 12),
                _buildMainControls(),
                const SizedBox(height: 8),
                _buildBottomBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedControls() {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton(
        onPressed: onToggleLock,
        icon: const Icon(Icons.lock_outline, color: Colors.white),
        tooltip: 'Unlock',
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Text(
            state.currentItem?.title ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onToggleLock != null)
          IconButton(
            onPressed: onToggleLock,
            icon: const Icon(Icons.lock_open_outlined, color: Colors.white),
            tooltip: 'Lock controls',
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return ProgressBarWithTime(
      position: state.position,
      duration: state.duration,
      buffered: state.buffered,
      onSeek: onSeek,
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onCyclePlayMode != null) _buildPlayModeButton(),
        const SizedBox(width: 16),
        if (onPrevious != null)
          _ControlButton(
            icon: Icons.skip_previous,
            onPressed: state.hasPrevious ? onPrevious : null,
            size: 40,
          ),
        const SizedBox(width: 16),
        _PlayPauseButton(
          isPlaying: state.isPlaying,
          onPressed: onPlayPause,
          size: 64,
        ),
        const SizedBox(width: 16),
        if (onNext != null)
          _ControlButton(
            icon: Icons.skip_next,
            onPressed: state.hasNext ? onNext : null,
            size: 40,
          ),
        const SizedBox(width: 16),
        if (onSpeedChange != null)
          _SpeedButton(
            speed: state.speed,
            onSpeedChange: onSpeedChange!,
          ),
      ],
    );
  }

  Widget _buildPlayModeButton() {
    IconData icon;
    String tooltip;

    switch (state.playMode) {
      case PlayMode.sequence:
        icon = Icons.repeat;
        tooltip = 'Sequence';
        break;
      case PlayMode.loop:
        icon = Icons.repeat;
        tooltip = 'Loop all';
        break;
      case PlayMode.singleLoop:
        icon = Icons.repeat_one;
        tooltip = 'Loop one';
        break;
      case PlayMode.shuffle:
        icon = Icons.shuffle;
        tooltip = 'Shuffle';
        break;
    }

    return IconButton(
      onPressed: onCyclePlayMode,
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
    );
  }

  Widget _buildBottomBar() {
    return Row(
      children: [
        if (onToggleMute != null)
          _VolumeControl(
            volume: state.volume,
            isMuted: state.isMuted,
            onToggleMute: onToggleMute!,
            onVolumeChange: onVolumeChange,
          ),
        const Spacer(),
        if (state.isBuffering)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        const SizedBox(width: 16),
        if (onToggleFullscreen != null)
          IconButton(
            onPressed: onToggleFullscreen,
            icon: Icon(
              state.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            tooltip: state.isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  const _ControlButton({
    required this.icon,
    this.onPressed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon:
          Icon(icon, color: onPressed != null ? Colors.white : Colors.white38),
      iconSize: size,
      padding: EdgeInsets.zero,
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;
  final double size;

  const _PlayPauseButton({
    required this.isPlaying,
    this.onPressed,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
        ),
        iconSize: size * 0.5,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final double volume;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final ValueChanged<double>? onVolumeChange;

  const _VolumeControl({
    required this.volume,
    required this.isMuted,
    required this.onToggleMute,
    this.onVolumeChange,
  });

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  bool _showSlider = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showSlider = true),
      onExit: (_) => setState(() => _showSlider = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: widget.onToggleMute,
            icon: Icon(
              widget.isMuted || widget.volume == 0
                  ? Icons.volume_off
                  : widget.volume < 0.5
                      ? Icons.volume_down
                      : Icons.volume_up,
              color: Colors.white,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _showSlider ? 100 : 0,
            child: _showSlider
                ? Slider(
                    value: widget.isMuted ? 0 : widget.volume,
                    onChanged: widget.onVolumeChange,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onSpeedChange;

  const _SpeedButton({
    required this.speed,
    required this.onSpeedChange,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      onSelected: onSpeedChange,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 0.75, child: Text('0.75x')),
        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${speed}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
