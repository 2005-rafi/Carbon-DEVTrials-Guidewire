import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/features/worker/data/worker_api.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkerSnapshot {
  const WorkerSnapshot({
    required this.profile,
    required this.status,
    required this.lastSyncedAt,
    required this.isStale,
  });

  final WorkerProfile profile;
  final WorkerStatus status;
  final DateTime? lastSyncedAt;
  final bool isStale;

  const WorkerSnapshot.empty()
    : profile = const WorkerProfile.empty(),
      status = const WorkerStatus.unknown(),
      lastSyncedAt = null,
      isStale = true;

  WorkerSnapshot copyWith({
    WorkerProfile? profile,
    WorkerStatus? status,
    DateTime? lastSyncedAt,
    bool? isStale,
  }) {
    return WorkerSnapshot(
      profile: profile ?? this.profile,
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isStale: isStale ?? this.isStale,
    );
  }
}

final workerFetchErrorProvider = StateProvider<String?>((ref) => null);
final workerActionErrorProvider = StateProvider<String?>((ref) => null);
final workerActionLoadingProvider = StateProvider<bool>((ref) => false);
final workerCacheProvider = StateProvider<WorkerSnapshot?>((ref) => null);

final workerSnapshotAsyncProvider = FutureProvider<WorkerSnapshot>((ref) async {
  ref.read(workerFetchErrorProvider.notifier).state = null;
  final api = ref.read(workerApiProvider);

  try {
    final profile = await api.fetchProfile();

    WorkerStatus status = const WorkerStatus.unknown();
    try {
      status = await api.fetchStatus();
    } on ApiException catch (error) {
      developer.log(
        'Worker status fetch fallback: ${error.message}',
        name: 'WorkerProvider',
      );
    }

    final snapshot = WorkerSnapshot(
      profile: profile,
      status: status,
      lastSyncedAt: DateTime.now(),
      isStale: false,
    );

    ref.read(workerCacheProvider.notifier).state = snapshot;
    return snapshot;
  } on ApiException catch (error) {
    final cached = ref.read(workerCacheProvider);
    if (cached != null) {
      final staleSnapshot = cached.copyWith(isStale: true);
      ref.read(workerCacheProvider.notifier).state = staleSnapshot;
      ref.read(workerFetchErrorProvider.notifier).state =
          '${error.message} Showing last synced profile data.';
      return staleSnapshot;
    }

    ref.read(workerFetchErrorProvider.notifier).state = error.message;
    return const WorkerSnapshot.empty();
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected worker snapshot load error: $error',
      name: 'WorkerProvider',
      error: error,
      stackTrace: stackTrace,
    );

    final cached = ref.read(workerCacheProvider);
    if (cached != null) {
      final staleSnapshot = cached.copyWith(isStale: true);
      ref.read(workerCacheProvider.notifier).state = staleSnapshot;
      ref.read(workerFetchErrorProvider.notifier).state =
          'Unable to sync latest worker data. Showing last synced state.';
      return staleSnapshot;
    }

    ref.read(workerFetchErrorProvider.notifier).state =
        'Unable to load worker details right now.';
    return const WorkerSnapshot.empty();
  }
});

final workerSnapshotProvider = Provider<WorkerSnapshot>((ref) {
  return ref
      .watch(workerSnapshotAsyncProvider)
      .maybeWhen(
        data: (snapshot) => snapshot,
        orElse: () =>
            ref.watch(workerCacheProvider) ?? const WorkerSnapshot.empty(),
      );
});

final workerActionProvider = Provider<WorkerAction>((ref) {
  return WorkerAction(ref);
});

final workerEligibilityGuardProvider = Provider<WorkerEligibilityGuard>((ref) {
  return WorkerEligibilityGuard(ref);
});

class WorkerAction {
  WorkerAction(this._ref);

  final Ref _ref;

  void clearActionError() {
    _ref.read(workerActionErrorProvider.notifier).state = null;
  }

  Future<WorkerSnapshot> refresh() async {
    _ref.invalidate(workerSnapshotAsyncProvider);
    return _ref.read(workerSnapshotAsyncProvider.future);
  }

