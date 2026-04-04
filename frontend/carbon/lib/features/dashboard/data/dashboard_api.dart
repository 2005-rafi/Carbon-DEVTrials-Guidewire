import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.activePolicy,
    required this.claimsCount,
    required this.totalPayout,
  });

  final bool activePolicy;
  final int claimsCount;
  final double totalPayout;
}

class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  Future<DashboardSnapshot> fetchDashboardSnapshot() async {
    final summaryData = await _getWithFallback(
      endpoint: ApiEndpoints.dashboardSummary,
      fallbackBaseUrls: <String>[
        ApiConfig.gatewayBaseUrl,
        ApiConfig.analyticsServiceBaseUrl,
      ],
    );

    final claimsData = await _getWithFallback(
      endpoint: ApiEndpoints.claimsList,
      fallbackBaseUrls: <String>[
        ApiConfig.gatewayBaseUrl,
        ApiConfig.claimsServiceBaseUrl,
      ],
    );

    final payoutData = await _getWithFallback(
      endpoint: ApiEndpoints.payoutHistory,
      fallbackBaseUrls: <String>[
        ApiConfig.gatewayBaseUrl,
        ApiConfig.payoutServiceBaseUrl,
      ],
    );

    final policyData = await _getWithFallback(
      endpoint: ApiEndpoints.policyDetails,
      fallbackBaseUrls: <String>[
        ApiConfig.gatewayBaseUrl,
        ApiConfig.policyServiceBaseUrl,
      ],
    );

    return DashboardSnapshot(
      activePolicy: _parsePolicyActive(summaryData, policyData),
      claimsCount: _parseClaimsCount(summaryData, claimsData),
      totalPayout: _parseTotalPayout(summaryData, payoutData),
    );
  }

  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    final notificationsData = await _getWithFallback(
      endpoint: ApiEndpoints.notifications,
      fallbackBaseUrls: <String>[
        ApiConfig.gatewayBaseUrl,
        ApiConfig.notificationServiceBaseUrl,
      ],
    );

    final eventsData = await _getWithFallback(
      endpoint: ApiEndpoints.eventsList,
      fallbackBaseUrls: <String>[
        ApiConfig.gatewayBaseUrl,
        ApiConfig.triggerServiceBaseUrl,
      ],
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

    final events = _extractList(eventsData).take(1).map<Map<String, dynamic>>((
      item,
    ) {
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
    }).toList();

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
  }

  Future<dynamic> _getWithFallback({
    required String endpoint,
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

    final direct = await attempt(endpoint);
    if (direct != null) {
      return direct;
    }

    for (final baseUrl in fallbackBaseUrls) {
      final data = await attempt('$baseUrl$endpoint');
      if (data != null) {
        return data;
      }
    }

    if (lastError != null) {
      throw lastError!;
    }

    throw Exception('Unable to fetch $endpoint');
  }

  bool _parsePolicyActive(dynamic summaryData, dynamic policyData) {
    if (summaryData is Map<String, dynamic>) {
      final value = summaryData['activePolicy'] ?? summaryData['policy_active'];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'active' || value.toLowerCase() == 'true';
      }
    }

    if (policyData is Map<String, dynamic>) {
      final status = policyData['status'] ?? policyData['policy_status'];
      if (status is String) {
        return status.toLowerCase() == 'active';
      }
    }

    return true;
  }

  int _parseClaimsCount(dynamic summaryData, dynamic claimsData) {
    if (summaryData is Map<String, dynamic>) {
      final value = summaryData['claimsCount'] ?? summaryData['claims_count'];
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
    }

    return _extractList(claimsData).length;
  }

  double _parseTotalPayout(dynamic summaryData, dynamic payoutData) {
    if (summaryData is Map<String, dynamic>) {
      final value = summaryData['totalPayout'] ?? summaryData['total_payout'];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
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
}

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.read(apiClientProvider));
});
