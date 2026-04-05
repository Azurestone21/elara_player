import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_video_colors.dart';

class AppTheme {
  static const Color defaultPrimaryColor = Color.fromARGB(255, 233, 99, 46);
  static const Color defaultSecondaryColor = Color.fromARGB(255, 255, 121, 37);
  static const Color defaultAccentColor = Color(0xFFE56268);

  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF262626);

  static const Color lightBackground = Color.fromARGB(255, 255, 247, 240);
  static const Color lightSurface = Color.fromARGB(255, 255, 249, 239);
  static const Color lightCard = Color(0xFFF1F5F9);

  // 默认的自定义颜色（浅色主题）
  static const defaultCustomVideoColors = CustomVideoColors(
    progressBarBgColor: Colors.white24,
    timeColor: Colors.white24,
  );

  static ThemeData darkTheme({
    Color primaryColor = defaultPrimaryColor,
    Color secondaryColor = defaultSecondaryColor,
    CustomVideoColors? customVideoColors,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        background: darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white54),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      extensions: [
        customVideoColors ?? defaultCustomVideoColors,
      ],
    );
  }

  static ThemeData lightTheme({
    Color primaryColor = defaultPrimaryColor,
    Color secondaryColor = defaultSecondaryColor,
    Color iconColor = Colors.black,
    Color textColor = const Color.fromARGB(255, 101, 101, 101),
    Color textBodyLargeColor = defaultAccentColor,
    CustomVideoColors? customVideoColors,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        background: lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color.fromARGB(255, 59, 41, 30),
        onBackground: Color.fromARGB(255, 59, 44, 30),
      ),
      scaffoldBackgroundColor: lightBackground,
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: iconColor),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
        headlineSmall: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
        bodyLarge: const TextStyle(
            fontSize: 16, color: Color.fromARGB(255, 59, 47, 30)),
        bodyMedium: const TextStyle(
            fontSize: 14, color: Color.fromARGB(255, 139, 123, 100)),
        bodySmall: const TextStyle(
            fontSize: 12, color: Color.fromARGB(255, 184, 165, 148)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.black12,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      extensions: [
        customVideoColors ?? defaultCustomVideoColors,
      ],
    );
  }
}
