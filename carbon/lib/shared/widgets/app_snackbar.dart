import 'package:flutter/material.dart';

enum AppToastType { success, error, warning, rateLimit, invalidOtp }

enum AppToastPosition { bottom, top }

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    AppToastType? toastType,
    AppToastPosition position = AppToastPosition.bottom,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolved =
        toastType ?? (isError ? AppToastType.error : AppToastType.success);

    final (Color backgroundColor, Color foregroundColor) = switch (resolved) {
      AppToastType.success => (colorScheme.primary, colorScheme.onPrimary),
      AppToastType.error => (colorScheme.error, colorScheme.onError),
      AppToastType.warning => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      AppToastType.rateLimit => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      AppToastType.invalidOtp => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };

    if (position == AppToastPosition.top) {
      _showTopToast(
        context,
        message,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }

  static void _showTopToast(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final topInset = MediaQuery.of(overlayContext).padding.top;
        return Positioned(
          left: 14,
          right: 14,
          top: topInset + 12,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: -20, end: 0),
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(opacity: 1, child: child),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 2600)).then((_) {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}
