import 'dart:io';
import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:dio/dio.dart';

class ApiErrorMapper {
  ApiErrorMapper._();

  static const Map<String, Map<String, String>>
  _localized = <String, Map<String, String>>{
    'en': <String, String>{
      'timeout':
          'The request timed out. Please check your internet connection and try again.',
      'connection':
          'Unable to reach the server right now. Please verify your connection and retry.',
      'certificate':
          'A secure connection could not be established. Please try again later.',
      'canceled': 'Request was canceled. Please try again.',
      'unauthorized':
          'Your session has expired. Please sign in again to continue.',
      'forbidden': 'You are not allowed to perform this action.',
      'notFound': 'The requested resource could not be found.',
      'conflict': 'This action conflicts with existing data.',
      'tooManyRequests':
          'Too many attempts detected. Please wait a minute and try again.',
      'validation': 'Please review your details and try again.',
      'server':
          'The server is currently unavailable. Please try again shortly.',
      'unknown': 'Something went wrong. Please try again.',
    },
    'hi': <String, String>{
      'timeout':
          'Anurodh ka samay samapt ho gaya. Kripya internet check karke dobara prayas karein.',
      'connection':
          'Server se connection nahi ho pa raha hai. Kripya network check karke dobara koshish karein.',
      'certificate':
          'Surakshit connection establish nahi ho pa raha. Kripya baad me dobara koshish karein.',
      'canceled': 'Anurodh radd kar diya gaya. Kripya dobara koshish karein.',
      'unauthorized':
          'Aapka session samapt ho gaya hai. Jaari rakhne ke liye dobara sign in karein.',
      'forbidden': 'Aapko yeh action karne ki anumati nahi hai.',
      'notFound': 'Mangaa gaya data nahi mila.',
      'conflict': 'Yeh action maujooda data se takra raha hai.',
      'tooManyRequests':
          'Bahut adhik prayas hue hain. Kripya ek minute baad dobara koshish karein.',
      'validation': 'Kripya apni details jaanch kar dobara koshish karein.',
      'server':
          'Server is samay uplabdh nahi hai. Kripya thodi der baad koshish karein.',
      'unknown': 'Kuch galat ho gaya. Kripya dobara koshish karein.',
    },
  };

