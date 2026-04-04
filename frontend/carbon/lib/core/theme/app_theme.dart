import 'package:carbon/core/theme/color_schemes.dart';
import 'package:carbon/core/theme/text_theme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: AppColorSchemes.light,
    textTheme: AppTextTheme.textTheme,
    scaffoldBackgroundColor: AppColorSchemes.light.surface,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: AppColorSchemes.dark,
    textTheme: AppTextTheme.textTheme,
    scaffoldBackgroundColor: AppColorSchemes.dark.surface,
  );
}
