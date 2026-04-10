import 'package:flutter/material.dart';

/// Kinetic Design System - "Precision Performance"
/// Based on DESIGN.md from Stitch
class AppColors {
  // Surface hierarchy (no borders - use background shifts)
  static const background = Color(0xFF000000);       // surface_container_lowest
  static const surface = Color(0xFF0E0E0E);           // base surface
  static const surfaceLow = Color(0xFF131313);         // sectioning
  static const surfaceHigh = Color(0xFF262626);        // interactive cards/inputs

  // Primary accent - Electric Lime
  static const primary = Color(0xFFCAFD00);            // primary_container
  static const primaryLight = Color(0xFFF3FFCA);       // primary
  static const onPrimary = Color(0xFF0E0E0E);          // dark text on lime

  // Semantic
  static const success = Color(0xFF4ADE80);
  static const error = Color(0xFFFF7351);
  static const warning = Color(0xFFFFA726);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);        // on_surface
  static const textSecondary = Color(0xFFADAAAA);      // on_surface_variant
  static const textMuted = Color(0xFF6B6B6B);          // dimmer labels

  // Outline (only when absolutely needed - "felt, not seen")
  static const outline = Color(0x26484847);            // outline_variant 15% opacity

  // Primary gradient for CTAs
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  // Category colors
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'legs': return const Color(0xFF8B5CF6);
      case 'chest': return const Color(0xFFEF4444);
      case 'back': return const Color(0xFF3B82F6);
      case 'shoulders': return const Color(0xFFF59E0B);
      case 'biceps': return const Color(0xFF22C55E);
      case 'triceps': return const Color(0xFF06B6D4);
      case 'calves': return const Color(0xFFEC4899);
      default: return primary;
    }
  }
}
