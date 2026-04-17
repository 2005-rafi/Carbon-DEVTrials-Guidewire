import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/dashboard/data/dashboard_api.dart';
import 'package:carbon/features/dashboard/provider/dashboard_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardApi extends DashboardApi {
  _FakeDashboardApi({
    required this.snapshot,
    this.activityPayload = const <Map<String, dynamic>>[],
  }) : super(Dio());

  final DashboardSnapshot snapshot;
  final List<Map<String, dynamic>> activityPayload;

  @override
  Future<DashboardSnapshot> fetchDashboardSnapshot() async {
    return snapshot;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    return activityPayload;
  }
}

void main() {
  group('dashboardSummaryProvider', () {
    test('returns partial warning when source data is degraded', () async {
      final fakeApi = _FakeDashboardApi(
        snapshot: const DashboardSnapshot(
          activePolicy: true,
          claimsCount: 3,
          totalPayout: 1840.0,
          hasPartialData: true,
          degradedSources: <String>['analytics', 'claims'],
        ),
      );

      final container = ProviderContainer(
        overrides: <Override>[dashboardApiProvider.overrideWithValue(fakeApi)],
      );
      addTearDown(container.dispose);

      final summary = await container.read(dashboardSummaryProvider.future);

      expect(summary.activePolicy, isTrue);
      expect(summary.claimsCount, 3);
      expect(summary.partialDataWarning, isNotEmpty);
      expect(summary.partialDataWarning, contains('Analytics'));
      expect(summary.partialDataWarning, contains('Claims'));
      expect(
        summary.degradedSources,
        containsAll(<String>['analytics', 'claims']),
      );
    });

    test('keeps warning empty when data is complete', () async {
      final fakeApi = _FakeDashboardApi(
        snapshot: const DashboardSnapshot(
          activePolicy: false,
          claimsCount: 0,
          totalPayout: 0.0,
          hasPartialData: false,
          degradedSources: <String>[],
        ),
      );

      final container = ProviderContainer(
        overrides: <Override>[dashboardApiProvider.overrideWithValue(fakeApi)],
      );
      addTearDown(container.dispose);

      final summary = await container.read(dashboardSummaryProvider.future);
      expect(summary.partialDataWarning, isEmpty);
      expect(summary.degradedSources, isEmpty);
    });
  });

  group('dashboardActivityAsyncProvider', () {
    test('maps remote route names to typed app routes', () async {
      final fakeApi = _FakeDashboardApi(
        snapshot: const DashboardSnapshot(
          activePolicy: true,
          claimsCount: 2,
          totalPayout: 1000.0,
          hasPartialData: false,
          degradedSources: <String>[],
        ),
        activityPayload: const <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'Event update',
            'subtitle': 'Rain alert',
            'timeText': 'Now',
            'routeName': '/events',
          },
          <String, dynamic>{
            'title': 'Fallback update',
            'subtitle': 'Unknown route',
            'timeText': 'Now',
            'routeName': '/not-known',
          },
        ],
      );

      final container = ProviderContainer(
        overrides: <Override>[dashboardApiProvider.overrideWithValue(fakeApi)],
      );
      addTearDown(container.dispose);

      final activities = await container.read(
        dashboardActivityAsyncProvider.future,
      );

      expect(activities, hasLength(2));
      expect(activities.first.routeName, RouteNames.events);
      expect(activities.last.routeName, RouteNames.dashboard);
    });
  });
}
