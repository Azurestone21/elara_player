import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

class PlayerGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDoubleTapLeft;
  final VoidCallback? onDoubleTapRight;
  final Function(Offset delta)? onHorizontalDragUpdate;
  final Function(Offset delta, bool isLeftSide)? onVerticalDragUpdate;
  final VoidCallback? onHorizontalDragStart;
  final VoidCallback? onHorizontalDragEnd;
  final VoidCallback? onLongPress;
  final VoidCallback? onMouseMove;

  const PlayerGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onDoubleTapLeft,
    this.onDoubleTapRight,
    this.onHorizontalDragUpdate,
    this.onVerticalDragUpdate,
    this.onHorizontalDragStart,
    this.onHorizontalDragEnd,
    this.onLongPress,
    this.onMouseMove,
  });

  @override
  State<PlayerGestureDetector> createState() => _PlayerGestureDetectorState();
}

class _PlayerGestureDetectorState extends State<PlayerGestureDetector> {
  bool _isHorizontalDrag = false;
  Offset _dragStartPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop) {
      return _buildDesktopDetector();
    }
    return _buildMobileDetector();
  }

  Widget _buildMobileDetector() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onDoubleTapDown: (details) {
        final width = context.size?.width ?? MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width / 2) {
          widget.onDoubleTapLeft?.call();
        } else {
          widget.onDoubleTapRight?.call();
        }
      },
      onHorizontalDragStart: (_) {
        _isHorizontalDrag = true;
        widget.onHorizontalDragStart?.call();
      },
      onHorizontalDragUpdate: (details) {
        if (_isHorizontalDrag) {
          widget.onHorizontalDragUpdate?.call(details.delta);
        }
      },
      onHorizontalDragEnd: (_) {
        _isHorizontalDrag = false;
        widget.onHorizontalDragEnd?.call();
      },
      onVerticalDragStart: (details) {
        _isHorizontalDrag = false;
        _dragStartPosition = details.globalPosition;
      },
      onVerticalDragUpdate: (details) {
        if (!_isHorizontalDrag && widget.onVerticalDragUpdate != null) {
          final width = context.size?.width ?? MediaQuery.of(context).size.width;
          final isLeftSide = _dragStartPosition.dx < width / 2;
          widget.onVerticalDragUpdate!(details.delta, isLeftSide);
        }
      },
      onLongPress: widget.onLongPress,
      child: widget.child,
    );
  }

  Widget _buildDesktopDetector() {
    return MouseRegion(
      onHover: (event) {
        widget.onMouseMove?.call();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: widget.child,
      ),
    );
  }
}

class VolumeBrightnessGesture extends StatefulWidget {
  final Widget child;
  final ValueChanged<double>? onVolumeChange;
  final ValueChanged<double>? onBrightnessChange;

  const VolumeBrightnessGesture({
    super.key,
    required this.child,
    this.onVolumeChange,
    this.onBrightnessChange,
  });

  @override
  State<VolumeBrightnessGesture> createState() => _VolumeBrightnessGestureState();
}

class _VolumeBrightnessGestureState extends State<VolumeBrightnessGesture> {
  double _currentVolume = 0.5;
  double _currentBrightness = 0.5;
  bool _showIndicator = false;
  String _indicatorText = '';
  IconData _indicatorIcon = Icons.volume_up;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showVolumeIndicator(double volume) {
    setState(() {
      _showIndicator = true;
      _currentVolume = volume.clamp(0.0, 1.0);
      _indicatorText = '${(_currentVolume * 100).toInt()}%';
      _indicatorIcon = _currentVolume == 0
          ? Icons.volume_off
          : _currentVolume < 0.3
              ? Icons.volume_mute
              : _currentVolume < 0.7
                  ? Icons.volume_down
                  : Icons.volume_up;
    });
    _startHideTimer();
  }

  void _showBrightnessIndicator(double brightness) {
    setState(() {
      _showIndicator = true;
      _currentBrightness = brightness.clamp(0.0, 1.0);
      _indicatorText = '${(_currentBrightness * 100).toInt()}%';
      _indicatorIcon = _currentBrightness < 0.3
          ? Icons.brightness_low
          : _currentBrightness < 0.7
              ? Icons.brightness_medium
              : Icons.brightness_high;
    });
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _showIndicator = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PlayerGestureDetector(
          onVerticalDragUpdate: (delta, isLeftSide) {
            if (!PlatformUtils.isMobile) return;
            
            final deltaPercent = -delta.dy / 300;
            
            if (isLeftSide) {
              _currentBrightness = (_currentBrightness + deltaPercent).clamp(0.0, 1.0);
              _showBrightnessIndicator(_currentBrightness);
              widget.onBrightnessChange?.call(_currentBrightness);
            } else {
              _currentVolume = (_currentVolume + deltaPercent).clamp(0.0, 1.0);
              _showVolumeIndicator(_currentVolume);
              widget.onVolumeChange?.call(_currentVolume);
            }
          },
          child: widget.child,
        ),
        if (_showIndicator)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_indicatorIcon, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    _indicatorText,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: _indicatorIcon == Icons.brightness_high ||
                              _indicatorIcon == Icons.brightness_medium ||
                              _indicatorIcon == Icons.brightness_low
                          ? _currentBrightness
                          : _currentVolume,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
