import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primaryGreen = Color(0xFF1E7F5C);
  static const Color primaryGreenDark = Color(0xFF0F4F3A);
  static const Color accentGold = Color(0xFFC9A14A);
  static const Color deepTeal = Color(0xFF0B3D3A);
  static const Color softCream = Color(0xFFF5F1E8);

  // Subtle warm tint for backgrounds (light mode)
  static const Color warmSurface = Color(0xFFFAF8F4);
  static const Color warmSurfaceHigh = Color(0xFFF1ECE2);

  // Status
  static const Color statusComplete = Color(0xFF2E8B57);
  static const Color statusMissed = Color(0xFFD64545);
  static const Color statusPartial = Color(0xFFE0A82E);
  static const Color statusNone = Color(0xFF9E9E9E);

  // Section accents used in Settings rows
  static const Color sectionBlue = Color(0xFF2E86AB);
  static const Color sectionPurple = Color(0xFF6B5B95);
  static const Color sectionCoral = Color(0xFFE07856);
  static const Color sectionBrown = Color(0xFF8B5A3C);

  static const List<Color> avatarPalette = [
    Color(0xFF1E7F5C),
    Color(0xFFC9A14A),
    Color(0xFF6B5B95),
    Color(0xFF2E86AB),
    Color(0xFFE07856),
    Color(0xFF8B5A3C),
    Color(0xFF5D737E),
    Color(0xFFA64942),
  ];

  static Color avatarColorFor(String text) {
    if (text.isEmpty) return avatarPalette.first;
    final hash = text.codeUnits.fold<int>(0, (a, b) => a + b);
    return avatarPalette[hash % avatarPalette.length];
  }
}
