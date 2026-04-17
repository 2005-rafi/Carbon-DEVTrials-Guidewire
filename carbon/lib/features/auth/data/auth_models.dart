class OtpRequest {
  const OtpRequest({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'phone_number': phone};
  }
}

class LoginRequest {
  const LoginRequest({required this.phone, required this.otp});

  final String phone;
  final String otp;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'login': phone, 'secret': otp};
  }
}

class OtpSendResponse {
  const OtpSendResponse({
    required this.message,
    this.otpFoundInResponse = false,
    this.notificationAttempted = false,
    this.notificationShown = false,
    this.notificationCopyAvailable = false,
    this.notificationPermissionState = 'unknown',
    this.notificationFailureReason,
  });

  final String message;
  final bool otpFoundInResponse;
  final bool notificationAttempted;
  final bool notificationShown;
  final bool notificationCopyAvailable;
  final String notificationPermissionState;
  final String? notificationFailureReason;

  factory OtpSendResponse.fromDynamic(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final message = (payload['message'] as String? ?? '').trim();
      return OtpSendResponse(
        message: message.isNotEmpty ? message : 'OTP sent successfully',
        otpFoundInResponse:
            (payload['otp_found_in_response'] as bool?) ?? false,
        notificationAttempted:
            (payload['notification_attempted'] as bool?) ?? false,
        notificationShown: (payload['notification_shown'] as bool?) ?? false,
        notificationCopyAvailable:
            (payload['notification_copy_available'] as bool?) ?? false,
        notificationPermissionState:
            (payload['notification_permission_state'] as String? ?? 'unknown')
                .trim(),
        notificationFailureReason:
            (payload['notification_failure_reason'] as String?)?.trim(),
      );
    }

    return const OtpSendResponse(message: 'OTP sent successfully');
  }
}

class ValidateSessionResponse {
  const ValidateSessionResponse({
    required this.status,
    required this.scope,
    this.userId = '',
    this.isValidFlag,
  });

  final String status;
  final String scope;
  final String userId;
  final bool? isValidFlag;

  bool get isValid {
    if (isValidFlag != null) {
      return isValidFlag!;
    }

    final normalized = status.trim().toLowerCase();
    return normalized == 'valid' ||
        normalized == 'success' ||
        normalized == 'ok';
  }

  factory ValidateSessionResponse.fromDynamic(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];

      if (data is Map<String, dynamic>) {
        final nestedStatus = _coerceString(data['status']);
        final topLevelStatus = _coerceString(payload['status']);

        return ValidateSessionResponse(
          status: nestedStatus.isNotEmpty ? nestedStatus : topLevelStatus,
          scope: _coerceString(data['scope']).isNotEmpty
              ? _coerceString(data['scope'])
              : _coerceString(payload['scope']),
          userId: _coerceString(data['user_id']).isNotEmpty
              ? _coerceString(data['user_id'])
              : _coerceString(payload['user_id']),
          isValidFlag:
              _coerceBool(data['is_valid']) ?? _coerceBool(data['valid']),
        );
      }

      return ValidateSessionResponse(
        status: _coerceString(payload['status']),
        scope: _coerceString(payload['scope']),
        userId: _coerceString(payload['user_id']),
        isValidFlag:
            _coerceBool(payload['is_valid']) ?? _coerceBool(payload['valid']),
      );
    }

    return const ValidateSessionResponse(status: '', scope: '');
  }

  static String _coerceString(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  static bool? _coerceBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' ||
          normalized == 'valid' ||
          normalized == 'success') {
        return true;
      }
      if (normalized == 'false' ||
          normalized == 'invalid' ||
          normalized == 'error') {
        return false;
      }
    }

    return null;
  }
}

class LogoutResponse {
  const LogoutResponse({required this.message});

  final String message;

  factory LogoutResponse.fromDynamic(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final message = (payload['message'] as String? ?? '').trim();
      return LogoutResponse(
        message: message.isNotEmpty ? message : 'Successfully logged out',
      );
    }
    return const LogoutResponse(message: 'Successfully logged out');
  }
}

