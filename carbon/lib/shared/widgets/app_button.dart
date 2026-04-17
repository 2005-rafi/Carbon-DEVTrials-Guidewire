import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(onPressed: onPressed, child: Text(label));

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
