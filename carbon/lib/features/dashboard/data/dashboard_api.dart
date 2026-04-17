import 'dart:io';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.activePolicy,
    required this.claimsCount,
    required this.totalPayout,
    required this.hasPartialData,
    required this.degradedSources,
  });

  final bool activePolicy;
  final int claimsCount;
  final double totalPayout;
  final bool hasPartialData;
  final List<String> degradedSources;
}

class DashboardApi {
  DashboardApi(this._dio, {String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  final Dio _dio;
  final String? Function()? _userIdProvider;

  Future<DashboardSnapshot> fetchDashboardSnapshot() async {
    try {
      final userId = _requireUserId();
      final degradedSources = <String>{};
      final summaryData = await _getOrNull(
        ApiEndpoints.analyticsDashboard,
        sourceName: 'analytics',
        degradedSources: degradedSources,
      );

      final claimsData = await _getOrNull(
        ApiEndpoints.claimsByUserId(userId),
        sourceName: 'claims',
        degradedSources: degradedSources,
      );

      final payoutData = await _getOrNull(
        ApiEndpoints.payoutByUserId(userId),
        sourceName: 'payout',
        degradedSources: degradedSources,
      );

      final policyData = await _getOrNull(
        ApiEndpoints.policyByUserId(userId),
        sourceName: 'policy',
        degradedSources: degradedSources,
      );

      return DashboardSnapshot(
        activePolicy: _parsePolicyActive(summaryData, policyData),
        claimsCount: _parseClaimsCount(summaryData, claimsData),
        totalPayout: _parseTotalPayout(summaryData, payoutData),
        hasPartialData: degradedSources.isNotEmpty,
        degradedSources: degradedSources.toList(growable: false),
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load dashboard summary right now.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    try {
      final userId = _requireUserId();
      final degradedSources = <String>{};
      final notificationsData = await _getOrNull(
        ApiEndpoints.notificationsByUserId(userId),
        sourceName: 'notifications',
        degradedSources: degradedSources,
      );

      final eventsData = await _getOrNull(
        ApiEndpoints.triggerActive,
        sourceName: 'events',
        degradedSources: degradedSources,
      );

      final notifications = _extractList(notificationsData)
          .take(2)
          .map<Map<String, dynamic>>((item) {
            final title = _extractString(item, <String>[
              'title',
              'message',
              'type',
              'event',
            ], fallback: 'Notification');
            final subtitle = _extractString(item, <String>[
              'subtitle',
              'detail',
              'description',
              'status',
            ], fallback: 'Update from notification service.');

            return <String, dynamic>{
              'title': title,
              'subtitle': subtitle,
              'timeText': _extractString(item, <String>[
                'time',
                'timestamp',
                'created_at',
                'date',
              ], fallback: 'Recently'),
              'routeName': '/notifications',
            };
          })
          .toList();

      final events = _extractList(eventsData).take(1).map<Map<String, dynamic>>(
        (item) {
          final severity = _extractString(item, <String>[
            'severity',
            'impact',
            'level',
          ], fallback: 'Medium');
          return <String, dynamic>{
            'title': _extractString(item, <String>[
              'title',
              'event',
              'name',
            ], fallback: 'Disruption Alert'),
            'subtitle': 'Severity: $severity',
            'timeText': _extractString(item, <String>[
              'time',
              'timestamp',
              'created_at',
              'date',
            ], fallback: 'Today'),
            'routeName': '/events',
          };
        },
      ).toList();

      final merged = <Map<String, dynamic>>[...notifications, ...events];
      if (merged.isEmpty) {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'No recent activity',
            'subtitle':
                'Your latest policy, claim, and payout updates appear here.',
            'timeText': 'Now',
            'routeName': '/dashboard',
          },
        ];
      }

      return merged;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load recent dashboard activity right now.',
      );
    }
  }

  Future<dynamic> _get(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    return response.data;
  }

  Future<dynamic> _getOrNull(
    String endpoint, {
    required String sourceName,
    required Set<String> degradedSources,
  }) async {
    try {
      return await _get(endpoint);
    } on DioException catch (error) {
      if (_isRecoverablePartialError(error)) {
        degradedSources.add(sourceName);
        return null;
      }
      rethrow;
    }
  }

  bool _isRecoverablePartialError(DioException error) {
    final code = error.response?.statusCode;
    if (code == HttpStatus.notFound ||
        code == HttpStatus.internalServerError ||
        code == HttpStatus.badGateway ||
        code == HttpStatus.serviceUnavailable ||
        code == HttpStatus.gatewayTimeout) {
      return true;
    }

    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
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

  bool _parsePolicyActive(dynamic summaryData, dynamic policyData) {
    final summaryMap = _unwrapEnvelopeMap(summaryData);
    if (summaryMap.isNotEmpty) {
      final value =
          summaryMap['activePolicy'] ??
          summaryMap['policy_active'] ??
          summaryMap['active_policies'];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value > 0;
      }
      if (value is String) {
        return value.toLowerCase() == 'active' || value.toLowerCase() == 'true';
      }
    }

    final policyMap = _unwrapEnvelopeMap(policyData);
    if (policyMap.isNotEmpty) {
      final isOptedIn = policyMap['is_opted_in'];
      if (isOptedIn is bool) {
        return isOptedIn;
      }
      final status = policyMap['status'] ?? policyMap['policy_status'];
      if (status is String) {
        return status.toLowerCase() == 'active';
      }
    }

    return false;
  }

  int _parseClaimsCount(dynamic summaryData, dynamic claimsData) {
    final summaryMap = _unwrapEnvelopeMap(summaryData);
    if (summaryMap.isNotEmpty) {
      final value =
          summaryMap['claimsCount'] ??
          summaryMap['claims_count'] ??
          summaryMap['total_claims_count'];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
    }

    return _extractList(claimsData).length;
  }

  double _parseTotalPayout(dynamic summaryData, dynamic payoutData) {
    final summaryMap = _unwrapEnvelopeMap(summaryData);
    if (summaryMap.isNotEmpty) {
      final value =
          summaryMap['totalPayout'] ??
          summaryMap['total_payout'] ??
          summaryMap['total_payout_amount'];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
    }

    double total = 0.0;
    for (final item in _extractList(payoutData)) {
      final value = item['amount'] ?? item['payout_amount'];
      if (value is num) {
        total += value.toDouble();
      } else if (value is String) {
        total += double.tryParse(value) ?? 0.0;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }

    if (raw is Map<String, dynamic>) {
      final candidates = <dynamic>[
        raw['data'],
        raw['items'],
        raw['results'],
        raw['value'],
        raw['notifications'],
        raw['events'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate.whereType<Map<String, dynamic>>().toList();
        }
      }
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _unwrapEnvelopeMap(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const <String, dynamic>{};
    }

    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return raw;
  }

  String _extractString(
    Map<String, dynamic> source,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage:
          'Your session has expired. Please sign in again to load dashboard data.',
      validationMessage:
          'Dashboard request is invalid. Please refresh and try again.',
    );
  }
}

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(
    ref.read(apiClientProvider),
    userIdProvider: () => ref.read(currentUserIdProvider),
  );
});
