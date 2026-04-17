import 'package:flutter/services.dart';

enum LoginUiState { idle, loading, failure, success }

class CountryDialCode {
  const CountryDialCode({
    required this.isoCode,
    required this.name,
    required this.dialCode,
    required this.mobilePattern,
  });

  final String isoCode;
  final String name;
  final String dialCode;
  final String mobilePattern;

  RegExp get mobileRegex => RegExp(mobilePattern);
}

class LoginFormValidators {
  static const CountryDialCode india = CountryDialCode(
    isoCode: 'IN',
    name: 'India',
    dialCode: '+91',
    mobilePattern: r'^\d{10}$',
  );

  static const List<CountryDialCode> supportedCountries = <CountryDialCode>[
    india,
  ];

  static String normalizePhone(String value) {
    return _extractMobileDigits(value);
  }

  static String normalizePhoneForApi(
    String value, {
    CountryDialCode country = india,
  }) {
    final digits = _extractMobileDigits(value);
    if (country.isoCode == 'IN' &&
        digits.length == 12 &&
        digits.startsWith('91')) {
      return digits.substring(2);
    }
    return digits;
  }

  static String? validatePhone(
    String? value, {
    CountryDialCode country = india,
  }) {
    final normalized = normalizePhoneForApi(value ?? '', country: country);
    if (normalized.isEmpty) {
      return 'Mobile number is required';
    }
    if (!isValidForCountry(normalized, country: country)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static bool isValidForCountry(
    String value, {
    CountryDialCode country = india,
  }) {
    final normalized = normalizePhoneForApi(value, country: country);
    return country.mobileRegex.hasMatch(normalized);
  }

  static String maskPhoneForOtp(
    String value, {
    CountryDialCode country = india,
  }) {
    final normalized = normalizePhoneForApi(value, country: country);
    if (normalized.length < 4) {
      return '${country.dialCode} XXXXX X$normalized';
    }

    final tail = normalized.substring(normalized.length - 4);
    return '${country.dialCode} XXXXX X$tail';
  }

  static String _extractMobileDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String? validateOtp(String? value) {
    final otp = (value ?? '').trim();
    if (otp.isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'Enter a valid 6-digit OTP';
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
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 10 ? digits.substring(0, 10) : digits;
    final formatted = _formatIndianMobile(clipped);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatIndianMobile(String digits) {
    if (digits.length <= 5) {
      return digits;
    }

    final first = digits.substring(0, 5);
    final second = digits.substring(5);
    return '$first $second';
  }
}
