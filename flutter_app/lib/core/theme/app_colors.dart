import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A2E);
  static const surfaceLight = Color(0xFF242442);

  static const primary = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF2563EB);
  static const gold = Color(0xFFFFD700);
  static const goldDark = Color(0xFFDAA520);

  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);

  static const categoryLegs = Color(0xFF8B5CF6);
  static const categoryChest = Color(0xFFEF4444);
  static const categoryBack = Color(0xFF3B82F6);
  static const categoryShoulders = Color(0xFFF59E0B);
  static const categoryBiceps = Color(0xFF22C55E);
  static const categoryTriceps = Color(0xFF06B6D4);
  static const categoryCalves = Color(0xFFEC4899);

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'legs':
        return categoryLegs;
      case 'chest':
        return categoryChest;
      case 'back':
        return categoryBack;
      case 'shoulders':
        return categoryShoulders;
      case 'biceps':
        return categoryBiceps;
      case 'triceps':
        return categoryTriceps;
      case 'calves':
        return categoryCalves;
      default:
        return primary;
    }
  }
}
