import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextTheme {
  static TextTheme get textTheme {
    final base = GoogleFonts.lexendTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        height: 1.08,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.16,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.18,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.24,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.28,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.42,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.42,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.2,
      ),
    );
  }
}
