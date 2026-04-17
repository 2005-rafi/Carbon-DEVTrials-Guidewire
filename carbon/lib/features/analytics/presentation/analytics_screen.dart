import 'dart:math' as math;

import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/utils/formatters.dart';
import 'package:carbon/features/analytics/data/analytics_models.dart';
import 'package:carbon/features/analytics/provider/analytics_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _showInsightSearch = false;

  String _windowLabel(AnalyticsWindow window) {
    switch (window) {
      case AnalyticsWindow.weekly:
        return 'Weekly';
      case AnalyticsWindow.monthly:
        return 'Monthly';
      case AnalyticsWindow.quarterly:
        return 'Quarterly';
    }
  }

  String _metricLabel(AnalyticsChartMetric metric) {
    switch (metric) {
      case AnalyticsChartMetric.earnings:
        return 'Earnings';
      case AnalyticsChartMetric.claims:
        return 'Claims';
      case AnalyticsChartMetric.payouts:
        return 'Payouts';
    }
  }

  Color _insightColor(String impactLevel, ColorScheme colorScheme) {
    final normalized = impactLevel.trim().toLowerCase();
    if (normalized == 'critical') {
      return colorScheme.error;
    }
    if (normalized == 'high') {
      return colorScheme.primary;
    }
    if (normalized == 'medium') {
      return colorScheme.secondary;
    }
    return colorScheme.tertiary;
  }

  double _metricValue(AnalyticsTrendPoint point, AnalyticsChartMetric metric) {
    switch (metric) {
      case AnalyticsChartMetric.earnings:
        return point.earnings;
      case AnalyticsChartMetric.claims:
        return point.claims.toDouble();
      case AnalyticsChartMetric.payouts:
        return point.payouts;
    }
  }

  Future<void> _openFilterSheet() async {
    AnalyticsWindow selectedWindow = ref.read(analyticsWindowProvider);
    AnalyticsChartMetric selectedMetric = ref.read(
      analyticsChartMetricProvider,
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Filter Insights'),
                    const SizedBox(height: 10),
                    const Text('Time Window'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AnalyticsWindow.values
                          .map((window) {
                            return ChoiceChip(
                              label: Text(_windowLabel(window)),
                              selected: selectedWindow == window,
                              onSelected: (_) {
                                setSheetState(() {
                                  selectedWindow = window;
                                });
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    const Text('Chart Metric'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AnalyticsChartMetric.values
                          .map((metric) {
                            return ChoiceChip(
                              label: Text(_metricLabel(metric)),
                              selected: selectedMetric == metric,
                              onSelected: (_) {
                                setSheetState(() {
                                  selectedMetric = metric;
                                });
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    ref.read(analyticsWindowProvider.notifier).state = selectedWindow;
    ref.read(analyticsChartMetricProvider.notifier).state = selectedMetric;
  }

  Future<void> _exportAnalyticsReport() async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Export Analytics Data'),
              content: const Text(
                'Do you want to export current analytics insights and trend data?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Export'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) {
      return;
    }

    final report = await ref.read(analyticsActionProvider).buildExportReport();
    if (!mounted) {
      return;
    }

    if (report == null || report.trim().isEmpty) {
      final error =
          ref.read(analyticsActionErrorProvider) ??
          'Unable to export analytics report.';
      AppSnackbar.show(context, error, isError: true);
      return;
    }

    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) {
      return;
    }

    AppSnackbar.show(context, 'Analytics report copied for sharing/export.');
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barChart(
    BuildContext context,
    List<AnalyticsTrendPoint> trends,
    AnalyticsChartMetric metric,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (trends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No trend data available.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ),
      );
    }

    final values = trends
        .map((point) => _metricValue(point, metric))
        .toList(growable: false);
    final maxValue = values.fold<double>(1, (max, value) {
      return value > max ? value : max;
    });

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (var index = 0; index < trends.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      values[index].toStringAsFixed(
                        metric == AnalyticsChartMetric.claims ? 0 : 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      height: ((values[index] / maxValue) * 110).clamp(8, 110),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trends[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _lineChart(
    BuildContext context,
    List<AnalyticsTrendPoint> trends,
    AnalyticsChartMetric metric,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (trends.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Not enough data points for trend line.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ),
      );
    }

    final values = trends
        .map((point) => _metricValue(point, metric))
        .toList(growable: false);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              values: values,
              color: colorScheme.secondary,
              markerColor: colorScheme.primary,
              gridColor: colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                trends.first.label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                trends[trends.length ~/ 2].label,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                trends.last.label,
                textAlign: TextAlign.right,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pieChart(BuildContext context, AnalyticsSummary summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final totalClaims = math.max(summary.claimsThisMonth, 1);
    final approved = summary.approvedClaims.toDouble();
    final pending = summary.pendingClaims.toDouble();
    final others =
        (totalClaims - summary.approvedClaims - summary.pendingClaims)
            .clamp(0, totalClaims)
            .toDouble();

    final segments = <_PieSegment>[
      _PieSegment(
        value: approved,
        color: colorScheme.primary,
        label: 'Approved',
      ),
      _PieSegment(
        value: pending,
        color: colorScheme.secondary,
        label: 'Pending',
      ),
      _PieSegment(value: others, color: colorScheme.tertiary, label: 'Other'),
    ];

    return Row(
      children: <Widget>[
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: _PieChartPainter(
              segments: segments,
              fallbackColor: colorScheme.surfaceContainerHighest,
              centerColor: colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            runSpacing: 8,
            children: segments
                .map((segment) {
                  return Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${segment.label}: ${segment.value.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _chartContainer(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsAsyncProvider);
    final summary = ref.watch(analyticsSummaryProvider);
    final trends = ref.watch(analyticsTrendsProvider);
    final insights = ref.watch(analyticsInsightsProvider);
    final selectedWindow = ref.watch(analyticsWindowProvider);
    final selectedMetric = ref.watch(analyticsChartMetricProvider);
    final insightSearch = ref.watch(analyticsInsightQueryProvider);

    final backendError = ref.watch(analyticsErrorProvider);
    final actionError = ref.watch(analyticsActionErrorProvider);
    final actionLoading = ref.watch(analyticsActionLoadingProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CoreScaffold(
      currentRoute: RouteNames.analytics,
      title: 'Analytics',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsAsyncProvider);
          ref.read(analyticsActionProvider).clearError();
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Insights Overview',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track trends, claim analytics, and payout efficiency in one unified dashboard.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: actionLoading
                              ? null
                              : _exportAnalyticsReport,
                          icon: actionLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                          label: Text(
                            actionLoading ? 'Exporting...' : 'Export Data',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openFilterSheet,
                          icon: const Icon(Icons.tune_outlined),
                          label: const Text('Filter Insights'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.secondary,
                            side: BorderSide(color: colorScheme.secondary),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showInsightSearch = !_showInsightSearch;
                            });

                            if (!_showInsightSearch) {
                              ref
                                      .read(
                                        analyticsInsightQueryProvider.notifier,
                                      )
                                      .state =
                                  '';
                            }
                          },
                          icon: Icon(
                            _showInsightSearch
                                ? Icons.search_off_outlined
                                : Icons.search,
                          ),
                          label: Text(
                            _showInsightSearch ? 'Hide Search' : 'Search',
                          ),
                        ),
                      ],
                    ),
                    if (_showInsightSearch) ...<Widget>[
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (value) =>
                            ref
                                    .read(
                                      analyticsInsightQueryProvider.notifier,
                                    )
                                    .state =
                                value,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search insights by title or category',
                          suffixIcon: insightSearch.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () =>
                                      ref
                                              .read(
                                                analyticsInsightQueryProvider
                                                    .notifier,
                                              )
                                              .state =
                                          '',
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Chip(
                          label: Text(
                            'Window: ${_windowLabel(selectedWindow)}',
                          ),
                          avatar: const Icon(Icons.schedule_outlined, size: 16),
                        ),
                        Chip(
                          label: Text(
                            'Metric: ${_metricLabel(selectedMetric)}',
                          ),
                          avatar: const Icon(Icons.show_chart, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final width = constraints.maxWidth;
                        final columns = width > 900
                            ? 4
                            : width > 620
                            ? 2
                            : 1;

                        return GridView.count(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: columns == 1 ? 3.7 : 1.7,
                          children: <Widget>[
                            _summaryCard(
                              context,
                              label: 'Protected Earnings',
                              value: AppFormatters.currency(
                                summary.totalProtectedEarnings,
                              ),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            _summaryCard(
                              context,
                              label: 'Claims This Month',
                              value: '${summary.claimsThisMonth}',
                              icon: Icons.assignment_outlined,
                            ),
                            _summaryCard(
                              context,
                              label: 'Approval Rate',
                              value:
                                  '${(summary.approvalRate * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              icon: Icons.verified_outlined,
                            ),
                            _summaryCard(
                              context,
                              label: 'Avg Payout Time',
                              value:
                                  '${summary.avgPayoutHours.toStringAsFixed(1)}h',
                              icon: Icons.timelapse_outlined,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _chartContainer(
                      context,
                      title:
                          'Bar Chart: ${_metricLabel(selectedMetric)} Comparison',
                      subtitle:
                          'Compare selected metric values across periods.',
                      child: _barChart(context, trends, selectedMetric),
                    ),
                    _chartContainer(
                      context,
                      title: 'Line Chart: Trend Over Time',
                      subtitle: 'Visualize directional trend progression.',
                      child: _lineChart(context, trends, selectedMetric),
                    ),
                    _chartContainer(
                      context,
                      title: 'Pie Chart: Claims Distribution',
                      subtitle: 'Current claim split by status categories.',
                      child: _pieChart(context, summary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Insights',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (insights.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'No insights available for current filters.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ),
                    for (final insight in insights)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _insightColor(
                              insight.impactLevel,
                              colorScheme,
                            ).withValues(alpha: 0.14),
                            child: Icon(
                              insight.isAnomaly
                                  ? Icons.warning_amber_outlined
                                  : Icons.lightbulb_outline,
                              color: _insightColor(
                                insight.impactLevel,
                                colorScheme,
                              ),
                            ),
                          ),
                          title: Text(
                            insight.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            insight.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _insightColor(
                                insight.impactLevel,
                                colorScheme,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              insight.impactLevel,
                              style: textTheme.labelSmall?.copyWith(
                                color: _insightColor(
                                  insight.impactLevel,
                                  colorScheme,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Detailed Drill-down',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final insight in insights)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: colorScheme.surfaceContainerHighest,
                        child: ExpansionTile(
                          title: Text(
                            insight.title,
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          iconColor: colorScheme.primary,
                          collapsedIconColor: colorScheme.primary,
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            14,
                          ),
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                insight.description,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.84,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: <Widget>[
                                Text(
                                  'Category: ${insight.category}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'Impact: ${insight.impactLevel}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  insight.isAnomaly
                                      ? 'Marked as anomaly'
                                      : 'Normal pattern',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (analyticsAsync.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: SizedBox(height: 28, child: AppLoader()),
                ),
              ),
            if (backendError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      backendError,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            if (actionError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      actionError,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.color,
    required this.markerColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color markerColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final maxValue = values.fold<double>(1, (max, value) {
      return value > max ? value : max;
    });
    final minValue = values.fold<double>(values.first, (min, value) {
      return value < min ? value : min;
    });
    final range = (maxValue - minValue).abs() < 0.001
        ? 1
        : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = i * (size.width / (values.length - 1));
      final normalized = (values[i] - minValue) / range;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final markerPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 3.2, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _PieSegment {
  const _PieSegment({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.segments,
    required this.fallbackColor,
    required this.centerColor,
  });

  final List<_PieSegment> segments;
  final Color fallbackColor;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);

    if (total <= 0) {
      final paint = Paint()
        ..color = fallbackColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, 0, math.pi * 2, true, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweep = (segment.value / total) * (math.pi * 2);
      if (sweep <= 0) {
        continue;
      }

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    final centerHolePaint = Paint()
      ..color = centerColor.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(rect.center, size.shortestSide * 0.22, centerHolePaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.fallbackColor != fallbackColor ||
        oldDelegate.centerColor != centerColor;
  }
}
