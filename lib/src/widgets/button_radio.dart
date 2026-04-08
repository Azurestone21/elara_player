import 'package:flutter/material.dart';

/// 单选按钮组件
class ButtonRadio extends StatelessWidget {
  /// 当前选中的选项卡索引
  final int value;

  /// 当前选项列表
  final List<Map<String, dynamic>> options;

  /// 选项点击事件
  final Function(dynamic) onChange;

  /// 构造函数
  /// [value] 当前选中索引
  /// [options] 当前选项列表
  const ButtonRadio(
      {super.key,
      required this.value,
      required this.options,
      required this.onChange});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        children: options.asMap().entries.map((item) {
          int index = item.key;
          Map<String, dynamic> option = item.value;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChange(option['value'] as int),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == option['value']
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft:
                        index == 0 ? const Radius.circular(8) : Radius.zero,
                    bottomLeft:
                        index == 0 ? const Radius.circular(8) : Radius.zero,
                    topRight: index == options.length - 1
                        ? const Radius.circular(8)
                        : Radius.zero,
                    bottomRight: index == options.length - 1
                        ? const Radius.circular(8)
                        : Radius.zero,
                  ),
                ),
                child: Text(
                  option['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: value == option['value']
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: value == option['value']
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
