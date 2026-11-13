import 'package:flutter/material.dart';

/// Bright, playful, game-like. Dark mode from day one (the feed is video-first).
abstract final class AppTheme {
  static const _seed = Color(0xFFFF7A1A); // quest-flame orange

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );
}
