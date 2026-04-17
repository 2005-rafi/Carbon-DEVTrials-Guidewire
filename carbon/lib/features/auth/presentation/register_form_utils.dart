import 'package:flutter/services.dart';

enum RegisterUiState { idle, loading, failure, success }

class ProfileFinalizationFormValue {
  const ProfileFinalizationFormValue({
    required this.fullName,
    required this.email,
    required this.isEmailValid,
    required this.isDirty,
    required this.isValid,
  });

  const ProfileFinalizationFormValue.empty()
    : fullName = '',
      email = '',
      isEmailValid = false,
      isDirty = false,
      isValid = false;

  final String fullName;
  final String email;
  final bool isEmailValid;
  final bool isDirty;
  final bool isValid;

  bool get canSubmit => isDirty && isValid;
}

class RegisterFormValidators {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Email is required';
    }

    final isValid = isValidEmail(email);
    if (!isValid) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validateFullName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) {
      return 'Full name is required';
    }
    if (name.length < 2) {
      return 'Enter your full name';
    }
    return null;
  }

  static bool isValidEmail(String value) {
    return _emailRegex.hasMatch(value.trim());
  }
}

class MobileNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
