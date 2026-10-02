import 'package:flutter/material.dart';

const _brandBlue = Color(0xFF0F4C81);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _brandBlue);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
