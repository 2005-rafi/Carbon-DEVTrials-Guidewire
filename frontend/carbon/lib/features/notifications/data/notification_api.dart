import 'dart:io';

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/notifications/data/notification_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationApi {
  NotificationApi(this._dio);

  final Dio _dio;

  static const List<String> _notificationsEndpointVariants = <String>[
    '/notifications',
    '/notification-service/notifications',
  ];

  static const List<String> _markReadEndpointVariants = <String>[
    '/notifications/mark-read',
    '/notification-service/notifications/mark-read',
  ];

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final raw = await _getWithFallback(
        endpointVariants: _notificationsEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.notificationServiceBaseUrl,
        ],
      );

      final records = _extractNotifications(
        raw,
      ).map(AppNotification.fromMap).toList(growable: false);

      if (records.isEmpty) {
        return AppNotification.fallbackList();
      }

      return records;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load notifications right now.',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _postWithFallback(
        endpointVariants: _markReadEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.notificationServiceBaseUrl,
        ],
        payload: <String, dynamic>{'id': notificationId},
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to update notification state.',
      );
    }
  }

  Future<dynamic> _getWithFallback({
    required List<String> endpointVariants,
    required List<String> fallbackBaseUrls,
  }) async {
    DioException? lastError;
    final attempted = <String>{};

    Future<dynamic> attempt(String url) async {
      if (attempted.contains(url)) {
        return null;
      }
      attempted.add(url);

      try {
        final response = await _dio.get<dynamic>(url);
        return response.data;
      } on DioException catch (error) {
        lastError = error;
        return null;
      }
    }

    for (final endpoint in endpointVariants) {
      final data = await attempt(endpoint);
      if (data != null) {
        return data;
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        final data = await attempt('$baseUrl$endpoint');
        if (data != null) {
          return data;
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
    throw Exception('Unable to fetch notifications.');
  }

  Future<void> _postWithFallback({
    required List<String> endpointVariants,
    required List<String> fallbackBaseUrls,
    required Map<String, dynamic> payload,
  }) async {
    DioException? lastError;
    final attempted = <String>{};

    Future<bool> attempt(String url) async {
      if (attempted.contains(url)) {
        return false;
      }
      attempted.add(url);

      try {
        await _dio.post<dynamic>(url, data: payload);
        return true;
      } on DioException catch (error) {
        lastError = error;
        return false;
      }
    }

    for (final endpoint in endpointVariants) {
      if (await attempt(endpoint)) {
        return;
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        if (await attempt('$baseUrl$endpoint')) {
          return;
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
    throw Exception('Unable to update notifications.');
  }

  List<Map<String, dynamic>> _extractNotifications(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (raw is! Map<String, dynamic>) {
      return <Map<String, dynamic>>[];
    }

    final candidates = <dynamic>[
      raw['data'],
      raw['items'],
      raw['results'],
      raw['notifications'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }
    }

    return <Map<String, dynamic>>[];
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    final serverMessage = _extractServerMessage(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Notification request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to connect to notification service. Check your internet.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return const ApiException(
            'Please sign in to view notifications.',
            statusCode: HttpStatus.unauthorized,
          );
        }
        return ApiException(serverMessage ?? genericMessage, statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('Notification request canceled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(serverMessage ?? genericMessage);
    }
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
      responseData['description'],
      responseData['error'],
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

    return null;
  }
}

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.read(apiClientProvider));
});
