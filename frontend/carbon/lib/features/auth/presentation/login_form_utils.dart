import 'package:flutter/services.dart';

enum LoginUiState { idle, loading, failure, success }

class LoginFormValidators {
  static String normalizePhone(String value) {
    return _extractIndianMobileDigits(value);
  }

  static String? validatePhone(String? value) {
    final normalized = _extractIndianMobileDigits(value ?? '');
    if (normalized.isEmpty) {
      return 'Indian mobile number is required';
    }
    if (!_isValidIndianMobile(normalized)) {
      return 'Enter a valid Indian mobile number (10 digits, starts with 6-9)';
    }
    return null;
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
    final password = (value ?? '').trim();
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

class PhoneMaskTextInputFormatter extends TextInputFormatter {
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

    final clipped = digits.length > 10 ? digits.substring(0, 10) : digits;
    final masked = _format(clipped);

    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
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