class OtpVerifyRequest {
  const OtpVerifyRequest({required this.phone, required this.otp});

  final String phone;
  final String otp;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'phone': phone, 'otp': otp};
  }
}

class WorkerCreateRequest {
  const WorkerCreateRequest({
    required this.fullName,
    required this.phone,
    required this.email,
  });

  final String fullName;
  final String phone;
  final String email;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'full_name': fullName,
      'phone_number': phone,
    };
    if (email.trim().isNotEmpty) {
      payload['email'] = email;
    }
    return payload;
  }
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.tokenType,
    this.verificationToken = '',
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String tokenType;
  final String verificationToken;

  static const empty = TokenResponse(
    accessToken: '',
    refreshToken: '',
    userId: '',
    tokenType: 'bearer',
    verificationToken: '',
  );

  factory TokenResponse.fromMap(Map<String, dynamic> map) {
    final dataMap = _resolveTokenContainer(map);
    final resolvedVerificationToken = _coerceString(
      dataMap['verification_token'],
    );
    final fallbackToken = _coerceTokenString(dataMap['token']);
    final normalizedAccessToken = _coerceString(dataMap['access_token']);
    final fallbackAccessToken = _coerceString(dataMap['new_access_token']);

    return TokenResponse(
      accessToken: normalizedAccessToken.isNotEmpty
          ? normalizedAccessToken
          : fallbackAccessToken,
      refreshToken: _coerceString(dataMap['refresh_token']),
      userId: _coerceString(dataMap['user_id']),
      tokenType: _coerceString(dataMap['token_type']).isEmpty
          ? 'bearer'
          : _coerceString(dataMap['token_type']),
      verificationToken: resolvedVerificationToken.isNotEmpty
          ? resolvedVerificationToken
          : fallbackToken,
    );
  }

  static TokenResponse fromDynamic(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return TokenResponse.fromMap(payload);
    }
    return empty;
  }

  static Map<String, dynamic> _resolveTokenContainer(Map<String, dynamic> map) {
    if (_containsDirectTokenFields(map)) {
      return map;
    }

    final topLevelToken = map['token'];
    if (topLevelToken is Map<String, dynamic> &&
        _containsDirectTokenFields(topLevelToken)) {
      return topLevelToken;
    }

    final data = map['data'];
    if (data is Map<String, dynamic>) {
      if (_containsDirectTokenFields(data)) {
        return data;
      }

      final nestedToken = data['token'];
      if (nestedToken is Map<String, dynamic> &&
          _containsDirectTokenFields(nestedToken)) {
        return nestedToken;
      }

      if (nestedToken is String && nestedToken.trim().isNotEmpty) {
        return data;
      }
    }

    if (topLevelToken is String && topLevelToken.trim().isNotEmpty) {
      return map;
    }

    return map;
  }

  static bool _containsDirectTokenFields(Map<String, dynamic> map) {
    return map.containsKey('access_token') ||
        map.containsKey('new_access_token') ||
        map.containsKey('refresh_token') ||
        map.containsKey('verification_token') ||
        map.containsKey('user_id') ||
        map.containsKey('token_type');
  }

  static String _coerceString(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  static String _coerceTokenString(dynamic rawToken) {
    final stringToken = _coerceString(rawToken);
    if (stringToken.isNotEmpty) {
      return stringToken;
    }

    if (rawToken is Map<String, dynamic>) {
      final fromMapVerification = _coerceString(rawToken['verification_token']);
      if (fromMapVerification.isNotEmpty) {
        return fromMapVerification;
      }

      final fromMapToken = _coerceString(rawToken['token']);
      if (fromMapToken.isNotEmpty) {
        return fromMapToken;
      }

      final fromMapAccessToken = _coerceString(rawToken['access_token']);
      if (fromMapAccessToken.isNotEmpty) {
        return fromMapAccessToken;
      }
    }

    return '';
  }

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;

  bool get hasUserId => userId.isNotEmpty;

  bool get hasVerificationToken => verificationToken.trim().isNotEmpty;
}
