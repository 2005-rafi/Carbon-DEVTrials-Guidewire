import 'package:carbon/features/profile/provider/profile_provider.dart';
import 'package:carbon/features/profile/presentation/profile_screen.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders incomplete profile and worker status sections', (
    WidgetTester tester,
  ) async {
    const viewData = ProfileViewData(
      profile: WorkerProfile(
        userId: 'worker-1',
        name: '',
        phone: '',
        email: '',
        zone: '',
        weeklyIncome: null,
      ),
      status: WorkerStatus(isActive: true, eligibleForClaim: false),
      isStale: false,
      lastSyncedAt: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          profileProvider.overrideWithValue(viewData),
          profileAsyncProvider.overrideWith((ref) async => viewData),
          profileErrorProvider.overrideWith((ref) => null),
          profileActionErrorProvider.overrideWith((ref) => null),
          profileActionLoadingProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'Some profile details are missing. Update your profile to avoid policy and claims issues.',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Coverage Status'), 250);

    expect(find.text('Coverage Status'), findsOneWidget);
    expect(find.text('Claim Eligibility'), findsOneWidget);
    expect(find.text('Not eligible'), findsWidgets);
  });
}
