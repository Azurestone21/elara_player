// providers/app_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class AppStateNotifier extends ChangeNotifier {
  bool _isMiniMode = false;
  Size? _lastSize;
  Offset? _lastPosition;

  bool get isMiniMode => _isMiniMode;

  Future<void> enterMiniMode() async {
    if (_isMiniMode) return;

    // 保存当前窗口尺寸和位置
    _lastSize = await windowManager.getSize();
    _lastPosition = await windowManager.getPosition();

    // 切换到迷你模式：先临时解除最小尺寸限制
    await windowManager.setMinimumSize(const Size(1, 1));
    // 设置迷你窗口尺寸（内容区域）
    await windowManager.setSize(const Size(320, 72));
    // 设置无边框、置顶、右下角对齐
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setAlignment(Alignment.bottomRight);

    _isMiniMode = true;
    notifyListeners();
  }

  Future<void> exitMiniMode() async {
    if (!_isMiniMode) return;

    // 恢复窗口尺寸和位置
    if (_lastSize != null) await windowManager.setSize(_lastSize!);
    if (_lastPosition != null) await windowManager.setPosition(_lastPosition!);
    // 恢复最小尺寸（设置一个较大的值让窗口可以正常缩放）
    await windowManager.setMinimumSize(const Size(700, 600));
    await windowManager.setAlwaysOnTop(false);
    // 如需恢复标题栏样式，可取消注释
    // await windowManager.setTitleBarStyle(TitleBarStyle.normal);

    _isMiniMode = false;
    notifyListeners();
  }
}

final appStateProvider = ChangeNotifierProvider<AppStateNotifier>(
  (ref) => AppStateNotifier(),
);