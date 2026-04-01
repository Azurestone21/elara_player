import 'package:flutter/material.dart';

/// 按钮（主色调）
class AddPrimaryBtn extends StatelessWidget {
  final VoidCallback onPressed;

  final String? text;
  final IconData? icon;

  const AddPrimaryBtn({super.key, this.text, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final commonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
    final textStyle = commonStyle.copyWith(
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
    final iconStyle = commonStyle.copyWith(
      shape: MaterialStateProperty.all(const CircleBorder()),
      padding: MaterialStateProperty.all(
        const EdgeInsets.all(0),
      ),
      minimumSize: MaterialStateProperty.all(
        const Size(40, 40),
      ),
    );

    // 图标和文本
    if (icon != null && text != null) {
      return SizedBox(
        width: 44,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon!),
          label: Text(text!),
          style: textStyle,
        ),
      );
    }

    // 仅文本
    if (icon == null && text != null) {
      return ElevatedButton(
        onPressed: onPressed,
        style: textStyle,
        child: Text(text!),
      );
    }

    // 仅图标
    if (icon != null && text == null) {
      return ElevatedButton(
        onPressed: onPressed,
        style: iconStyle,
        child: Icon(icon!),
      );
    }

    return Container();
  }
}
