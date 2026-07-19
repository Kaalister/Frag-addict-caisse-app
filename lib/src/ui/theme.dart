import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0D0D0D);
  static const surface = Color(0xFF161616);
  static const surface2 = Color(0xFF1E1E1E);
  static const border = Color(0xFF2A2A2A);
  static const accent = Color(0xFFC8F135);
  static const accent2 = Color(0xFF35C8F1);
  static const danger = Color(0xFFF13535);
  static const warn = Color(0xFFF1A035);
  static const text = Color(0xFFF0F0F0);
  static const muted = Color(0xFF8B8B8B);
  static const cash = Color(0xFF4CAF50);
  static const paypal = Color(0xFF1565C0);
  static const sumup = Color(0xFF7B1FA2);
}

class VisualIdentity {
  static const name = 'Tilly';
  static const mood = 'noir carbone, vert traceur, cyan instrumentation';
  static const radius = 8.0;
}

extension ThemeAccent on BuildContext {
  Color get primaryAccent => Theme.of(this).colorScheme.primary;
  Color get onPrimaryAccent => Theme.of(this).colorScheme.onPrimary;
}

ThemeData caisseTheme(Color primaryColor) {
  final onPrimary = _readableOnColor(primaryColor);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: onPrimary,
      secondary: AppColors.accent2,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VisualIdentity.radius),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: primaryColor),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: onPrimary);
        }
        return const IconThemeData(color: AppColors.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
              color: primaryColor, fontWeight: FontWeight.w800, fontSize: 12);
        }
        return TextStyle(color: primaryColor, fontSize: 12);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: primaryColor,
      selectedIconTheme: IconThemeData(color: onPrimary),
      unselectedIconTheme: const IconThemeData(color: AppColors.muted),
      selectedLabelTextStyle:
          TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
      unselectedLabelTextStyle: TextStyle(color: primaryColor),
    ),
  );
}

Color _readableOnColor(Color color) =>
    color.computeLuminance() > 0.45 ? Colors.black : Colors.white;
