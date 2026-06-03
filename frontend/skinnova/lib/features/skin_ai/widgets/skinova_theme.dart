// widgets/skinova_theme.dart

import 'package:flutter/material.dart';

abstract class SkiNova {
  // Brand palette
  static const wine = Color(0xFF5B2333);
  static const wineLight = Color(0xFF7A3146);
  static const wineMuted = Color(0xFFF2E8EA);
  static const offWhite = Color(0xFFFAF8F7);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const divider = Color(0xFFEDEBEA);

  // Status colours
  static const statusGood = Color(0xFF4CAF82);
  static const statusModerate = Color(0xFFE8A838);
  static const statusNeedsCare = Color(0xFF5B2333);

  // Gradients
  static const wineGradient = LinearGradient(
    colors: [Color(0xFF5B2333), Color(0xFF7A3146)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softGradient = LinearGradient(
    colors: [Color(0xFFFAF8F7), Color(0xFFF2E8EA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Typography
  static const displayFont = 'Playfair Display';
  static const bodyFont = 'DM Sans';

  static TextStyle heading1({Color color = textPrimary}) => TextStyle(
        fontFamily: displayFont,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle heading2({Color color = textPrimary}) => TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle heading3({Color color = textPrimary}) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  static TextStyle body({Color color = textPrimary}) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle caption({Color color = textSecondary}) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle label({Color color = textPrimary}) => TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      );

  // Radius
  static const radiusSmall = BorderRadius.all(Radius.circular(8));
  static const radiusMedium = BorderRadius.all(Radius.circular(14));
  static const radiusLarge = BorderRadius.all(Radius.circular(20));
  static const radiusXL = BorderRadius.all(Radius.circular(28));
  static const radiusCircle = BorderRadius.all(Radius.circular(100));

  // Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get wineShadow => [
        BoxShadow(
          color: wine.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
