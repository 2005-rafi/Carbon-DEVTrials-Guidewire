import 'dart:io';

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/analytics/data/analytics_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsApi {
  AnalyticsApi(this._dio);

  final Dio _dio;

  static const List<String> _summaryEndpointVariants = <String>[
    '/analytics/summary',
    '/analytics-service/analytics/summary',
    '/analytics-service/summary',
  ];

  static const List<String> _trendsEndpointVariants = <String>[
    '/analytics/trends',
    '/analytics-service/analytics/trends',
    '/analytics-service/trends',
  ];

  Future<AnalyticsData> fetchAnalyticsData() async {
    try {
      final summaryRaw = await _getWithFallback(
        endpointVariants: _summaryEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.analyticsServiceBaseUrl,
        ],
      );

      final trendsRaw = await _getWithFallback(
        endpointVariants: _trendsEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.analyticsServiceBaseUrl,
        ],
      );

      final summaryMap = _extractSummaryMap(summaryRaw);
      final trendList = _extractTrends(trendsRaw);

      final summary = summaryMap.isEmpty
          ? AnalyticsSummary.fallback()
          : AnalyticsSummary.fromMap(summaryMap);
      final trends = trendList.isEmpty
          ? AnalyticsTrendPoint.fallbackList()
          : trendList.map(AnalyticsTrendPoint.fromMap).toList(growable: false);

      final insights = _deriveInsights(summary, trends);

      return AnalyticsData(
        summary: summary,
        trends: trends,
        insights: insights,
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load analytics right now.',
      );
    }
  }

  Future<Map<String, dynamic>> fetchSummary() async {
    final data = await fetchAnalyticsData();
    return <String, dynamic>{
      'totalProtectedEarnings': data.summary.totalProtectedEarnings,
      'claimsThisMonth': data.summary.claimsThisMonth,
      'approvedClaims': data.summary.approvedClaims,
      'pendingClaims': data.summary.pendingClaims,
      'avgPayoutHours': data.summary.avgPayoutHours,
      'approvalRate': data.summary.approvalRate,
    };
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
    throw Exception('Unable to fetch analytics data.');
  }

  Map<String, dynamic> _extractSummaryMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      final summary = raw['summary'];
      if (summary is Map<String, dynamic>) {
        return summary;
      }

      return raw;
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractTrends(dynamic raw) {
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
      raw['trends'],
      raw['series'],
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

  List<AnalyticsInsight> _deriveInsights(
    AnalyticsSummary summary,
    List<AnalyticsTrendPoint> trends,
  ) {
    final points = trends.isEmpty ? AnalyticsTrendPoint.fallbackList() : trends;
    final latest = points.last;
    final previous = points.length > 1 ? points[points.length - 2] : latest;

    final earningDelta = latest.earnings - previous.earnings;
    final earningsDirection = earningDelta >= 0 ? 'increased' : 'decreased';
    final earningsMagnitude = earningDelta.abs().toStringAsFixed(0);

    final approvalRatePercent = (summary.approvalRate * 100).clamp(0, 100);
    final payoutStatus = summary.avgPayoutHours <= 4.5
        ? 'healthy'
        : 'needs attention';

    return <AnalyticsInsight>[
      AnalyticsInsight(
        title: 'Earnings Trend Update',
        description:
            'Protected earnings $earningsDirection by Rs $earningsMagnitude compared to the previous period.',
        category: 'Earnings',
        impactLevel: earningDelta >= 0 ? 'High' : 'Medium',
        isAnomaly: earningDelta < -700,
      ),
      AnalyticsInsight(
        title: 'Claim Approval Pulse',
        description:
            'Current claim approval rate is ${approvalRatePercent.toStringAsFixed(0)}% this month.',
        category: 'Claims',
        impactLevel: approvalRatePercent >= 70 ? 'High' : 'Critical',
        isAnomaly: approvalRatePercent < 50,
      ),
      AnalyticsInsight(
        title: 'Payout Processing Health',
        description:
            'Average payout turnaround is ${summary.avgPayoutHours.toStringAsFixed(1)}h and currently $payoutStatus.',
        category: 'Payout',
        impactLevel: payoutStatus == 'healthy' ? 'Medium' : 'Critical',
        isAnomaly: payoutStatus != 'healthy',
      ),
    ];
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
          'Analytics service timed out. Pull to refresh and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to connect to analytics service. Check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return const ApiException(
            'Please sign in to view analytics insights.',
            statusCode: HttpStatus.unauthorized,
          );
        }

        return ApiException(serverMessage ?? genericMessage, statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('Analytics request canceled.');
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

final analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  return AnalyticsApi(ref.read(apiClientProvider));
});
