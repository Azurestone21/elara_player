import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as vp;
import '../models/models.dart';

/// 视频播放器视图组件
class VideoPlayerView extends StatelessWidget {
  /// 视频控制器
  final vp.VideoPlayerController? controller;
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
  Widget build(BuildContext context) {
    print('VideoPlayerView build 被调用');
    print('控制器: $controller');
    print('控制器已初始化: ${controller?.value.isInitialized}');
    print('播放器状态: ${state.status}');
    print('当前项目: ${state.currentItem?.title}');
    print('当前项目类型: ${state.currentItem?.type}');

    if (controller == null) {
      print('控制器为空');
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('视频控制器未初始化', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    print('控制器已初始化: ${controller!.value.isInitialized}');
    print('控制器有错误: ${controller!.value.hasError}');
    if (controller!.value.hasError) {
      print('控制器错误: ${controller!.value.errorDescription}');
    }

    // 始终构建视频播放器，即使未初始化
    // 这允许视频播放器处理自己的状态并可能恢复
    print('正在构建视频播放器');
    print('视频时长: ${controller!.value.duration}');
    print('视频宽高比: ${controller!.value.aspectRatio}');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller!.value.isInitialized ? controller!.value.aspectRatio : 16/9,
            child: vp.VideoPlayer(controller!),
          ),
        ),
      ),
    );
  }
}
