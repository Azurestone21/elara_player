import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 视频分类状态提供者
final videoCategoryProvider = StateProvider<String>((ref) => '');

/// 音频分类状态提供者
final audioCategoryProvider = StateProvider<String>((ref) => '');
