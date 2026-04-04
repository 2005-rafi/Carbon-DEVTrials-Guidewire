import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.autovalidateMode,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.maxLines,
  });

  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      maxLines: obscureText ? 1 : (maxLines ?? 1),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surface,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
