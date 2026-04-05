import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../src.dart';

/// 自定义AppBar（桌面端）
class WindowsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackBefore;
  final Color? bgColor;
  final Color? color;
  final String? title;
  final Widget? leftWidget;
  final bool hideBackButton;

  const WindowsAppBar({
    super.key,
    this.onBackBefore,
    this.hideBackButton = false,
    this.bgColor,
    this.color,
    this.title,
    this.leftWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: Container(
        // decoration: BoxDecoration(
        //   color: bgColor ?? Colors.white,
        //   border:
        //       Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
        // ),
        child: Row(
          children: [
            hideBackButton
                ? Container()
                :
                // 返回
                IconButton(
                    onPressed: () {
                      onBackBefore?.call();
                      AppRouter.pop();
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: color ?? theme.appBarTheme.foregroundColor,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),

            const SizedBox(width: 16),

            // 标题
            SizedBox(
              child: GestureDetector(
                onPanStart: (details) => windowManager.startDragging(),
                child: Text(
                  title ?? 'Elara Player',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color ?? theme.appBarTheme.foregroundColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(width: 16),

            if (leftWidget != null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leftWidget!,
                ),
              ),

            const Spacer(),

            // 设置
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.settings,
                size: 16,
                color: color ?? theme.appBarTheme.foregroundColor,
              ),
              padding: EdgeInsets.zero,
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // Window controls
            WindowControls(color: color),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}
