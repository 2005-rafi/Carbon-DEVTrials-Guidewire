import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/utils/formatters.dart';
import 'package:carbon/features/dashboard/provider/dashboard_provider.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:carbon/shared/widgets/app_card.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _openCoreRoute(String routeName) async {
    if (routeName == RouteNames.dashboard) {
      return;
    }
    await NavigationService.instance.pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final dashboardError = ref.watch(dashboardErrorProvider);
    final summary = summaryAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const DashboardSummary(
        activePolicy: false,
        claimsCount: 0,
        totalPayout: 0.0,
        partialDataWarning: '',
        degradedSources: <String>[],
      ),
    );

    final activitiesAsync = ref.watch(dashboardActivityAsyncProvider);
    final workerSnapshot = ref.watch(workerSnapshotProvider);
    final workerStatus = workerSnapshot.status;
    final workerProfile = workerSnapshot.profile;
    final metrics = ref.watch(dashboardMetricsProvider);
    final quickActions = ref.watch(dashboardQuickActionsProvider);
    final activities = ref.watch(dashboardActivityProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final metricColumnCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 560
            ? 2
            : 1;
        final quickActionColumnCount = constraints.maxWidth > 680
            ? 3
            : constraints.maxWidth > 420
            ? 2
            : 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (summaryAsync.isLoading ||
                  activitiesAsync.isLoading) ...<Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SizedBox(height: 28, child: AppLoader()),
                ),
              ],
              if (dashboardError != null) ...<Widget>[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dashboardError,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (summary.partialDataWarning.isNotEmpty) ...<Widget>[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_outlined,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary.partialDataWarning,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Welcome back',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.activePolicy
                          ? 'Your protection is active. Here is your latest overview.'
                          : 'Activate policy to begin automated protection coverage.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Worker Context',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Zone: ${workerProfile.displayZone}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Weekly Income: ${workerProfile.displayWeeklyIncome}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Coverage: ${workerStatus.coverageLabel} | Claims: ${workerStatus.claimEligibilityLabel}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Summary',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                itemCount: metrics.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: metricColumnCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: metricColumnCount == 1 ? 3.2 : 1.55,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final metric = metrics[index];
                  final metricValue = metric.title == 'Total Payout'
                      ? AppFormatters.currency(summary.totalPayout)
                      : metric.value;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openCoreRoute(metric.routeName),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              child: Icon(metric.icon),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    metric.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    metricValue,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Actions',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                itemCount: quickActions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: quickActionColumnCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: quickActionColumnCount == 1 ? 4.3 : 1.2,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final action = quickActions[index];
                  return FilledButton.tonal(
                    onPressed: () => _openCoreRoute(action.routeName),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(action.icon, size: 22),
                        const SizedBox(height: 8),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Recent Activity',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              for (final activity in activities)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    title: activity.title,
                    subtitle: '${activity.subtitle}\n${activity.timeText}',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      AppSnackbar.show(context, activity.title);
                      _openCoreRoute(activity.routeName);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
