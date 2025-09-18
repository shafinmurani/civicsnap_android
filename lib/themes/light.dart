import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData civicSnapLightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  // A clean and modern background color
  scaffoldBackgroundColor: const Color(0xFFF0F4F8),

  // Updated color scheme with more depth and contrast
  colorScheme:
      ColorScheme.fromSwatch(
        primarySwatch:
            Colors.green, // Generates a palette from the primary color
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF388E3C), // A darker, richer green
        onPrimary: Colors.white,
        secondary: const Color(0xFFFFB300), // A warm, golden yellow
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF263238),
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
      ),

  // Consistent font family
  textTheme: GoogleFonts.poppinsTextTheme().copyWith(
    headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFF263238)),
    bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFF455A64)),
    bodySmall: const TextStyle(fontSize: 12, color: Color(0xFF607D8B)),
  ),

  // AppBar with a more modern feel
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF388E3C),
    foregroundColor: Colors.white,
    elevation: 4,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  // Redesigned Card theme
  cardTheme: CardThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 3,
    margin: const EdgeInsets.all(8),
  ),

  // Elevated button style for call-to-action buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF388E3C),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 4,
    ),
  ),

  // Input field styling for forms
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade100,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF388E3C), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF757575)),
    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
  ),

  // Floating Action Button with a circular shape
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF388E3C),
    foregroundColor: Colors.white,
    shape: CircleBorder(),
  ),
);
