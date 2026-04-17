import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/analytics/data/analytics_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsApi {
  AnalyticsApi(this._dio);

  final Dio _dio;

  Future<AnalyticsData> fetchAnalyticsData() async {
    try {
      final summaryRaw = await _get(ApiEndpoints.analyticsDashboard);

      final trendsRaw = await _get(ApiEndpoints.analyticsTimeseries(days: 30));

      final summaryMap = _extractSummaryMap(summaryRaw);
      final trendList = _extractTrends(trendsRaw);

      final summary = summaryMap.isEmpty
          ? AnalyticsData.empty().summary
          : AnalyticsSummary.fromMap(summaryMap);
      final trends = trendList
          .map(AnalyticsTrendPoint.fromMap)
          .toList(growable: false);

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

  Future<dynamic> _get(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    return response.data;
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
    if (trends.isEmpty) {
      return const <AnalyticsInsight>[];
    }

    final latest = trends.last;
    final previous = trends.length > 1 ? trends[trends.length - 2] : latest;

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
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage: 'Please sign in to view analytics insights.',
      validationMessage:
          'Analytics query is invalid. Please refresh and try again.',
    );
  }
}

final analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  return AnalyticsApi(ref.read(apiClientProvider));
});
