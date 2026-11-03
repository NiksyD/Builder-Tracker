import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Liquid-glass palette: deep gradient backdrop, white-tinted glass, system accents.
class G {
  static const bg0 = Color(0xFF0A0A0C);
  static const bg1 = Color(0xFF18181C);
  // Monochrome: every accent is white. Hierarchy comes from opacity and weight.
  static const blue = Colors.white;
  static const green = Colors.white;
  static const orange = Colors.white;
  static const red = Color(0xFFE5E5E5);
  static const text = Colors.white;
  static final textDim = Colors.white.withValues(alpha: 0.55);
  static final hairline = Colors.white.withValues(alpha: 0.16);
}

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: G.bg0,
      colorScheme: const ColorScheme.dark(primary: Colors.white, surface: G.bg0),
      useMaterial3: true,
    );

TextStyle largeTitle() =>
    GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w800, color: G.text, letterSpacing: -0.8);

TextStyle headline({double size = 18}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w600, color: G.text, letterSpacing: -0.2);

TextStyle body({double size = 16, Color? color, FontWeight w = FontWeight.w400}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: color ?? G.text);

TextStyle dim({double size = 14}) => GoogleFonts.inter(fontSize: size, color: G.textDim);

TextStyle timer({double size = 24, Color? color}) => GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? G.text,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
