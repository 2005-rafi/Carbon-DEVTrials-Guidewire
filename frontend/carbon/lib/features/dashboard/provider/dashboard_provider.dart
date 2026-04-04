import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/dashboard/data/dashboard_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.activePolicy,
    required this.claimsCount,
    required this.totalPayout,
  });

  final bool activePolicy;
  final int claimsCount;
  final double totalPayout;
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  try {
    final snapshot = await ref
        .read(dashboardApiProvider)
        .fetchDashboardSnapshot();
    return DashboardSummary(
      activePolicy: snapshot.activePolicy,
      claimsCount: snapshot.claimsCount,
      totalPayout: snapshot.totalPayout,
    );
  } catch (_) {
    return const DashboardSummary(
      activePolicy: true,
      claimsCount: 4,
      totalPayout: 3240.00,
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
          activePolicy: true,
          claimsCount: 4,
          totalPayout: 3240.00,
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
            title: 'Claim Approved',
            subtitle: 'Claim CLM-1024 has been approved automatically.',
            timeText: '2h ago',
            routeName: RouteNames.claims,
          ),
          DashboardActivity(
            title: 'Payout Processed',
            subtitle: 'Payout PAY-2201 sent to your account.',
            timeText: '4h ago',
            routeName: RouteNames.payout,
          ),
          DashboardActivity(
            title: 'Disruption Alert',
            subtitle: 'High-severity rainfall event detected nearby.',
            timeText: 'Today',
            routeName: RouteNames.events,
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
  } catch (_) {
    return const <DashboardActivity>[
      DashboardActivity(
        title: 'Claim Approved',
        subtitle: 'Claim CLM-1024 has been approved automatically.',
        timeText: '2h ago',
        routeName: RouteNames.claims,
      ),
      DashboardActivity(
        title: 'Payout Processed',
        subtitle: 'Payout PAY-2201 sent to your account.',
        timeText: '4h ago',
        routeName: RouteNames.payout,
      ),
      DashboardActivity(
        title: 'Disruption Alert',
        subtitle: 'High-severity rainfall event detected nearby.',
        timeText: 'Today',
        routeName: RouteNames.events,
      ),
    ];
  }
});
