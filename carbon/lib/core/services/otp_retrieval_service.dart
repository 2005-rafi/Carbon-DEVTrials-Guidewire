import 'dart:developer' as developer;
import 'dart:convert';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/services/notification_service.dart';
import 'package:dio/dio.dart';

class OtpNotificationDelivery {
  const OtpNotificationDelivery({
    required this.otpFoundInResponse,
    required this.notificationAttempted,
    required this.notificationShown,
    required this.permissionState,
    required this.copyActionAvailable,
    this.failureReason,
  });

  const OtpNotificationDelivery.empty()
    : otpFoundInResponse = false,
      notificationAttempted = false,
      notificationShown = false,
      permissionState = OtpNotificationPermissionState.unknown,
      copyActionAvailable = false,
      failureReason = null;

  final bool otpFoundInResponse;
  final bool notificationAttempted;
  final bool notificationShown;
  final OtpNotificationPermissionState permissionState;
  final bool copyActionAvailable;
  final String? failureReason;

  bool get hasFailure => (failureReason ?? '').trim().isNotEmpty;
}

class OtpRetrievalResult {
  const OtpRetrievalResult({
    required this.message,
    required this.otp,
    required this.notificationDelivery,
  });

  final String message;
  final String otp;
  final OtpNotificationDelivery notificationDelivery;
}

class OtpRetrievalService {
  OtpRetrievalService(this._dio);

  final Dio _dio;
  final _notificationService = NotificationService();

  Future<OtpRetrievalResult> sendOtpAndRetrieve({
    required String phone,
    bool enableSystemNotification = false,
  }) async {
    try {
      final response = await _sendOtpRequest(phone);

      var message = 'OTP sent successfully';
      String? otp;

      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        final container = _resolveContainer(payload);
        final rawMessage = container['message'] as String?;
        if (rawMessage != null && rawMessage.trim().isNotEmpty) {
          message = rawMessage.trim();
        }

        otp = _resolveOtpValue(container);
        if (otp == null || otp.isEmpty) {
          otp = _extractOtpFromMessage(message);
        }
      }

      final resolvedOtp = (otp ?? '').trim();
      OtpNotificationDelivery delivery = OtpNotificationDelivery.empty();

      if (resolvedOtp.isEmpty) {
        developer.log(
          'OTP not present in backend response.',
          name: 'OtpRetrievalService',
        );
        delivery = const OtpNotificationDelivery(
          otpFoundInResponse: false,
          notificationAttempted: false,
          notificationShown: false,
          permissionState: OtpNotificationPermissionState.unknown,
          copyActionAvailable: false,
          failureReason: 'otp_missing_from_response',
        );
      } else if (!enableSystemNotification) {
        delivery = const OtpNotificationDelivery(
          otpFoundInResponse: true,
          notificationAttempted: false,
          notificationShown: false,
          permissionState: OtpNotificationPermissionState.unknown,
          copyActionAvailable: false,
          failureReason: 'notification_mode_disabled',
        );
      } else if (enableSystemNotification) {
        final notificationResult = await _notificationService
            .showOtpNotification(otp: resolvedOtp, phone: phone, isMock: false);
        delivery = OtpNotificationDelivery(
          otpFoundInResponse: true,
          notificationAttempted: notificationResult.attempted,
          notificationShown: notificationResult.shown,
          permissionState: notificationResult.permissionState,
          copyActionAvailable: notificationResult.copyActionAvailable,
          failureReason: notificationResult.reason,
        );
        developer.log(
          'OTP notification status: attempted=${notificationResult.attempted}, shown=${notificationResult.shown}, reason=${notificationResult.reason}',
          name: 'OtpRetrievalService',
        );
      }

      return OtpRetrievalResult(
        message: message,
        otp: resolvedOtp,
        notificationDelivery: delivery,
      );
    } on DioException {
      rethrow;
    } catch (e, stack) {
      developer.log(
        'Failed to retrieve OTP',
        name: 'OtpRetrievalService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Map<String, dynamic> _resolveContainer(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      if (_containsOtpKey(data)) {
        return <String, dynamic>{...payload, ...data};
      }

      return <String, dynamic>{...payload, ...data};
    }

    if (_containsOtpKey(payload) || payload.containsKey('message')) {
      return payload;
    }

