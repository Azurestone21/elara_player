import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/models.dart';

/// 视频播放器视图组件
class VideoPlayerView extends StatefulWidget {
  /// 视频控制器
  final VideoController? controller;

  /// 播放器状态
  final PlayerState state;

  /// 点击回调
  final VoidCallback? onTap;

  /// 构造函数
  const VideoPlayerView({
    super.key,
    this.controller,
    required this.state,
    this.onTap,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('视频控制器未初始化', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // 始终构建视频播放器，即使未初始化
    // 这允许视频播放器处理自己的状态并可能恢复

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Video(controller: widget.controller!),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
