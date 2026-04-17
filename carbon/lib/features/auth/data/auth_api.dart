import 'dart:io';
import 'dart:developer' as developer;

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/core/services/otp_retrieval_service.dart';
import 'package:carbon/features/auth/data/auth_models.dart';
import 'package:carbon/features/auth/data/auth_service.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthApi {
  AuthApi(
    this._dio, {
    OtpRetrievalService? otpRetrievalService,
    String? Function()? accessTokenProvider,
    bool enableSystemOtpNotification = false,
  }) : _otpRetrievalService = otpRetrievalService ?? OtpRetrievalService(_dio),
       _accessTokenProvider = accessTokenProvider,
       _enableSystemOtpNotification = enableSystemOtpNotification;

  final Dio _dio;
  final OtpRetrievalService _otpRetrievalService;
  final String? Function()? _accessTokenProvider;
  final bool _enableSystemOtpNotification;
  static const String _defaultWorkerZone = String.fromEnvironment(
    'DEFAULT_WORKER_ZONE',
    defaultValue: 'UNASSIGNED',
  );

  Future<OtpSendResponse> sendOtp({required String phone}) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw const ApiException('Phone number is required to send OTP.');
    }

    try {
      final result = await _otpRetrievalService.sendOtpAndRetrieve(
        phone: normalizedPhone,
        enableSystemNotification: _enableSystemOtpNotification,
      );

      return OtpSendResponse(
        message: result.message,
        otpFoundInResponse: result.notificationDelivery.otpFoundInResponse,
        notificationAttempted:
            result.notificationDelivery.notificationAttempted,
        notificationShown: result.notificationDelivery.notificationShown,
        notificationCopyAvailable:
            result.notificationDelivery.copyActionAvailable,
        notificationPermissionState:
            result.notificationDelivery.permissionState.name,
        notificationFailureReason: result.notificationDelivery.failureReason,
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage:
            'Unable to send OTP right now. Please try again in a moment.',
        authFailureMessage: 'Unable to send OTP for this mobile number.',
      );
    }
  }

  Future<TokenResponse> login({
    required String phoneNumber,
    required String otp,
  }) async {
    final phone = phoneNumber.trim();
    final otpCode = otp.trim();

    if (phone.isEmpty || otpCode.isEmpty) {
      throw const ApiException('Phone number and OTP are required.');
    }

    final request = LoginRequest(phone: phone, otp: otpCode);
    final payload = request.toJson();
    final fallbackPayload = <String, dynamic>{'phone': phone, 'otp': otpCode};
    const loginUrl = ApiEndpoints.login;

    developer.log('Request URL: $loginUrl', name: 'AuthApi.login');
    developer.log(
      'Payload: ${_redactSensitiveFields(payload)}',
      name: 'AuthApi.login',
    );

    return _postForTokenWithPayloadFallback(
      endpoint: loginUrl,
      payloadVariants: <Map<String, dynamic>>[payload, fallbackPayload],
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
      authFailureMessage: 'Invalid phone number or OTP.',
      genericFailureMessage:
          'Unable to sign in right now. Please try again in a moment.',
      variantReason: 'login_payload_compat',
    );
  }

  Future<TokenResponse> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String verificationToken,
  }) async {
    final name = fullName.trim();
    final phone = phoneNumber.trim();
    final normalizedEmail = email.trim();
    final token = verificationToken.trim();

    if (name.isEmpty || phone.isEmpty || token.isEmpty) {
      throw const ApiException(
        'Profile finalization requires verified session details.',
      );
    }

    final request = WorkerCreateRequest(
      fullName: name,
      phone: phone,
      email: normalizedEmail,
    );
    final payload = request.toJson();
    final fallbackPayload = <String, dynamic>{
      'full_name': name,
      'phone': phone,
      if (normalizedEmail.isNotEmpty) 'email': normalizedEmail,
    };
    const requestUrl = ApiEndpoints.register;

    developer.log('Request URL: $requestUrl', name: 'AuthApi.register');
    developer.log(
      'Payload: ${_redactSensitiveFields(payload)}',
      name: 'AuthApi.register',
    );

    return _postForTokenWithPayloadFallback(
      endpoint: requestUrl,
      payloadVariants: <Map<String, dynamic>>[payload, fallbackPayload],
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
          'Authorization': 'Bearer $token',
        },
      ),
      authFailureMessage:
          'Session expired. Please restart verification from login.',
      genericFailureMessage:
          'Unable to complete profile setup right now. Please try again shortly.',
      variantReason: 'register_payload_compat',
    );
  }

  Future<TokenResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw const ApiException(
        'Phone number is required for OTP verification.',
      );
    }
    if (otp.length != 6) {
      throw const ApiException('OTP must be exactly 6 digits.');
    }

    const requestUrl = ApiEndpoints.verifyOtp;

    return _postForTokenAcrossEndpoints(
      endpoints: const <String>[requestUrl],
      payload: OtpVerifyRequest(phone: normalizedPhone, otp: otp).toJson(),
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
      genericFailureMessage: 'OTP verification failed. Please try again.',
    );
  }

  Future<void> resendOtp({required String phone}) async {
    await sendOtp(phone: phone);
  }

  Future<void> createProfile({
    required String phone,
    required String fullName,
    required String email,
    String? userId,
    String? accessToken,
  }) async {
    final normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId.isEmpty) {
      throw const ApiException(
        'Profile finalization missing user identity. Please verify OTP again.',
      );
    }

    final normalizedEmail = email.trim();
    final normalizedZone = _defaultWorkerZone.trim().isEmpty
        ? 'UNASSIGNED'
        : _defaultWorkerZone.trim();

    final request = WorkerProfileUpdateRequest.fromRaw(
      userId: normalizedUserId,
      name: fullName,
      phone: phone,
      zone: normalizedZone,
      email: normalizedEmail,
    );
    request.validate();

    final token = accessToken?.trim() ?? '';

    await _postForVoidWithPayloadFallback(
      endpoint: ApiEndpoints.workerProfile,
      payloadVariants: request.toPayloadVariants(),
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
          'X-Correlation-ID':
              'worker-finalize-${DateTime.now().millisecondsSinceEpoch}',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
      genericFailureMessage:
          'Unable to complete profile setup right now. Please retry from Profile.',
      variantReason: 'worker_profile_payload_compat',
    );
  }

  Future<TokenResponse> refresh({required String refreshToken}) async {
    final token = refreshToken.trim();
    if (token.isEmpty) {
      throw const ApiException('Refresh token is required.');
    }

    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.refresh,
        data: <String, dynamic>{'refresh_token': token},
        options: Options(
          headers: <String, dynamic>{
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );

      final parsedToken = TokenResponse.fromDynamic(response.data);
      final hydratedToken = TokenResponse(
        accessToken: parsedToken.accessToken,
        refreshToken: parsedToken.refreshToken.isNotEmpty
            ? parsedToken.refreshToken
            : token,
        userId: parsedToken.userId,
        tokenType: parsedToken.tokenType,
      );
      if (hydratedToken.isValid) {
        return hydratedToken;
      }

      throw const ApiException('Session refresh failed. Please sign in again.');
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        authFailureMessage: 'Session expired. Please sign in again.',
        genericMessage:
            'Unable to refresh your session right now. Please sign in again.',
      );
    }
  }

  Future<ValidateSessionResponse> validate() async {
    final token = _accessTokenProvider?.call()?.trim() ?? '';
    return _validateAccessToken(
      token: token,
      genericFailureMessage: 'Unable to validate your session right now.',
      authFailureMessage: 'Session expired. Please sign in again.',
    );
  }

  Future<ValidateSessionResponse> validateWithToken({
    required String accessToken,
  }) async {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw const ApiException('Access token is required for validation.');
    }

    return _validateAccessToken(
      token: token,
      genericFailureMessage:
          'Unable to validate verification session right now.',
      authFailureMessage:
          'Verification session expired. Please request OTP again.',
    );
  }

  Future<ValidateSessionResponse> _validateAccessToken({
    required String token,
    required String genericFailureMessage,
    required String authFailureMessage,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.validate,
        queryParameters: token.isEmpty
            ? null
            : <String, dynamic>{'access_token': token},
      );
      final parsed = ValidateSessionResponse.fromDynamic(response.data);
      if (!parsed.isValid) {
        throw const ApiException('Session is not valid.', statusCode: 401);
      }
      return parsed;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: genericFailureMessage,
        authFailureMessage: authFailureMessage,
      );
    } on ApiException {
      rethrow;
    }
  }

  Future<LogoutResponse> logout() async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.logout,
        data: const <String, dynamic>{},
        options: Options(
          headers: <String, dynamic>{
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );
      return LogoutResponse.fromDynamic(response.data);
    } on DioException catch (error) {
      final apiError = _toFriendlyApiException(
        error,
        genericMessage: 'Unable to sign out cleanly right now.',
        authFailureMessage: 'Session expired. Please sign in again.',
      );

      if (apiError.statusCode == HttpStatus.unauthorized) {
        return const LogoutResponse(message: 'Successfully logged out');
      }

      throw apiError;
    }
  }

  Future<TokenResponse> _postForTokenAcrossEndpoints({
    required List<String> endpoints,
    required Map<String, dynamic> payload,
    required String genericFailureMessage,
    String? authFailureMessage,
    Options? requestOptions,
  }) async {
    dynamic responseData;
    ApiException? lastFriendlyError;
    final requestUrlsTried = <String>[];

    for (final endpoint in endpoints) {
      requestUrlsTried.add(endpoint);
      try {
        final response = await _dio.post<dynamic>(
          endpoint,
          data: payload,
          options: requestOptions,
        );
        responseData = response.data;
        break;
      } on DioException catch (error) {
        lastFriendlyError = _toFriendlyApiException(
          error,
          genericMessage: genericFailureMessage,
          authFailureMessage: authFailureMessage,
        );
      }
    }

    final token = TokenResponse.fromDynamic(responseData);
    if (token.isValid || token.hasVerificationToken) {
      return token;
    }

    if (_isSuccessfulEnvelope(responseData)) {
      return TokenResponse.empty;
    }

    if (responseData is Map<String, dynamic>) {
      final nestedToken = TokenResponse.fromMap(responseData);
      if (nestedToken.isValid || nestedToken.hasVerificationToken) {
        return nestedToken;
      }
    }

    if (lastFriendlyError != null) {
      developer.log(
        'Token exchange failed on endpoints: ${requestUrlsTried.join(', ')}',
        name: 'AuthApi',
      );
      throw lastFriendlyError;
    }

    throw ApiException(genericFailureMessage);
  }

  Future<TokenResponse> _postForTokenWithPayloadFallback({
    required String endpoint,
    required List<Map<String, dynamic>> payloadVariants,
    required String genericFailureMessage,
    String? authFailureMessage,
    String? variantReason,
    Options? requestOptions,
  }) async {
    dynamic responseData;
    ApiException? lastFriendlyError;

    for (var index = 0; index < payloadVariants.length; index++) {
      final payload = payloadVariants[index];
      final hasNext = index < payloadVariants.length - 1;

      try {
        final response = await _dio.post<dynamic>(
          endpoint,
          data: payload,
          options: requestOptions,
        );
        responseData = response.data;
        break;
      } on DioException catch (error) {
        final friendly = _toFriendlyApiException(
          error,
          genericMessage: genericFailureMessage,
          authFailureMessage: authFailureMessage,
        );

        final shouldRetry = hasNext && _shouldRetryWithPayloadVariant(error);
        if (shouldRetry) {
          developer.log(
            'Retrying $endpoint using compatibility payload variant (${variantReason ?? 'compat_payload'}).',
            name: 'AuthApi',
          );
          lastFriendlyError = friendly;
          continue;
        }

        throw friendly;
      }
    }

    final token = TokenResponse.fromDynamic(responseData);
    if (token.isValid) {
      return token;
    }

    if (token.hasVerificationToken) {
      return token;
    }

    if (_isSuccessfulEnvelope(responseData)) {
      return TokenResponse.empty;
    }

    if (lastFriendlyError != null) {
      throw lastFriendlyError;
    }

    throw ApiException(genericFailureMessage);
  }

  bool _shouldRetryWithPayloadVariant(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != HttpStatus.badRequest &&
        statusCode != HttpStatus.unprocessableEntity) {
      return false;
    }

    final diagnosticMessage = _extractResponseMessage(
      error.response?.data,
    ).toLowerCase();

    if (diagnosticMessage.isEmpty) {
      return true;
    }

    const compatibleHints = <String>[
      'field required',
      'missing',
      'validation',
      'phone',
      'login',
      'secret',
      'otp',
      'phone_number',
      'extra fields',
      'unexpected',
    ];

    return compatibleHints.any(diagnosticMessage.contains);
  }

  String _extractResponseMessage(dynamic payload) {
    if (payload is String) {
      return payload.trim();
    }

    if (payload is Map<String, dynamic>) {
      final direct = <dynamic>[
        payload['message'],
        payload['detail'],
        payload['error'],
        payload['description'],
      ];

      for (final candidate in direct) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }

      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return _extractResponseMessage(data);
      }
    }

    return '';
  }

  bool _isSuccessfulEnvelope(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return false;
    }

    final topLevelStatus = (payload['status'] as String? ?? '')
        .trim()
        .toLowerCase();
    if (topLevelStatus == 'success' ||
        topLevelStatus == 'ok' ||
        topLevelStatus == 'valid') {
      return true;
    }

    if (payload['ok'] == true || payload['success'] == true) {
      return true;
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final dataStatus = (data['status'] as String? ?? '').trim().toLowerCase();
      if (dataStatus == 'success' ||
          dataStatus == 'ok' ||
          dataStatus == 'valid') {
        return true;
      }

      if (data['ok'] == true ||
          data['success'] == true ||
          data['is_valid'] == true) {
        return true;
      }
    }

    return false;
  }

  Future<void> _postForVoidWithPayloadFallback({
    required String endpoint,
    required List<Map<String, dynamic>> payloadVariants,
    required String genericFailureMessage,
    String? authFailureMessage,
    String? variantReason,
    Options? requestOptions,
  }) async {
    ApiException? lastFriendlyError;

    for (var index = 0; index < payloadVariants.length; index++) {
      final payload = payloadVariants[index];
      final hasNext = index < payloadVariants.length - 1;

      try {
        await _dio.post<dynamic>(
          endpoint,
          data: payload,
          options: requestOptions,
        );
        return;
      } on DioException catch (error) {
        final friendly = _toFriendlyApiException(
          error,
          genericMessage: genericFailureMessage,
          authFailureMessage: authFailureMessage,
        );

        final shouldRetry = hasNext && _shouldRetryWithPayloadVariant(error);
        if (shouldRetry) {
          developer.log(
            'Retrying $endpoint using compatibility payload variant (${variantReason ?? 'compat_payload'}).',
            name: 'AuthApi',
          );
          lastFriendlyError = friendly;
          continue;
        }

        throw friendly;
      }
    }

    if (lastFriendlyError != null) {
      throw lastFriendlyError;
    }

    throw ApiException(genericFailureMessage);
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
    String? authFailureMessage,
  }) {
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage:
          authFailureMessage ??
          'Authentication failed. Please check your credentials and retry.',
      forbiddenMessage:
          'Your account does not have permission for this action.',
      conflictMessage: 'This account already exists. Please sign in.',
      tooManyRequestsMessage:
          'Too many attempts detected. Please wait a minute and try again.',
      validationMessage: 'Please verify your details and try again.',
      serverMessage:
          'The server is having trouble right now. Please try again shortly.',
    );
  }

  Map<String, dynamic> _redactSensitiveFields(Map<String, dynamic> payload) {
    final redacted = Map<String, dynamic>.from(payload);
    const sensitiveKeys = <String>{
      'password',
      'otp',
      'secret',
      'login',
      'phone',
      'phone_number',
      'email',
      'full_name',
      'access_token',
      'refresh_token',
      'verification_token',
    };

    for (final key in sensitiveKeys) {
      if (redacted.containsKey(key)) {
        redacted[key] = '***';
      }
    }
    return redacted;
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.read(apiClientProvider);
  final mode = ref.read(authEnvironmentModeProvider);
  return AuthApi(
    dio,
    otpRetrievalService: OtpRetrievalService(dio),
    accessTokenProvider: () => ref.read(authTokenProvider),
    enableSystemOtpNotification:
        mode == AuthEnvironmentMode.systemNotificationDev,
  );
});