  static ApiException fromDio(
    DioException error, {
    required String fallbackMessage,
    String? localeCode,
    String? unauthorizedMessage,
    String? forbiddenMessage,
    String? notFoundMessage,
    String? conflictMessage,
    String? tooManyRequestsMessage,
    String? validationMessage,
    String? serverMessage,
    Map<int, String> businessMessages = const <int, String>{},
    bool allowServerMessageFor4xx = true,
  }) {
    final code = error.response?.statusCode;
    final extractedServerMessage = _extractServerMessage(error.response?.data);
    final technical = _buildTechnicalMessage(error, extractedServerMessage);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _emitMapped(
          error,
          ApiException(
            _msg(localeCode, 'timeout'),
            statusCode: code,
            technicalMessage: technical,
          ),
        );
      case DioExceptionType.connectionError:
        return _emitMapped(
          error,
          ApiException(
            _msg(localeCode, 'connection'),
            statusCode: code,
            technicalMessage: technical,
          ),
        );
      case DioExceptionType.badCertificate:
        return _emitMapped(
          error,
          ApiException(
            _msg(localeCode, 'certificate'),
            statusCode: code,
            technicalMessage: technical,
          ),
        );
      case DioExceptionType.cancel:
        return _emitMapped(
          error,
          ApiException(
            _msg(localeCode, 'canceled'),
            statusCode: code,
            technicalMessage: technical,
          ),
        );
      case DioExceptionType.badResponse:
        if (code == null) {
          return _emitMapped(
            error,
            ApiException(fallbackMessage, technicalMessage: technical),
          );
        }

        if (businessMessages.containsKey(code)) {
          return _emitMapped(
            error,
            ApiException(
              businessMessages[code]!,
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        if (code == HttpStatus.unauthorized) {
          return _emitMapped(
            error,
            ApiException(
              unauthorizedMessage ?? _msg(localeCode, 'unauthorized'),
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        if (code == HttpStatus.forbidden) {
          return _emitMapped(
            error,
            ApiException(
              forbiddenMessage ?? _msg(localeCode, 'forbidden'),
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        if (code == HttpStatus.notFound) {
          return _emitMapped(
            error,
            ApiException(
              notFoundMessage ?? _msg(localeCode, 'notFound'),
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        if (code == HttpStatus.conflict) {
          return _emitMapped(
            error,
            ApiException(
              conflictMessage ?? _msg(localeCode, 'conflict'),
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        if (code == HttpStatus.tooManyRequests) {
          return _emitMapped(
            error,
            ApiException(
              tooManyRequestsMessage ?? _msg(localeCode, 'tooManyRequests'),
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        if (code == HttpStatus.unprocessableEntity ||
            code == HttpStatus.badRequest) {
          final message =
              allowServerMessageFor4xx &&
                  extractedServerMessage != null &&
                  extractedServerMessage.isNotEmpty
              ? extractedServerMessage
              : validationMessage ?? _msg(localeCode, 'validation');
          return _emitMapped(
            error,
            ApiException(
              message,
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        if (code >= HttpStatus.internalServerError) {
          return _emitMapped(
            error,
            ApiException(
              serverMessage ?? _msg(localeCode, 'server'),
              statusCode: code,
              technicalMessage: technical,
            ),
          );
        }

        return _emitMapped(
          error,
          ApiException(
            extractedServerMessage ?? fallbackMessage,
            statusCode: code,
            technicalMessage: technical,
          ),
        );
      case DioExceptionType.unknown:
        return _emitMapped(
          error,
          ApiException(
            extractedServerMessage ?? fallbackMessage,
            statusCode: code,
            technicalMessage: technical,
          ),
        );
    }
  }

  static ApiException _emitMapped(DioException error, ApiException mapped) {
    final method = error.requestOptions.method;
    final path = error.requestOptions.path;
    developer.log(
      'API error mapped: $method $path | status=${mapped.statusCode} | user="${mapped.userFriendlyMessage}" | technical="${mapped.technicalMessage ?? 'n/a'}"',
      name: 'ApiErrorMapper',
      error: error,
      stackTrace: error.stackTrace,
    );
    return mapped;
  }

  static String? _extractServerMessage(dynamic responseData) {
    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final direct = <dynamic>[
      responseData['message'],
      responseData['detail'],
      responseData['description'],
      responseData['error'],
    ];

    for (final candidate in direct) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
      if (candidate is Map<String, dynamic>) {
        final nestedMessage = candidate['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
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
        final nested = first['message'] ?? first['msg'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
    }

    return null;
  }

  static String _buildTechnicalMessage(
    DioException error,
    String? serverMessage,
  ) {
    final code = error.response?.statusCode;
    final statusPart = code == null ? 'status=none' : 'status=$code';
    final dioType = 'dioType=${error.type.name}';
    final path = 'path=${error.requestOptions.path}';
    final lowLevel = (error.message ?? '').trim();
    final serverPart = serverMessage == null || serverMessage.isEmpty
        ? ''
        : '; server=$serverMessage';
    final lowLevelPart = lowLevel.isEmpty ? '' : '; detail=$lowLevel';
    return '$statusPart; $dioType; $path$serverPart$lowLevelPart';
  }

  static String _msg(String? localeCode, String key) {
    final normalized = (localeCode ?? 'en').toLowerCase();
    final languageCode = normalized.split(RegExp(r'[-_]')).first;

    final localeMap =
        _localized[normalized] ?? _localized[languageCode] ?? _localized['en']!;

    return localeMap[key] ?? _localized['en']![key] ?? 'Something went wrong.';
  }
}
