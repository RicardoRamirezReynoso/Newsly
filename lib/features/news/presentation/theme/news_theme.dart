import 'package:flutter/material.dart';

abstract final class NewsPalette {
  static const ink = Color(0xff10253d);
  static const secondary = Color(0xff4b5c70);
  static const background = Color(0xfff7f6fa);
  static const surface = Colors.white;
  static const subtle = Color(0xffefedf4);
  static const line = Color(0xffdcdbe4);
  static const accent = Color(0xffa62c22);
  static const accentSoft = Color(0xfffbece8);
}

abstract final class NewsType {
  /// Construye el estilo editorial de los titulares con tamaño y peso configurables.
  static TextStyle serif(
    double size, {
    double weight = 650,
    double height = 1.1,
    double spacing = -0.5,
  }) => TextStyle(
    fontFamily: 'Source Serif 4',
    fontVariations: [FontVariation('wght', weight)],
    fontSize: size,
    height: height,
    letterSpacing: spacing,
    color: NewsPalette.ink,
  );

  /// Construye el estilo de lectura y controles con tamaño, peso y color configurables.
  static TextStyle sans(
    double size, {
    double weight = 500,
    double height = 1.45,
    double spacing = 0,
    Color color = NewsPalette.ink,
  }) => TextStyle(
    fontFamily: 'Manrope',
    fontVariations: [FontVariation('wght', weight)],
    fontSize: size,
    height: height,
    letterSpacing: spacing,
    color: color,
  );
}

/// Aplica la paleta, la tipografía y los estilos de controles de Newsly.
ThemeData newsTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NewsPalette.ink,
    primary: NewsPalette.ink,
    surface: NewsPalette.surface,
    error: NewsPalette.accent,
    outline: NewsPalette.line,
    secondaryContainer: NewsPalette.subtle,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: NewsPalette.background,
    dividerColor: NewsPalette.line,
    fontFamily: 'Manrope',
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: NewsPalette.ink,
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: NewsPalette.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NewsPalette.ink,
        foregroundColor: Colors.white,
        textStyle: NewsType.sans(13, weight: 740),
      ),
    ),
  );
}
