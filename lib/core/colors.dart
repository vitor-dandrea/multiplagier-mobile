import 'package:flutter/material.dart';

/// Tokens da paleta Multiplagier (style guide dark + lime).
abstract final class AppColors {
  // Main
  static const primary = Color(0xFFD7FC70);
  static const onPrimary = Color(0xFF121410);
  static const primaryDim = Color(0xFFA8C94A);
  static const primaryContainer = Color(0xFF2A3318);
  static const onPrimaryContainer = Color(0xFFE8FFA8);

  // Neutrals (fundos escuros → texto claro)
  static const canvas = Color(0xFF0B0C0A);
  static const surface = Color(0xFF141612);
  static const surfaceContainer = Color(0xFF1C1F1A);
  static const surfaceContainerHigh = Color(0xFF262A23);
  static const outline = Color(0xFF5C6356);
  static const outlineVariant = Color(0xFF3A3F35);
  static const onSurface = Color(0xFFF2F5EC);
  static const onSurfaceVariant = Color(0xFFB8C0AE);

  // Alerts
  static const success = Color(0xFF29AE29);
  static const onSuccess = Color(0xFFFFFFFF);
  static const warning = Color(0xFFFFC62A);
  static const onWarning = Color(0xFF1A1400);
  static const error = Color(0xFFEF4444);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFF4A1515);
  static const onErrorContainer = Color(0xFFFFDAD6);

  // Accents (uso parcimonioso)
  static const orange = Color(0xFFED7615);
  static const lavender = Color(0xFF6E3CF5);
  static const sussie = Color(0xFF38E1F1);
  static const blueJeans = Color(0xFF0082FF);
}

/// Extensão para success / warning fora do [ColorScheme] padrão.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;

  static const dark = AppStatusColors(
    success: AppColors.success,
    onSuccess: AppColors.onSuccess,
    warning: AppColors.warning,
    onWarning: AppColors.onWarning,
  );

  static AppStatusColors of(BuildContext context) {
    return Theme.of(context).extension<AppStatusColors>() ?? dark;
  }

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}
