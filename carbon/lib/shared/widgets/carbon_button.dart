import 'package:carbon/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CarbonButtonState { disabled, enabled, loading }

class CarbonButton extends ConsumerWidget {
  const CarbonButton({
    super.key,
    required this.label,
    required this.state,
    required this.onPressed,
    this.height = 54,
  });

  final String label;
  final CarbonButtonState state;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final bool isEnabled = state == CarbonButtonState.enabled;
    final Color backgroundColor = isEnabled
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final Color foregroundColor = isEnabled
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: 0.54);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: state == CarbonButtonState.loading
              ? SizedBox(
                  key: const ValueKey<String>('carbon_button_loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey<String>('carbon_button_label'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
