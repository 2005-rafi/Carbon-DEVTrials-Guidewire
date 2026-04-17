import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/dashboard/data/dashboard_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.activePolicy,
    required this.claimsCount,
    required this.totalPayout,
    required this.partialDataWarning,
    required this.degradedSources,
  });

  final bool activePolicy;
  final int claimsCount;
  final double totalPayout;
  final String partialDataWarning;
  final List<String> degradedSources;
}

final dashboardErrorProvider = StateProvider<String?>((ref) => null);

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  ref.read(dashboardErrorProvider.notifier).state = null;
  try {
    final snapshot = await ref
        .read(dashboardApiProvider)
        .fetchDashboardSnapshot();
    return DashboardSummary(
      activePolicy: snapshot.activePolicy,
      claimsCount: snapshot.claimsCount,
      totalPayout: snapshot.totalPayout,
      partialDataWarning: snapshot.hasPartialData
          ? _buildPartialDataWarning(snapshot.degradedSources)
          : '',
      degradedSources: snapshot.degradedSources,
    );
  } on ApiException catch (error) {
    developer.log(error.toString(), name: 'DashboardProvider');
    ref.read(dashboardErrorProvider.notifier).state = error.message;
    return const DashboardSummary(
      activePolicy: false,
      claimsCount: 0,
      totalPayout: 0,
      partialDataWarning: '',
      degradedSources: <String>[],
    );
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected dashboard summary load error: $error',
      name: 'DashboardProvider',
      error: error,
      stackTrace: stackTrace,
    );
    ref.read(dashboardErrorProvider.notifier).state =
        'Unable to load dashboard summary right now.';
    return const DashboardSummary(
      activePolicy: false,
      claimsCount: 0,
      totalPayout: 0,
      partialDataWarning: '',
      degradedSources: <String>[],
    );
  }
});

class DashboardMetric {
  const DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.routeName,
  });

  final String title;
  final String value;
  final IconData icon;
  final String routeName;
}

class DashboardQuickAction {
  const DashboardQuickAction({
    required this.label,
    required this.icon,
    required this.routeName,
  });

  final String label;
  final IconData icon;
  final String routeName;
}

class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.routeName,
  });

  final String title;
  final String subtitle;
  final String timeText;
  final String routeName;
}

final dashboardMetricsProvider = Provider<List<DashboardMetric>>((ref) {
  final summary = ref
      .watch(dashboardSummaryProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => const DashboardSummary(
          activePolicy: false,
          claimsCount: 0,
          totalPayout: 0,
          partialDataWarning: '',
          degradedSources: <String>[],
        ),
      );

  return <DashboardMetric>[
    DashboardMetric(
      title: 'Active Policy',
      value: summary.activePolicy ? 'Yes' : 'No',
      icon: Icons.shield_outlined,
      routeName: RouteNames.policy,
    ),
    DashboardMetric(
      title: 'Claims',
      value: '${summary.claimsCount}',
      icon: Icons.assignment_turned_in_outlined,
      routeName: RouteNames.claims,
    ),
    DashboardMetric(
      title: 'Total Payout',
      value: summary.totalPayout.toStringAsFixed(2),
      icon: Icons.payments_outlined,
      routeName: RouteNames.payout,
    ),
  ];
});

final dashboardQuickActionsProvider = Provider<List<DashboardQuickAction>>((
  ref,
) {
  return const <DashboardQuickAction>[
    DashboardQuickAction(
      label: 'Policy',
      icon: Icons.policy_outlined,
      routeName: RouteNames.policy,
    ),
    DashboardQuickAction(
      label: 'Claims',
      icon: Icons.assignment_outlined,
      routeName: RouteNames.claims,
    ),
    DashboardQuickAction(
      label: 'Payout',
      icon: Icons.account_balance_wallet_outlined,
      routeName: RouteNames.payout,
    ),
    DashboardQuickAction(
      label: 'Events',
      icon: Icons.warning_amber_outlined,
      routeName: RouteNames.events,
    ),
    DashboardQuickAction(
      label: 'Analytics',
      icon: Icons.insights_outlined,
      routeName: RouteNames.analytics,
    ),
    DashboardQuickAction(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      routeName: RouteNames.notifications,
    ),
  ];
});

final dashboardActivityProvider = Provider<List<DashboardActivity>>((ref) {
  return ref
      .watch(dashboardActivityAsyncProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => const <DashboardActivity>[
          DashboardActivity(
            title: 'No recent activity',
            subtitle: 'Live backend updates will appear here.',
            timeText: 'Now',
            routeName: RouteNames.dashboard,
          ),
        ],
      );
});

final dashboardActivityAsyncProvider = FutureProvider<List<DashboardActivity>>((
  ref,
) async {
  try {
    final remote = await ref.read(dashboardApiProvider).fetchRecentActivity();
    return remote.map((item) {
      final rawRoute = (item['routeName'] as String?) ?? RouteNames.dashboard;
      final routeName = switch (rawRoute) {
        '/notifications' => RouteNames.notifications,
        '/events' => RouteNames.events,
        '/claims' => RouteNames.claims,
        '/payout' => RouteNames.payout,
        _ => RouteNames.dashboard,
      };

      return DashboardActivity(
        title: (item['title'] as String?) ?? 'Activity Update',
        subtitle:
            (item['subtitle'] as String?) ??
            'You have a new account activity update.',
        timeText: (item['timeText'] as String?) ?? 'Recently',
        routeName: routeName,
      );
    }).toList();
  } on ApiException catch (error) {
    developer.log(error.toString(), name: 'DashboardProvider');
    ref.read(dashboardErrorProvider.notifier).state = error.message;
    return const <DashboardActivity>[];
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected dashboard activity load error: $error',
      name: 'DashboardProvider',
      error: error,
      stackTrace: stackTrace,
    );
    ref.read(dashboardErrorProvider.notifier).state ??=
        'Unable to load recent dashboard activity right now.';
    return const <DashboardActivity>[];
  }
});

String _buildPartialDataWarning(List<String> degradedSources) {
  if (degradedSources.isEmpty) {
    return '';
  }

  final labels = degradedSources
      .map((source) => _dashboardSourceLabel(source))
      .toSet()
      .toList(growable: false);

  final sourceList = labels.join(', ');
  return 'Some dashboard data is temporarily unavailable ($sourceList). Values shown are partial.';
}

String _dashboardSourceLabel(String source) {
  switch (source.trim().toLowerCase()) {
    case 'analytics':
      return 'Analytics';
    case 'claims':
      return 'Claims';
    case 'payout':
      return 'Payouts';
    case 'policy':
      return 'Policy';
    default:
      return 'Service';
  }
}
