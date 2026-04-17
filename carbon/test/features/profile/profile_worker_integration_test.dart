import 'package:carbon/features/profile/data/worker_models.dart';
import 'package:carbon/features/profile/provider/profile_provider.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerProfile.fromMap', () {
    test('reads worker profile fields from contract keys', () {
      final profile = WorkerProfile.fromMap(<String, dynamic>{
        'user_id': 'worker-1',
        'name': 'Asha',
        'phone': '+91 9000000000',
        'zone': 'MR-2',
        'weekly_income': 2450.5,
      });

      expect(profile.userId, 'worker-1');
      expect(profile.name, 'Asha');
      expect(profile.phone, '+91 9000000000');
      expect(profile.zone, 'MR-2');
      expect(profile.weeklyIncome, 2450.5);
      expect(profile.displayWeeklyIncome, 'INR 2450.50');
    });
  });

  group('profileAsyncProvider', () {
    test('maps worker snapshot into profile view state', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          workerSnapshotAsyncProvider.overrideWith((ref) async {
            return WorkerSnapshot(
              profile: WorkerProfile.fromMap(<String, dynamic>{
                'name': 'Meera',
                'phone': '+91 9777777777',
                'zone': 'MR-4',
              }),
              status: WorkerStatus.fromMap(<String, dynamic>{
                'is_active': true,
                'eligible_for_claim': false,
              }),
              lastSyncedAt: DateTime(2026, 4, 17, 10, 0),
              isStale: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(profileAsyncProvider.future);

      expect(data.profile.displayName, 'Meera');
      expect(data.status.coverageLabel, 'Active');
      expect(data.status.claimEligibilityLabel, 'Not eligible');
      expect(data.isStale, isFalse);
      expect(data.lastSyncedAt, DateTime(2026, 4, 17, 10, 0));
    });

    test('exposes worker fetch error via profileErrorProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(workerFetchErrorProvider.notifier).state =
          'profile unavailable';

      expect(container.read(profileErrorProvider), 'profile unavailable');
    });
  });
}
