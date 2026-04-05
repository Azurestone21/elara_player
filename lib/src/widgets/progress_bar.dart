import 'package:flutter/material.dart';
import '../src.dart';

class ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final CustomVideoColors? customColors;

  const ProgressBar({
    super.key,
    required this.position,
    required this.duration,
    this.buffered = Duration.zero,
    this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    this.customColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final bufferedProgress = duration.inMilliseconds > 0
        ? buffered.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          onHorizontalDragStart: (_) => onSeekStart?.call(),
          onHorizontalDragEnd: (_) => onSeekEnd?.call(),
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final percent = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
            onSeek?.call(Duration(
                milliseconds: (percent * duration.inMilliseconds).toInt()));
          },
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final percent = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
            onSeek?.call(Duration(
                milliseconds: (percent * duration.inMilliseconds).toInt()));
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 20,
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: customColors?.progressBarBgColor ??
                          theme.sliderTheme.inactiveTrackColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: width * bufferedProgress,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: width * progress,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: (width - 12) * progress,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProgressBarWithTime extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final CustomVideoColors? customColors;

  const ProgressBarWithTime({
    super.key,
    required this.position,
    required this.duration,
    this.buffered = Duration.zero,
    this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    this.customColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ProgressBar(
            position: position,
            duration: duration,
            buffered: buffered,
            onSeek: onSeek,
            onSeekStart: onSeekStart,
            onSeekEnd: onSeekEnd,
            customColors: customColors,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          '${FormatUtils.formatDuration(position)} / ${FormatUtils.formatDuration(duration)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: customColors?.timeColor ?? null,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
