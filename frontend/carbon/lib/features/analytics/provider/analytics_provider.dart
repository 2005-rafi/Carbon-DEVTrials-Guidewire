import 'package:carbon/features/analytics/data/analytics_api.dart';
import 'package:carbon/features/analytics/data/analytics_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AnalyticsWindow { weekly, monthly, quarterly }

enum AnalyticsChartMetric { earnings, claims, payouts }

final analyticsErrorProvider = StateProvider<String?>((ref) => null);
final analyticsActionLoadingProvider = StateProvider<bool>((ref) => false);
final analyticsActionErrorProvider = StateProvider<String?>((ref) => null);

final analyticsWindowProvider = StateProvider<AnalyticsWindow>(
  (ref) => AnalyticsWindow.monthly,
);
final analyticsChartMetricProvider = StateProvider<AnalyticsChartMetric>(
  (ref) => AnalyticsChartMetric.earnings,
);
final analyticsInsightQueryProvider = StateProvider<String>((ref) => '');

final analyticsAsyncProvider = FutureProvider<AnalyticsData>((ref) async {
  ref.read(analyticsErrorProvider.notifier).state = null;
  try {
    return await ref.read(analyticsApiProvider).fetchAnalyticsData();
  } catch (error) {
    ref.read(analyticsErrorProvider.notifier).state = error.toString();
    return AnalyticsData.fallback();
  }
});

final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  return ref
      .watch(analyticsAsyncProvider)
      .maybeWhen(data: (data) => data, orElse: AnalyticsData.fallback);
});

final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  return ref.watch(analyticsDataProvider).summary;
});

final analyticsTrendsProvider = Provider<List<AnalyticsTrendPoint>>((ref) {
  final data = ref.watch(analyticsDataProvider);
  final window = ref.watch(analyticsWindowProvider);
  final trends = data.trends;

  switch (window) {
    case AnalyticsWindow.weekly:
      return trends.take(4).toList(growable: false);
    case AnalyticsWindow.monthly:
      return trends;
    case AnalyticsWindow.quarterly:
      if (trends.length <= 3) {
        return trends;
      }
      return trends.skip(trends.length - 3).toList(growable: false);
  }
});

final analyticsInsightsProvider = Provider<List<AnalyticsInsight>>((ref) {
  final insights = ref.watch(analyticsDataProvider).insights;
  final query = ref.watch(analyticsInsightQueryProvider).trim().toLowerCase();

  if (query.isEmpty) {
    return insights;
  }

  return insights
      .where((insight) {
        return insight.title.toLowerCase().contains(query) ||
            insight.description.toLowerCase().contains(query) ||
            insight.category.toLowerCase().contains(query);
      })
      .toList(growable: false);
});

final analyticsActionProvider = Provider<AnalyticsAction>((ref) {
  return AnalyticsAction(ref);
});

class AnalyticsAction {
  AnalyticsAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(analyticsActionErrorProvider.notifier).state = null;
  }

  Future<String?> buildExportReport() async {
    _ref.read(analyticsActionLoadingProvider.notifier).state = true;
    _ref.read(analyticsActionErrorProvider.notifier).state = null;

    try {
      final summary = _ref.read(analyticsSummaryProvider);
      final trends = _ref.read(analyticsTrendsProvider);
      final insights = _ref.read(analyticsInsightsProvider);

      final trendLines = trends
          .map(
            (point) =>
                '${point.label}: earnings=${point.earnings.toStringAsFixed(0)}, claims=${point.claims}, payouts=${point.payouts.toStringAsFixed(0)}',
          )
          .join('\n');
      final insightLines = insights
          .map((insight) => '- ${insight.title}: ${insight.description}')
          .join('\n');

      return 'Analytics Report\n'
          'Protected earnings: ${summary.totalProtectedEarnings.toStringAsFixed(2)}\n'
          'Claims this month: ${summary.claimsThisMonth}\n'
          'Approved claims: ${summary.approvedClaims}\n'
          'Pending claims: ${summary.pendingClaims}\n'
          'Average payout hours: ${summary.avgPayoutHours.toStringAsFixed(1)}\n\n'
          'Trend Data:\n$trendLines\n\n'
          'Insights:\n$insightLines';
    } catch (_) {
      _ref.read(analyticsActionErrorProvider.notifier).state =
          'Unable to prepare analytics report.';
      return null;
    } finally {
      _ref.read(analyticsActionLoadingProvider.notifier).state = false;
    }
  }
}

final analyticsProvider = Provider<Map<String, String>>((ref) {
  final summary = ref.watch(analyticsSummaryProvider);
  return <String, String>{
    'Weekly Earnings Protected': summary.totalProtectedEarnings.toStringAsFixed(
      0,
    ),
    'Claims This Month': '${summary.claimsThisMonth}',
    'Average Payout Time': '${summary.avgPayoutHours.toStringAsFixed(1)}h',
  };
});
