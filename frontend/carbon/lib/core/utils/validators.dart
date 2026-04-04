class Validators {
  static String? requiredField(String value, {String field = 'Field'}) {
    if (value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Email is required';
    }

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(normalized)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? minLength(String value, int min, {String field = 'Field'}) {
    if (value.trim().length < min) {
      return '$field must be at least $min characters';
    }
    return null;
  }

  static String? phoneNumber(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Phone number is required';
    }

    final digitsOnly = normalized.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Enter a valid phone number';
    }

    return null;
  }
}
