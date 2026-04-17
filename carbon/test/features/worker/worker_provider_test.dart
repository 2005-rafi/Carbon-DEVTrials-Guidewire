import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerEligibilityGuard', () {
    test('allows policy acceptance when worker is active', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          workerSnapshotAsyncProvider.overrideWith((ref) async {
            return WorkerSnapshot(
              profile: const WorkerProfile.empty(),
              status: WorkerStatus.fromMap(<String, dynamic>{
                'is_active': true,
                'eligible_for_claim': true,
              }),
              lastSyncedAt: DateTime(2026, 4, 17, 10, 0),
              isStale: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(workerEligibilityGuardProvider).ensurePolicyEligible(),
        completes,
      );
    });

    test('blocks policy acceptance when worker is inactive', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          workerSnapshotAsyncProvider.overrideWith((ref) async {
            return WorkerSnapshot(
              profile: const WorkerProfile.empty(),
              status: WorkerStatus.fromMap(<String, dynamic>{
                'is_active': false,
                'eligible_for_claim': true,
              }),
              lastSyncedAt: DateTime(2026, 4, 17, 10, 0),
              isStale: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(workerEligibilityGuardProvider).ensurePolicyEligible(),
        throwsA(isA<ApiException>()),
      );
    });

    test('blocks claim creation when eligibility is false', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          workerSnapshotAsyncProvider.overrideWith((ref) async {
            return WorkerSnapshot(
              profile: const WorkerProfile.empty(),
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

      await expectLater(
        container.read(workerEligibilityGuardProvider).ensureClaimEligible(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
