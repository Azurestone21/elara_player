import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

class PlatformUtils {
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isWindows || isMacOS || isLinux;
  static bool get isWeb => kIsWeb;

  static bool get isAndroid => !kIsWeb && UniversalPlatform.isAndroid;
  static bool get isIOS => !kIsWeb && UniversalPlatform.isIOS;
  static bool get isWindows => !kIsWeb && UniversalPlatform.isWindows;
  static bool get isMacOS => !kIsWeb && UniversalPlatform.isMacOS;
  static bool get isLinux => !kIsWeb && UniversalPlatform.isLinux;

  static bool get supportsVolumeControl => isMobile;
  static bool get supportsBrightnessControl => isMobile;
  static bool get supportsFullscreenGesture => isMobile;
  static bool get supportsMouseWheel => isDesktop;
  static bool get supportsKeyboardShortcuts => isDesktop || isWeb;
}
