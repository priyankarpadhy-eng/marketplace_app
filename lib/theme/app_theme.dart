import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ── Brand Accent (Google Pay / Material You) ─────────────────
  static const Color primary     = Color(0xFF4285F4); // Google Blue — CTA, links, focus
  static const Color primarySoft = Color(0xFFE8F0FE); // Blue tint — selected states
  static const Color primaryDark = Color(0xFF8AB4F8); // Google Blue (dark mode)

  // ── Brand Semantic Colors ────────────────────────────────────
  static const Color success     = Color(0xFF34A853); // Google Green — success, confirm
  static const Color successSoft = Color(0xFFE6F4EA); // Green tint
  static const Color warning     = Color(0xFFFBBC05); // Google Yellow — warnings, alerts
  static const Color error       = Color(0xFFEA4335); // Google Red — errors, decline

  // ── Section Accents (adapted to GPay Brand scheme) ───────────
  static const Color socialAccent  = Color(0xFF4285F4); // Google Blue
  static const Color rideAccent    = Color(0xFFFBBC05); // Google Yellow
  static const Color marketAccent  = Color(0xFF34A853); // Google Green
  static const Color profileAccent = Color(0xFFEA4335); // Google Red

  // ── Light Palette (White-First) ──────────────────────────────
  static const Color lightBg           = Color(0xFFF9FAFB); // Background — warm gray
  static const Color lightSurface      = Color(0xFFFFFFFF); // Surface — cards, sheets
  static const Color lightSurfaceAlt   = Color(0xFFF3F4F6); // Gray tint
  static const Color lightTextPrimary  = Color(0xFF111827); // Text Primary
  static const Color lightTextSecondary = Color(0xFF4B5563); // Text Secondary
  static const Color lightBorder       = Color(0xFFE5E7EB); // Subtle Border

  // ── Dark Palette (Google Dark Theme Style) ───────────────────
  static const Color darkBg           = Color(0xFF111827);
  static const Color darkSurface      = Color(0xFF1F2937);
  static const Color darkSurfaceAlt   = Color(0xFF374151);
  static const Color darkTextPrimary  = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder       = Color(0xFF374151);

  // ── Helpers ──────────────────────────────────────────────────
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceAlt(bool isDark) => isDark ? darkSurfaceAlt : lightSurfaceAlt;
  static Color scaffoldBg(bool isDark) => isDark ? darkBg : lightBg;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color accent(bool isDark) => isDark ? primaryDark : primary;

  // ── Text Theme helper ────────────────────────────────────────
  static TextTheme textTheme(bool isDark) {
    final textPrimaryColor = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondaryColor = isDark ? darkTextSecondary : lightTextSecondary;
    return TextTheme(
      displayLarge: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.w600, letterSpacing: -0.02),
      titleMedium: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.w600, letterSpacing: -0.02),
      titleSmall: GoogleFonts.syne(color: textPrimaryColor, fontWeight: FontWeight.w600, letterSpacing: -0.02),
      bodyLarge: GoogleFonts.dmSans(color: textPrimaryColor, fontSize: 16, height: 1.6),
      bodyMedium: GoogleFonts.dmSans(color: textPrimaryColor, fontSize: 14, height: 1.6),
      bodySmall: GoogleFonts.dmSans(color: textSecondaryColor, fontSize: 12, height: 1.6),
      labelLarge: GoogleFonts.dmSans(color: textSecondaryColor, fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: GoogleFonts.dmSans(color: textSecondaryColor, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: GoogleFonts.dmSans(color: textSecondaryColor, fontWeight: FontWeight.w500, fontSize: 11),
    );
  }

  // ────────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: lightBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: lightBg,
      onSurface: lightTextPrimary,
      primary: primary,
      secondary: primarySoft,
      error: error,
    ),
    textTheme: textTheme(false),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: lightTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: lightBorder),
      ),
      backgroundColor: lightSurface,
      selectedColor: primarySoft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryDark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: darkBg,
      onSurface: darkTextPrimary,
      primary: primaryDark,
      secondary: darkSurfaceAlt,
      error: error,
    ),
    textTheme: textTheme(true),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: darkBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: darkBorder),
      ),
      backgroundColor: darkSurface,
      selectedColor: darkSurfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
  }
}
