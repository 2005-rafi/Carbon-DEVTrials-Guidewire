import 'dart:io';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/notifications/data/notification_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationApi {
  NotificationApi(this._dio, {String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  final Dio _dio;
  final String? Function()? _userIdProvider;

  Future<List<AppNotification>> fetchNotifications() async {
    final userId = _requireUserId();

    try {
      final raw = await _get(ApiEndpoints.notificationsByUserId(userId));

      final records = _extractNotifications(
        raw,
      ).map(AppNotification.fromMap).toList(growable: false);
      return records;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load notifications right now.',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // The current backend contract does not expose a mark-read endpoint.
    // Notification read state stays local in the UI provider layer.
    return;
  }

  Future<dynamic> _get(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    return response.data;
  }

  String _requireUserId() {
    final candidate = _userIdProvider?.call()?.trim();
    if (candidate == null || candidate.isEmpty) {
      throw const ApiException(
        'User identity is missing. Please sign in again.',
        statusCode: HttpStatus.unauthorized,
      );
    }
    return candidate;
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
      raw['value'],
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
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage: 'Please sign in to view notifications.',
      validationMessage:
          'Notification request looks invalid. Please refresh and try again.',
    );
  }
}

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(
    ref.read(apiClientProvider),
    userIdProvider: () => ref.read(currentUserIdProvider),
  );
});
