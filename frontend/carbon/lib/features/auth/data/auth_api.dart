import 'dart:io';
import 'dart:developer' as developer;

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/auth/data/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    final phone = phoneNumber.trim();
    if (phone.isEmpty || password.isEmpty) {
      throw const ApiException('Phone number and password are required.');
    }

    final request = LoginRequest(phoneNumber: phone, password: password);
    final payload = request.toJson();
    final requestUrl = '${ApiConfig.authGatewayBaseUrl}${ApiEndpoints.login}';

    developer.log(
      'Request URL: $requestUrl',
      name: 'AuthApi.login',
    );
    developer.log(
      'Payload: ${_redactSensitiveFields(payload)}',
      name: 'AuthApi.login',
    );

    await _postWithFallback(
      endpointVariants: <String>[requestUrl],
      payloadVariants: <Map<String, dynamic>>[payload],
      fallbackBaseUrls: const <String>[],
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
      authFailureMessage: 'Invalid phone number or password.',
      genericFailureMessage:
          'Unable to sign in right now. Please try again in a moment.',
    );
  }

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    final name = fullName.trim();
    final phone = phoneNumber.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      throw const ApiException(
        'Name, phone number, and password are required.',
      );
    }

    final request = RegisterRequest(
      fullName: name,
      phoneNumber: phone,
      password: password,
    );
    final payload = request.toJson();
    final requestUrl =
        '${ApiConfig.authGatewayBaseUrl}${ApiEndpoints.register}';

    developer.log(
      'Request URL: $requestUrl',
      name: 'AuthApi.register',
    );
    developer.log(
      'Payload: ${_redactSensitiveFields(payload)}',
      name: 'AuthApi.register',
    );

    await _postWithFallback(
      endpointVariants: <String>[requestUrl],
      payloadVariants: <Map<String, dynamic>>[payload],
      fallbackBaseUrls: const <String>[],
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
      genericFailureMessage:
          'Unable to create account right now. Please try again shortly.',
    );
  }

  Future<void> verifyOtp({required String otp}) async {
    if (otp.length != 6) {
      throw const ApiException('OTP must be exactly 6 digits.');
    }

    final requestUrl =
        '${ApiConfig.authGatewayBaseUrl}${ApiEndpoints.verifyOtp}';

    await _postWithFallback(
      endpointVariants: <String>[requestUrl],
      payloadVariants: <Map<String, dynamic>>[
        <String, dynamic>{'otp': otp},
      ],
      fallbackBaseUrls: const <String>[],
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
      genericFailureMessage: 'OTP verification failed. Please try again.',
    );
  }

  Future<void> resendOtp() async {
    final requestUrl =
        '${ApiConfig.authGatewayBaseUrl}${ApiEndpoints.resendOtp}';

    await _postWithFallback(
      endpointVariants: <String>[requestUrl],
      payloadVariants: const <Map<String, dynamic>>[<String, dynamic>{}],
      fallbackBaseUrls: const <String>[],
      requestOptions: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
      genericFailureMessage: 'Unable to resend OTP right now.',
    );
  }

  Future<void> _postWithFallback({
    required List<String> endpointVariants,
    required List<Map<String, dynamic>> payloadVariants,
    required List<String> fallbackBaseUrls,
    required String genericFailureMessage,
    String? authFailureMessage,
    Options? requestOptions,
  }) async {
    DioException? lastError;
    final attemptedKeys = <String>{};

    Future<void> attempt(String url, Map<String, dynamic> payload) async {
      final attemptKey = '$url|${payload.keys.join(',')}';
      if (attemptedKeys.contains(attemptKey)) {
        return;
      }

      attemptedKeys.add(attemptKey);
      try {
        await _dio.post(url, data: payload, options: requestOptions);
        lastError = null;
        return;
      } on DioException catch (error) {
        lastError = error;
      }
    }

    for (final endpoint in endpointVariants) {
      for (final payload in payloadVariants) {
        await attempt(endpoint, payload);
        if (lastError == null) {
          return;
        }
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        final url = '$baseUrl$endpoint';
        for (final payload in payloadVariants) {
          await attempt(url, payload);
          if (lastError == null) {
            return;
          }
        }
      }
    }

    if (lastError != null) {
      throw _toFriendlyApiException(
        lastError!,
        genericMessage: genericFailureMessage,
        authFailureMessage: authFailureMessage,
      );
    }

    throw ApiException(genericFailureMessage);
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
    String? authFailureMessage,
  }) {
    final explicitMessage = _extractServerMessage(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(
          'The request timed out. Please check your connection and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to reach the server. Please verify your internet connection.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          'Secure connection failed. Please try again later.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return ApiException(
            explicitMessage ??
                authFailureMessage ??
                'Authentication failed. Please check your credentials.',
            statusCode: code,
          );
        }
        if (code == HttpStatus.forbidden) {
          return ApiException(
            explicitMessage ??
                'Your account does not have permission for this action.',
            statusCode: code,
          );
        }
        if (code == HttpStatus.conflict) {
          return ApiException(
            explicitMessage ?? 'This account already exists. Please sign in.',
            statusCode: code,
          );
        }
        if (code == HttpStatus.tooManyRequests) {
          return ApiException(
            explicitMessage ??
                'Too many attempts. Please wait a minute and try again.',
            statusCode: code,
          );
        }
        if (code == HttpStatus.unprocessableEntity ||
            code == HttpStatus.badRequest) {
          return ApiException(
            explicitMessage ?? 'Please verify your details and try again.',
            statusCode: code,
          );
        }
        if (code != null && code >= HttpStatus.internalServerError) {
          return ApiException(
            explicitMessage ??
                'The server is having trouble right now. Please try again shortly.',
            statusCode: code,
          );
        }
        return ApiException(
          explicitMessage ?? genericMessage,
          statusCode: code,
        );
      case DioExceptionType.cancel:
        return const ApiException('Request canceled. Please try again.');
      case DioExceptionType.unknown:
        final lowLevelMessage = error.message?.trim();
        if (lowLevelMessage != null && lowLevelMessage.isNotEmpty) {
          return ApiException(explicitMessage ?? lowLevelMessage);
        }
        return ApiException(explicitMessage ?? genericMessage);
    }
  }

  Map<String, dynamic> _redactSensitiveFields(Map<String, dynamic> payload) {
    final redacted = Map<String, dynamic>.from(payload);
    if (redacted.containsKey('password')) {
      redacted['password'] = '***';
    }
    return redacted;
  }

  String? _extractServerMessage(dynamic responseData) {
    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final candidates = <dynamic>[
      responseData['message'],
      responseData['detail'],
      responseData['error'],
      responseData['description'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
      if (candidate is Map<String, dynamic>) {
        final nested = candidate['message'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
    }

    final errors = responseData['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map<String, dynamic>) {
        final firstMessage = first['message'];
        if (firstMessage is String && firstMessage.trim().isNotEmpty) {
          return firstMessage.trim();
        }
      }
    }

    return null;
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(apiClientProvider));
});
