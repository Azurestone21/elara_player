import 'package:flutter/material.dart';
import '../src.dart';
import 'routes.dart';

// 路由表
class AppRouter {
  static final Map<String, Widget Function(BuildContext)> routes = {
    Routes.home: (context) => const HomePage(),
    Routes.musicPlayer: (context) => const MusicPlayerPage(),
    Routes.videoPlayer: (context) => const VideoPlayerPage(),
    Routes.settings: (context) => const SettingsPage(),
  };

  // 统一跳转方法
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  // 返回
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  // 替换页面（无法返回）
  static Future<T?> pushReplacement<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  // 清空所有页面，进入新页面
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}