    return payload;
  }

  bool _containsOtpKey(Map<String, dynamic> payload) {
    return payload.containsKey('otp') ||
        payload.containsKey('otp_code') ||
        payload.containsKey('code') ||
        payload.containsKey('verification_code');
  }

  String? _resolveOtpValue(Map<String, dynamic> container) {
    final directOtp = _resolveOtpFromNode(container);
    if ((directOtp ?? '').isNotEmpty) {
      return directOtp;
    }

    const otpKeys = <String>['otp', 'otp_code', 'code', 'verification_code'];

    for (final key in otpKeys) {
      final value = container[key];
      final normalized = _normalizeOtpCandidate(value);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  String? _resolveOtpFromNode(dynamic node, {int depth = 0}) {
    if (node == null || depth > 8) {
      return null;
    }

    final normalizedSelf = _normalizeOtpCandidate(node);
    if (normalizedSelf != null && normalizedSelf.isNotEmpty) {
      return normalizedSelf;
    }

    if (node is Map<String, dynamic>) {
      const otpKeys = <String>['otp', 'otp_code', 'code', 'verification_code'];
      for (final key in otpKeys) {
        if (!node.containsKey(key)) {
          continue;
        }

        final normalized = _normalizeOtpCandidate(node[key]);
        if (normalized != null && normalized.isNotEmpty) {
          return normalized;
        }
      }

      for (final value in node.values) {
        final nested = _resolveOtpFromNode(value, depth: depth + 1);
        if ((nested ?? '').isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    if (node is List) {
      for (final item in node) {
        final nested = _resolveOtpFromNode(item, depth: depth + 1);
        if ((nested ?? '').isNotEmpty) {
          return nested;
        }
      }
      return null;
    }

    if (node is String) {
      final text = node.trim();
      if (text.isEmpty) {
        return null;
      }

      if ((text.startsWith('{') && text.endsWith('}')) ||
          (text.startsWith('[') && text.endsWith(']'))) {
        try {
          final decoded = jsonDecode(text);
          final nested = _resolveOtpFromNode(decoded, depth: depth + 1);
          if ((nested ?? '').isNotEmpty) {
            return nested;
          }
        } catch (_) {
          // Non-JSON text is handled by regex fallback below.
        }
      }

      return _extractOtpFromMessage(text);
    }

    return null;
  }

  String? _normalizeOtpCandidate(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      if (RegExp(r'^\d{6}$').hasMatch(trimmed)) {
        return trimmed;
      }

      return _extractOtpFromMessage(trimmed);
    }

    if (value is num) {
      final digits = value.toInt().toString();
      if (digits.isEmpty) {
        return null;
      }

      // Preserve common backend numeric OTP patterns that drop leading zeroes.
      final padded = digits.length < 6 ? digits.padLeft(6, '0') : digits;
      final match = RegExp(r'\d{6}').firstMatch(padded);
      return match?.group(0);
    }

    return null;
  }

  Future<Response<dynamic>> _sendOtpRequest(String phone) async {
    const previewPayloadExtras = <String, dynamic>{
      'include_otp_preview': true,
      'delivery_mode': 'in_app_notification',
      'notification_channel': 'local',
    };

    Future<Response<dynamic>> sendPayload(Map<String, dynamic> data) {
      return _dio.post<dynamic>(ApiEndpoints.sendOtp, data: data);
    }

    try {
      return await sendPayload(<String, dynamic>{
        'phone_number': phone,
        ...previewPayloadExtras,
      });
    } on DioException catch (error) {
      if (!_shouldRetryWithPhoneFallback(error)) {
        rethrow;
      }

      developer.log(
        'Retrying OTP send using compatibility payload key: phone_number without preview extras',
        name: 'OtpRetrievalService',
      );

      try {
        return await sendPayload(<String, dynamic>{'phone_number': phone});
      } on DioException catch (plainPhoneNumberError) {
        if (!_shouldRetryWithPhoneFallback(plainPhoneNumberError)) {
          rethrow;
        }

        developer.log(
          'Retrying OTP send using compatibility payload key: phone with preview extras',
          name: 'OtpRetrievalService',
        );

        try {
          return await sendPayload(<String, dynamic>{
            'phone': phone,
            ...previewPayloadExtras,
          });
        } on DioException catch (phonePreviewError) {
          if (!_shouldRetryWithPhoneFallback(phonePreviewError)) {
            rethrow;
          }

          developer.log(
            'Retrying OTP send using compatibility payload key: phone without preview extras',
            name: 'OtpRetrievalService',
          );
          return sendPayload(<String, dynamic>{'phone': phone});
        }
      }
    }
  }

  bool _shouldRetryWithPhoneFallback(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 400 || statusCode == 422;
  }

  String? _extractOtpFromMessage(String? message) {
    if (message == null) return null;

    final otpPattern = RegExp(r'\b\d{6}\b');
    final match = otpPattern.firstMatch(message);
    return match?.group(0);
  }
}
