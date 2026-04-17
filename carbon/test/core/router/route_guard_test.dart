import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/router/route_guard.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guardedChild = Text('Protected Child');

  WorkerSnapshot buildSnapshot({
    required String name,
    required String phone,
    required String zone,
  }) {
    return WorkerSnapshot(
      profile: WorkerProfile(
        userId: '72f7e4ed-497e-470f-9782-2e0d9e7302f6',
        name: name,
        phone: phone,
        email: 'user@carbon.app',
        zone: zone,
      ),
      status: const WorkerStatus.unknown(),
      lastSyncedAt: DateTime(2026, 4, 17, 12, 0),
      isStale: false,
    );
  }

  testWidgets('shows protected child when authenticated and profile complete', (
    tester,
  ) async {
    final snapshot = buildSnapshot(
      name: 'Carbon User',
      phone: '9988776655',
      zone: 'MR-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          isAuthenticatedProvider.overrideWith((ref) => true),
          workerSnapshotProvider.overrideWith((ref) => snapshot),
        ],
        child: const MaterialApp(
          home: RouteGuard(child: Scaffold(body: guardedChild)),
        ),
      ),
    );

    expect(find.text('Protected Child'), findsOneWidget);
  });

  testWidgets('blocks protected child when profile is incomplete', (
    tester,
  ) async {
    final snapshot = buildSnapshot(
      name: 'Carbon User',
      phone: '9988776655',
      zone: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          isAuthenticatedProvider.overrideWith((ref) => true),
          workerSnapshotProvider.overrideWith((ref) => snapshot),
        ],
        child: const MaterialApp(
          home: RouteGuard(child: Scaffold(body: guardedChild)),
        ),
      ),
    );

    expect(find.text('Protected Child'), findsNothing);
  });

  testWidgets('allows access when incomplete profile is explicitly allowed', (
    tester,
  ) async {
    final snapshot = buildSnapshot(
      name: 'Carbon User',
      phone: '9988776655',
      zone: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          isAuthenticatedProvider.overrideWith((ref) => true),
          workerSnapshotProvider.overrideWith((ref) => snapshot),
        ],
        child: const MaterialApp(
          home: RouteGuard(
            allowIncompleteProfileAccess: true,
            child: Scaffold(body: guardedChild),
          ),
        ),
      ),
    );

    expect(find.text('Protected Child'), findsOneWidget);
  });
}
