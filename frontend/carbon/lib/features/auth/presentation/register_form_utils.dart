import 'package:flutter/services.dart';

enum RegisterUiState { idle, loading, failure, success }

class RegisterFormValidators {
  static String normalizePhoneDigits(String value) {
    return _extractIndianMobileDigits(value);
  }

  static String normalizePhoneForApi(String value) {
    return _extractIndianMobileDigits(value);
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

  static String? validatePhone(String? value) {
    final digits = _extractIndianMobileDigits(value ?? '');
    if (digits.isEmpty) {
      return 'Indian mobile number is required';
    }

    if (_isValidIndianMobile(digits)) {
      return null;
    }

    return 'Enter a valid Indian mobile number (10 digits, starts with 6-9)';
  }

  static String _extractIndianMobileDigits(String value) {
    final withoutPrefix = value.trim().replaceFirst(
      RegExp(r'^\+91[\s-]*'),
      '',
    );
    var digits = withoutPrefix.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }

    if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 10) {
      return digits;
    }

    return digits;
  }

  static bool _isValidIndianMobile(String digits) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    final confirm = value ?? '';
    if (confirm.isEmpty) {
      return 'Confirm password is required';
    }
    if (confirm != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}

class IndianPhoneMaskTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final withoutPrefix = newValue.text.trimLeft().replaceFirst(
      RegExp(r'^\+91[\s-]*'),
      '',
    );
    var digits = withoutPrefix.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }

    if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    final buffer = StringBuffer('+91 ');

    if (digits.length <= 5) {
      buffer.write(digits);
      return buffer.toString();
    }

    buffer.write(digits.substring(0, 5));
    buffer.write(' ');
    buffer.write(digits.substring(5));

    return buffer.toString();
  }
}
