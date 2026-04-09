import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds (NOT pure black - looks cheap)
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141A);
  static const surfaceLight = Color(0xFF1E1E2A);
  static const surfaceBorder = Color(0x0FFFFFFF); // white 6%

  // Accent gradient
  static const accent1 = Color(0xFF6C63FF); // purple-blue
  static const accent2 = Color(0xFF3B82F6); // blue
  static const gold = Color(0xFFFFD700);
  static const goldDark = Color(0xFFDAA520);
  static const neonGreen = Color(0xFFC8FF00);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  // Text
  static const textPrimary = Color(0xF2FFFFFF); // white 95%
  static const textSecondary = Color(0x99FFFFFF); // white 60%
  static const textMuted = Color(0x61FFFFFF); // white 38%

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent1, accent2],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF06B6D4)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
  );

  // Category
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'legs': return const Color(0xFF8B5CF6);
      case 'chest': return const Color(0xFFEF4444);
      case 'back': return const Color(0xFF3B82F6);
      case 'shoulders': return const Color(0xFFF59E0B);
      case 'biceps': return const Color(0xFF22C55E);
      case 'triceps': return const Color(0xFF06B6D4);
      case 'calves': return const Color(0xFFEC4899);
      default: return accent2;
    }
  }
}
