import 'package:flutter/material.dart';

class CarbonTheme {
  CarbonTheme._();

  static TextStyle authTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
  }

  static TextStyle authSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
    );
  }

  static TextStyle otpDigit(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    );
  }

  static BorderRadiusGeometry controlRadius = BorderRadius.circular(14);
}
