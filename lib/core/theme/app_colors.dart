import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  final Color accent;
  final Color accentLight;
  final Color accentDark;

  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceElevated;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color success;
  final Color successLight;
  final Color danger;
  final Color dangerLight;
  final Color warning;
  final Color warningLight;
  final Color info;

  final Color border;
  final Color borderLight;

  final LinearGradient primaryGradient;
  final LinearGradient accentGradient;
  final LinearGradient cardGradient;
  final LinearGradient heroGradient;

  const AppColorsExtension({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.successLight,
    required this.danger,
    required this.dangerLight,
    required this.warning,
    required this.warningLight,
    required this.info,
    required this.border,
    required this.borderLight,
    required this.primaryGradient,
    required this.accentGradient,
    required this.cardGradient,
    required this.heroGradient,
  });

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? accent,
    Color? accentLight,
    Color? accentDark,
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? successLight,
    Color? danger,
    Color? dangerLight,
    Color? warning,
    Color? warningLight,
    Color? info,
    Color? border,
    Color? borderLight,
    LinearGradient? primaryGradient,
    LinearGradient? accentGradient,
    LinearGradient? cardGradient,
    LinearGradient? heroGradient,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      accentDark: accentDark ?? this.accentDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      danger: danger ?? this.danger,
      dangerLight: dangerLight ?? this.dangerLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      info: info ?? this.info,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerLight: Color.lerp(dangerLight, other.dangerLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      accentGradient: LinearGradient.lerp(accentGradient, other.accentGradient, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
    );
  }
}

// Ensure old AppColors is a thin wrapper that redirects to dark theme colors.
// But we actually want to migrate the usages, so we define dark and light instances here.

class AppColors {
  AppColors._();
  
  static const Color primary = Color(0xFF00BFA6);
  static const Color primaryLight = Color(0xFF5DF2D6);
  static const Color primaryDark = Color(0xFF008E76);
  static const Color accent = Color(0xFF7C4DFF);
  static const Color accentLight = Color(0xFFB47CFF);
  static const Color accentDark = Color(0xFF3F1DCB);

  // Dark background
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF1C2333);
  static const Color surfaceElevated = Color(0xFF21273A);
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF484F58);

  // Light background
  static const Color backgroundLight = Color(0xFFF6F8FA);
  static const Color surfaceLightObj = Color(0xFFFFFFFF);
  static const Color surfaceLightObjLight = Color(0xFFF0F6FC);
  static const Color surfaceLightObjElevated = Color(0xFFE1E4E8);
  static const Color textPrimaryLight = Color(0xFF1F2328);
  static const Color textSecondaryLight = Color(0xFF656D76);
  static const Color textTertiaryLight = Color(0xFF8C959F);

  static const Color success = Color(0xFF3FB950);
  static const Color successLight = Color(0xFF56D364);
  static const Color danger = Color(0xFFF85149);
  static const Color dangerLight = Color(0xFFFF7B72);
  static const Color warning = Color(0xFFD29922);
  static const Color warningLight = Color(0xFFE3B341);
  static const Color info = Color(0xFF58A6FF);

  static const Color border = Color(0xFF30363D);
  static const Color borderLightObj = Color(0xFFD0D7DE);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00E5CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF1C2333), Color(0xFF161B22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF112240), Color(0xFF0D1117)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradientLightObj = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F6FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradientLightObj = LinearGradient(
    colors: [Color(0xFFF6F8FA), Color(0xFFE1E4E8), Color(0xFFF6F8FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const AppColorsExtension darkColorExtension = AppColorsExtension(
    primary: primary,
    primaryLight: primaryLight,
    primaryDark: primaryDark,
    accent: accent,
    accentLight: accentLight,
    accentDark: accentDark,
    background: background,
    surface: surface,
    surfaceLight: surfaceLight,
    surfaceElevated: surfaceElevated,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    success: success,
    successLight: successLight,
    danger: danger,
    dangerLight: dangerLight,
    warning: warning,
    warningLight: warningLight,
    info: info,
    border: border,
    borderLight: borderLightObj, // Using borderLightObj is fine later
    primaryGradient: primaryGradient,
    accentGradient: accentGradient,
    cardGradient: cardGradientDark,
    heroGradient: heroGradientDark,
  );

  static const AppColorsExtension lightColorExtension = AppColorsExtension(
    primary: primary,
    primaryLight: primaryLight,
    primaryDark: primaryDark,
    accent: accent,
    accentLight: accentLight,
    accentDark: accentDark,
    background: backgroundLight,
    surface: surfaceLightObj,
    surfaceLight: surfaceLightObjLight,
    surfaceElevated: surfaceLightObjElevated,
    textPrimary: textPrimaryLight,
    textSecondary: textSecondaryLight,
    textTertiary: textTertiaryLight,
    success: success,
    successLight: successLight,
    danger: danger,
    dangerLight: dangerLight,
    warning: warning,
    warningLight: warningLight,
    info: info,
    border: borderLightObj,
    borderLight: border, // Reversed for light mode
    primaryGradient: primaryGradient,
    accentGradient: accentGradient,
    cardGradient: cardGradientLightObj,
    heroGradient: heroGradientLightObj,
  );
}

extension AppThemeContext on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>() ?? AppColors.darkColorExtension;
}
