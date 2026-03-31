import 'package:flutter/foundation.dart';

enum AppThemeMode { light, dark, system }

@immutable
class AppSettings {
  final AppThemeMode themeMode;
  final double defaultVolume;
  final double defaultSpeed;
  final bool autoPlay;
  final bool rememberPosition;
  final bool enableHardwareAcceleration;
  final String? defaultDownloadPath;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.defaultVolume = 1.0,
    this.defaultSpeed = 1.0,
    this.autoPlay = true,
    this.rememberPosition = true,
    this.enableHardwareAcceleration = true,
    this.defaultDownloadPath,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    double? defaultVolume,
    double? defaultSpeed,
    bool? autoPlay,
    bool? rememberPosition,
    bool? enableHardwareAcceleration,
    String? defaultDownloadPath,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      defaultSpeed: defaultSpeed ?? this.defaultSpeed,
      autoPlay: autoPlay ?? this.autoPlay,
      rememberPosition: rememberPosition ?? this.rememberPosition,
      enableHardwareAcceleration:
          enableHardwareAcceleration ?? this.enableHardwareAcceleration,
      defaultDownloadPath: defaultDownloadPath ?? this.defaultDownloadPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'defaultVolume': defaultVolume,
      'defaultSpeed': defaultSpeed,
      'autoPlay': autoPlay,
      'rememberPosition': rememberPosition,
      'enableHardwareAcceleration': enableHardwareAcceleration,
      'defaultDownloadPath': defaultDownloadPath,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values[json['themeMode'] ?? 2],
      defaultVolume: json['defaultVolume'] ?? 1.0,
      defaultSpeed: json['defaultSpeed'] ?? 1.0,
      autoPlay: json['autoPlay'] ?? true,
      rememberPosition: json['rememberPosition'] ?? true,
      enableHardwareAcceleration: json['enableHardwareAcceleration'] ?? true,
      defaultDownloadPath: json['defaultDownloadPath'],
    );
  }
}
