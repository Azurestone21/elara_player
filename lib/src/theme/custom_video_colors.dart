import 'package:flutter/material.dart';

/// 自定义视频颜色主题扩展
class CustomVideoColors extends ThemeExtension<CustomVideoColors> {
  // 自定义颜色属性
  final Color progressBarBgColor;
  final Color timeColor;

  // 构造函数
  const CustomVideoColors({
    required this.progressBarBgColor,
    required this.timeColor,
  });

  // 实现 copyWith 方法（可选字段，用于部分更新）
  @override
  CustomVideoColors copyWith({
    Color? progressBarBgColor,
    Color? timeColor,
  }) {
    return CustomVideoColors(
      progressBarBgColor: progressBarBgColor ?? this.progressBarBgColor,
      timeColor: timeColor ?? this.timeColor,
    );
  }

  // 实现 lerp 方法（用于主题切换时的平滑过渡）
  @override
  CustomVideoColors lerp(ThemeExtension<CustomVideoColors>? other, double t) {
    if (other is! CustomVideoColors) return this;
    return CustomVideoColors(
      progressBarBgColor:
          Color.lerp(progressBarBgColor, other.progressBarBgColor, t)!,
      timeColor: Color.lerp(timeColor, other.timeColor, t)!,
    );
  }
}
