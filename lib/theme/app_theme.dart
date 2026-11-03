import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fantasy palette: stone, wood, parchment, gold.
class Pal {
  static const stoneDark = Color(0xFF1E1D22);
  static const stoneMid = Color(0xFF34333A);
  static const stoneLight = Color(0xFF4A4952);
  static const woodDark = Color(0xFF3B2314);
  static const wood = Color(0xFF6B4226);
  static const woodLight = Color(0xFF8E5E36);
  static const parchment = Color(0xFFF1E2B8);
  static const parchmentDark = Color(0xFFD9C48F);
  static const ink = Color(0xFF2B1D0E);
  static const gold = Color(0xFFE2B33C);
  static const goldDark = Color(0xFF9C7418);
  static const green = Color(0xFF5E8C3A);
  static const red = Color(0xFF9B2D20);
  static const iron = Color(0xFF2A2A2E);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Pal.wood,
      brightness: Brightness.dark,
      surface: Pal.stoneDark,
    ),
    scaffoldBackgroundColor: Pal.stoneDark,
    useMaterial3: true,
  );
  return base;
}

/// Readable mixed-case serif for text on parchment.
TextStyle inkStyle({double size = 16, FontWeight w = FontWeight.w600}) =>
    GoogleFonts.alegreya(fontSize: size, fontWeight: w, color: Pal.ink, height: 1.15);

TextStyle titleStyle({double size = 22}) => GoogleFonts.cinzel(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: Pal.gold,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 2))],
    );
