import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口控制组件
class WindowControls extends StatelessWidget {
  final Color? color;

  const WindowControls({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: () => windowManager.minimize(),
          icon: Icon(
            Icons.remove,
            size: 16,
            color: color ?? theme.appBarTheme.foregroundColor,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          tooltip: '最小化',
        ),
        IconButton(
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          icon: Icon(
            Icons.square_outlined,
            size: 16,
            color: color ?? theme.appBarTheme.foregroundColor,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          tooltip: '最大化',
        ),
        IconButton(
          onPressed: () => windowManager.close(),
          icon: Icon(
            Icons.close,
            size: 16,
            color: color ?? theme.appBarTheme.foregroundColor,
          ),
          padding: EdgeInsets.zero,
          iconSize: 16,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          tooltip: '关闭',
        ),
      ],
    );
  }
}
