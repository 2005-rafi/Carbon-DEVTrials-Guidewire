import 'package:carbon/core/network/api_exception.dart';

class WorkerProfile {
  const WorkerProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.zone,
    this.weeklyIncome,
  });

  final String userId;
  final String name;
  final String phone;
  final String email;
  final String zone;
  final double? weeklyIncome;

  const WorkerProfile.empty()
    : userId = '',
      name = '',
      phone = '',
      email = '',
      zone = '',
      weeklyIncome = null;

  factory WorkerProfile.fromMap(Map<String, dynamic> map) {
    return WorkerProfile(
      userId: _readString(map, const <String>['user_id', 'id']),
      name: _readString(map, const <String>[
        'name',
        'full_name',
        'profile_name',
      ]),
      phone: _readString(map, const <String>[
        'phone',
        'phone_number',
        'mobile',
      ]),
      email: _readString(map, const <String>['email', 'mail']),
      zone: _readString(map, const <String>['zone', 'worker_zone']),
      weeklyIncome: _readDouble(map, const <String>[
        'weekly_income',
        'weeklyIncome',
        'income',
      ]),
    );
  }

  WorkerProfile copyWith({
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? zone,
    double? weeklyIncome,
  }) {
    return WorkerProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      zone: zone ?? this.zone,
      weeklyIncome: weeklyIncome ?? this.weeklyIncome,
    );
  }

  bool get hasIdentity => name.trim().isNotEmpty || phone.trim().isNotEmpty;

  bool get isIncomplete =>
      name.trim().isEmpty || phone.trim().isEmpty || zone.trim().isEmpty;

  String get displayName => name.trim().isEmpty ? 'Not available' : name.trim();

  String get displayPhone =>
      phone.trim().isEmpty ? 'Not available' : phone.trim();

  String get displayEmail =>
      email.trim().isEmpty ? 'Not available' : email.trim();

  String get displayZone => zone.trim().isEmpty ? 'Not available' : zone.trim();

  String get displayWeeklyIncome {
    final income = weeklyIncome;
    if (income == null) {
      return 'Not available';
    }
    return 'INR ${income.toStringAsFixed(2)}';
  }

  static String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  static double? _readDouble(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) {
        return value.toDouble();
      }

      if (value is String && value.trim().isNotEmpty) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }
}

class WorkerStatus {
  const WorkerStatus({required this.isActive, required this.eligibleForClaim});

  final bool? isActive;
  final bool? eligibleForClaim;

  const WorkerStatus.unknown() : isActive = null, eligibleForClaim = null;

  factory WorkerStatus.fromMap(Map<String, dynamic> map) {
    return WorkerStatus(
      isActive: _readBool(map, const <String>['is_active']),
      eligibleForClaim: _readBool(map, const <String>['eligible_for_claim']),
    );
  }

  bool get isKnown => isActive != null || eligibleForClaim != null;

  bool get isCoverageActive => isActive == true;

  bool get canClaim => eligibleForClaim == true;

  String get coverageLabel {
    final active = isActive;
    if (active == null) {
      return 'Unknown';
    }
    return active ? 'Active' : 'Inactive';
  }

  String get claimEligibilityLabel {
    final eligible = eligibleForClaim;
    if (eligible == null) {
      return 'Unknown';
    }
    return eligible ? 'Eligible' : 'Not eligible';
  }

  static bool? _readBool(Map<String, dynamic> source, List<String> keys) {
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
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }

    return null;
  }
}

class WorkerProfileUpdateRequest {
  WorkerProfileUpdateRequest({
    required this.userId,
    required this.name,
    required this.phone,
    required this.zone,
    this.email,
  });

  final String userId;
  final String name;
  final String phone;
  final String zone;
  final String? email;

  factory WorkerProfileUpdateRequest.fromRaw({
    required String userId,
    required String name,
    required String phone,
    required String zone,
    String? email,
  }) {
    return WorkerProfileUpdateRequest(
      userId: userId.trim(),
      name: _normalizeName(name),
      phone: _normalizePhone(phone),
      zone: _normalizeZone(zone),
      email: _normalizeEmail(email),
    );
  }

  WorkerProfile toProfile({double? weeklyIncome}) {
    return WorkerProfile(
      userId: userId,
      name: name,
      phone: phone,
      email: email ?? '',
      zone: zone,
      weeklyIncome: weeklyIncome,
    );
  }

  void validate() {
    if (userId.trim().isEmpty) {
      throw const ApiException(
        'User identity is missing. Please sign in again.',
      );
    }

    if (name.trim().isEmpty) {
      throw const ApiException('Name is required.');
    }

    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.length < 10) {
      throw const ApiException('Please enter a valid mobile number.');
    }

    if (zone.trim().isEmpty) {
      throw const ApiException('Zone is required to update profile.');
    }

    final normalizedEmail = email?.trim() ?? '';
    if (normalizedEmail.isNotEmpty && !normalizedEmail.contains('@')) {
      throw const ApiException('Please enter a valid email address.');
    }
  }

  Map<String, dynamic> toCanonicalPayload({required bool includeEmail}) {
    return <String, dynamic>{
      'user_id': userId,
      'name': name,
      'phone': phone,
      'zone': zone,
      if (includeEmail && (email?.trim().isNotEmpty ?? false)) 'email': email,
    };
  }

  Map<String, dynamic> toFallbackPayload({required bool includeEmail}) {
    return <String, dynamic>{
      'user_id': userId,
      'full_name': name,
      'phone_number': phone,
      'zone': zone,
      if (includeEmail && (email?.trim().isNotEmpty ?? false)) 'email': email,
    };
  }

  List<Map<String, dynamic>> toPayloadVariants() {
    final hasEmail = email?.trim().isNotEmpty ?? false;
    return <Map<String, dynamic>>[
      toCanonicalPayload(includeEmail: true),
      if (hasEmail) toCanonicalPayload(includeEmail: false),
      toFallbackPayload(includeEmail: true),
      if (hasEmail) toFallbackPayload(includeEmail: false),
    ];
  }

  static String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _normalizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('+')) {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      return '+$digits';
    }
    return trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _normalizeZone(String value) {
    final cleaned = value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '-');
    return cleaned.isEmpty ? 'UNASSIGNED' : cleaned;
  }

  static String? _normalizeEmail(String? value) {
    if (value == null) {
      return null;
    }

    final cleaned = value.trim().toLowerCase();
    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}
