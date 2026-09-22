
import 'package:flutter/material.dart';

class ProkColors {
  static const primary      = Color(0xFF1E3A8A);
  static const primaryLight = Color(0xFF3B82F6);
  static const primarySurface = Color(0xFFEFF6FF);
  static const success      = Color(0xFF059669);
  static const successSurface = Color(0xFFECFDF5);
  static const warning      = Color(0xFFD97706);
  static const warningSurface = Color(0xFFFFFBEB);
  static const error        = Color(0xFFDC2626);
  static const errorSurface = Color(0xFFFEF2F2);
  static const neutral50    = Color(0xFFF8FAFC);
  static const neutral100   = Color(0xFFF1F5F9);
  static const neutral200   = Color(0xFFE2E8F0);
  static const neutral400   = Color(0xFF94A3B8);
  static const neutral600   = Color(0xFF475569);
  static const neutral800   = Color(0xFF1E293B);
  static const neutral900   = Color(0xFF0F172A);
  static const white        = Color(0xFFFFFFFF);

  static Color riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return error;
      case 'MEDIUM': return warning;
      default:       return success;
    }
  }
  static Color riskSurface(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return errorSurface;
      case 'MEDIUM': return warningSurface;
      default:       return successSurface;
    }
  }
}

class ProkRadius {
  static const sm   = BorderRadius.all(Radius.circular(8));
  static const md   = BorderRadius.all(Radius.circular(12));
  static const lg   = BorderRadius.all(Radius.circular(16));
  static const full = BorderRadius.all(Radius.circular(999));
}

class ProkTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: ProkColors.primary, brightness: Brightness.light),
    scaffoldBackgroundColor: ProkColors.neutral50,
    fontFamily: null,
    appBarTheme: const AppBarTheme(
      backgroundColor: ProkColors.white,
      foregroundColor: ProkColors.neutral900,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ProkColors.neutral900),
      iconTheme: IconThemeData(color: ProkColors.neutral800, size: 22),
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ProkColors.white,
      selectedItemColor: ProkColors.primary,
      unselectedItemColor: ProkColors.neutral400,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ProkColors.primary,
        foregroundColor: ProkColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: const RoundedRectangleBorder(borderRadius: ProkRadius.md),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ProkColors.primary,
        side: const BorderSide(color: ProkColors.neutral200),
        shape: const RoundedRectangleBorder(borderRadius: ProkRadius.md),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ProkColors.neutral100,
      hintStyle: const TextStyle(color: ProkColors.neutral400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: const BorderSide(color: ProkColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: const BorderSide(color: ProkColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: const BorderSide(color: ProkColors.error, width: 1.5)),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: ProkColors.primary,
      unselectedLabelColor: ProkColors.neutral400,
      indicatorColor: ProkColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: ProkColors.neutral200,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 13),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ProkColors.neutral100,
      labelStyle: const TextStyle(fontSize: 12, color: ProkColors.neutral800, fontWeight: FontWeight.w500),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(color: ProkColors.neutral200, space: 1, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ProkColors.neutral900,
      contentTextStyle: const TextStyle(color: ProkColors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: ProkRadius.md),
    ),
  );
}
