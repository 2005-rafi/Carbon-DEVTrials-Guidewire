class ModelParsers {
  ModelParsers._();

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static String readString(
    Map<String, dynamic> source, {
    required List<String> primaryKeys,
    List<String> compatibilityKeys = const <String>[],
    required String fallback,
  }) {
    final primary = _readStringFromKeys(source, primaryKeys);
    if (primary != null) {
      return primary;
    }

    final compat = _readStringFromKeys(source, compatibilityKeys);
    if (compat != null) {
      return compat;
    }

    return fallback;
  }

  static int readInt(
    Map<String, dynamic> source, {
    required List<String> primaryKeys,
    List<String> compatibilityKeys = const <String>[],
    int fallback = 0,
  }) {
    final primary = _readIntFromKeys(source, primaryKeys);
    if (primary != null) {
      return primary;
    }

    final compat = _readIntFromKeys(source, compatibilityKeys);
    if (compat != null) {
      return compat;
    }

    return fallback;
  }

  static double readDouble(
    Map<String, dynamic> source, {
    required List<String> primaryKeys,
    List<String> compatibilityKeys = const <String>[],
    double fallback = 0.0,
  }) {
    final primary = _readDoubleFromKeys(source, primaryKeys);
    if (primary != null) {
      return primary;
    }

    final compat = _readDoubleFromKeys(source, compatibilityKeys);
    if (compat != null) {
      return compat;
    }

    return fallback;
  }

  static bool readBool(
    Map<String, dynamic> source, {
    required List<String> primaryKeys,
    List<String> compatibilityKeys = const <String>[],
    bool fallback = false,
  }) {
    final primary = _readBoolFromKeys(source, primaryKeys);
    if (primary != null) {
      return primary;
    }

    final compat = _readBoolFromKeys(source, compatibilityKeys);
    if (compat != null) {
      return compat;
    }

    return fallback;
  }

  static String readIdentifier(
    Map<String, dynamic> source, {
    required List<String> primaryKeys,
    List<String> compatibilityKeys = const <String>[],
    required String fallback,
  }) {
    final value = readString(
      source,
      primaryKeys: primaryKeys,
      compatibilityKeys: compatibilityKeys,
      fallback: fallback,
    );

    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return fallback;
    }

    if (_uuidPattern.hasMatch(cleaned)) {
      return cleaned.toLowerCase();
    }

    return cleaned;
  }

  static String normalizeDate(dynamic raw, {required String fallback}) {
    if (raw is! String || raw.trim().isEmpty) {
      return fallback;
    }

    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      return raw.trim();
    }

    final year = parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String normalizeTimestamp(dynamic raw, {required String fallback}) {
    if (raw is! String || raw.trim().isEmpty) {
      return fallback;
    }

    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      return raw.trim();
    }

    return parsed.toUtc().toIso8601String();
  }

  static String? _readStringFromKeys(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
      if (value is bool) {
        return value ? 'true' : 'false';
      }
    }

    return null;
  }

  static int? _readIntFromKeys(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9-]'), '');
        final parsed = int.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static double? _readDoubleFromKeys(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
        final parsed = double.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static bool? _readBoolFromKeys(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }

    return null;
  }
}
