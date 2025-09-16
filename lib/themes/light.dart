import 'package:flutter/material.dart';

final ThemeData civicSnapLightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true, // set according to your design preference
  primaryColor: const Color(0xFF4CAF50),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF4CAF50),
    secondary: Color(0xFFFF9800),
    surface: Colors.white,
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black,
    onError: Colors.white,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF4CAF50),
    foregroundColor: Colors.white,
    elevation: 2,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF4CAF50),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
    ),
    labelStyle: TextStyle(color: Colors.black54),
  ),

  // <-- Use CardThemeData here for newer SDKs
  cardTheme: CardThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 3,
    margin: const EdgeInsets.all(8),
  ),

  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
  ),
);