  Future<void> refreshIfAuthenticated() async {
    if (!_ref.read(isAuthenticatedProvider)) {
      return;
    }

    try {
      await refresh();
    } catch (error, stackTrace) {
      developer.log(
        'Worker refresh after auth/resume failed: $error',
        name: 'WorkerProvider',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String zone,
    String? email,
  }) async {
    _ref.read(workerActionLoadingProvider.notifier).state = true;
    _ref.read(workerActionErrorProvider.notifier).state = null;

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null || userId.trim().isEmpty) {
      _ref.read(workerActionLoadingProvider.notifier).state = false;
      _ref.read(workerActionErrorProvider.notifier).state =
          'User identity is missing. Please sign in again.';
      return false;
    }

    final previous = _ref.read(workerSnapshotProvider);

    try {
      final request = WorkerProfileUpdateRequest.fromRaw(
        userId: userId,
        name: name,
        phone: phone,
        zone: zone,
        email: email,
      );
      request.validate();

      final optimisticProfile = previous.profile.copyWith(
        name: request.name,
        phone: request.phone,
        zone: request.zone,
        email: request.email ?? previous.profile.email,
      );

      _ref.read(workerCacheProvider.notifier).state = previous.copyWith(
        profile: optimisticProfile,
        isStale: true,
      );

      final updatedProfile = await _ref
          .read(workerApiProvider)
          .updateProfile(request: request);

      WorkerStatus status = previous.status;
      try {
        status = await _ref.read(workerApiProvider).fetchStatus();
      } on ApiException catch (error) {
        developer.log(
          'Worker status reconcile fallback: ${error.message}',
          name: 'WorkerProvider',
        );
      }

      final snapshot = WorkerSnapshot(
        profile: updatedProfile,
        status: status,
        lastSyncedAt: DateTime.now(),
        isStale: false,
      );

      _ref.read(workerCacheProvider.notifier).state = snapshot;
      _ref.invalidate(workerSnapshotAsyncProvider);
      return true;
    } on ApiException catch (error) {
      _ref.read(workerCacheProvider.notifier).state = previous;
      _ref.read(workerActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected worker update error: $error',
        name: 'WorkerProvider',
        error: error,
        stackTrace: stackTrace,
      );
      _ref.read(workerCacheProvider.notifier).state = previous;
      _ref.read(workerActionErrorProvider.notifier).state =
          'Unable to save profile right now. Please try again.';
      return false;
    } finally {
      _ref.read(workerActionLoadingProvider.notifier).state = false;
    }
  }
}

class WorkerEligibilityGuard {
  WorkerEligibilityGuard(this._ref);

  final Ref _ref;

  Future<WorkerStatus> _resolveStatus({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _ref.read(workerActionProvider).refreshIfAuthenticated();
    }

    try {
      final snapshot = await _ref.read(workerSnapshotAsyncProvider.future);
      return snapshot.status;
    } catch (_) {
      return _ref.read(workerSnapshotProvider).status;
    }
  }

  Future<void> ensurePolicyEligible() async {
    final status = await _resolveStatus(forceRefresh: true);

    if (status.isActive == false) {
      developer.log(
        'event=eligibility_gate_blocks payload={flow: policy, reason: inactive_worker}',
        name: 'WorkerProvider',
      );
      throw const ApiException(
        'Your worker profile is inactive. Activate your worker profile before accepting policy.',
        statusCode: 403,
      );
    }
  }

  Future<void> ensureClaimEligible() async {
    final status = await _resolveStatus(forceRefresh: true);

    if (status.isActive == false) {
      developer.log(
        'event=eligibility_gate_blocks payload={flow: claims, reason: inactive_worker}',
        name: 'WorkerProvider',
      );
      throw const ApiException(
        'Your worker profile is inactive. Claims are unavailable until profile activation.',
        statusCode: 403,
      );
    }

    if (status.eligibleForClaim == false) {
      developer.log(
        'event=eligibility_gate_blocks payload={flow: claims, reason: ineligible_worker}',
        name: 'WorkerProvider',
      );
      throw const ApiException(
        'You are currently not eligible for claim creation.',
        statusCode: 403,
      );
    }
  }
}
