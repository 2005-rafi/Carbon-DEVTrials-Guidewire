import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/claims/data/claims_api.dart';
import 'package:carbon/features/claims/data/claims_models.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClaimsCacheSnapshot {
  const ClaimsCacheSnapshot({
    required this.records,
    required this.lastSyncedAt,
    required this.isStale,
  });

  final List<ClaimRecord> records;
  final DateTime? lastSyncedAt;
  final bool isStale;

  ClaimsCacheSnapshot copyWith({
    List<ClaimRecord>? records,
    DateTime? lastSyncedAt,
    bool? isStale,
  }) {
    return ClaimsCacheSnapshot(
      records: records ?? this.records,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isStale: isStale ?? this.isStale,
    );
  }
}

final claimsErrorProvider = StateProvider<String?>((ref) => null);
final claimsActionErrorProvider = StateProvider<String?>((ref) => null);
final claimsActionLoadingProvider = StateProvider<bool>((ref) => false);
final claimsCacheProvider = StateProvider<ClaimsCacheSnapshot?>((ref) => null);

final claimStatusFilterProvider = StateProvider<ClaimStatus?>((ref) => null);
final claimsSearchQueryProvider = StateProvider<String>((ref) => '');

final claimsAsyncProvider = FutureProvider<List<ClaimRecord>>((ref) async {
  ref.read(claimsErrorProvider.notifier).state = null;
  try {
    final records = await ref.read(claimsApiProvider).fetchClaims();
    ref.read(claimsCacheProvider.notifier).state = ClaimsCacheSnapshot(
      records: records,
      lastSyncedAt: DateTime.now(),
      isStale: false,
    );
    return records;
  } on ApiException catch (error) {
    developer.log(error.toString(), name: 'ClaimsProvider');
    final cached = ref.read(claimsCacheProvider);
    if (cached != null) {
      final stale = cached.copyWith(isStale: true);
      ref.read(claimsCacheProvider.notifier).state = stale;
      ref.read(claimsErrorProvider.notifier).state =
          '${error.message} Showing last synced claims.';
      return stale.records;
    }

    ref.read(claimsErrorProvider.notifier).state = error.message;
    return const <ClaimRecord>[];
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected claims load error: $error',
      name: 'ClaimsProvider',
      error: error,
      stackTrace: stackTrace,
    );
    final cached = ref.read(claimsCacheProvider);
    if (cached != null) {
      final stale = cached.copyWith(isStale: true);
      ref.read(claimsCacheProvider.notifier).state = stale;
      ref.read(claimsErrorProvider.notifier).state =
          'Unable to sync latest claims right now. Showing last synced claims.';
      return stale.records;
    }

    ref.read(claimsErrorProvider.notifier).state =
        'Unable to load claims right now.';
    return const <ClaimRecord>[];
  }
});

final claimsProvider = Provider<List<ClaimRecord>>((ref) {
  return ref
      .watch(claimsAsyncProvider)
      .maybeWhen(
        data: (records) => records,
        orElse: () =>
            ref.watch(claimsCacheProvider)?.records ?? const <ClaimRecord>[],
      );
});

final claimsIsStaleProvider = Provider<bool>((ref) {
  return ref.watch(claimsCacheProvider)?.isStale ?? false;
});

final claimsLastSyncedAtProvider = Provider<DateTime?>((ref) {
  return ref.watch(claimsCacheProvider)?.lastSyncedAt;
});

final filteredClaimsProvider = Provider<List<ClaimRecord>>((ref) {
  final allClaims = ref.watch(claimsProvider);
  final selectedStatus = ref.watch(claimStatusFilterProvider);
  final query = ref.watch(claimsSearchQueryProvider).trim().toLowerCase();

  return allClaims
      .where((claim) {
        final matchesStatus = selectedStatus == null
            ? true
            : claim.normalizedStatus == selectedStatus;
        final matchesQuery = query.isEmpty
            ? true
            : claim.id.toLowerCase().contains(query) ||
                  claim.description.toLowerCase().contains(query);

        return matchesStatus && matchesQuery;
      })
      .toList(growable: false);
});

final claimsSummaryProvider = Provider<ClaimsSummary>((ref) {
  return ClaimsSummary.fromRecords(ref.watch(claimsProvider));
});

final claimsActionProvider = Provider<ClaimsAction>((ref) {
  return ClaimsAction(ref);
});

class ClaimsAction {
  ClaimsAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(claimsActionErrorProvider.notifier).state = null;
  }

  Future<bool> createAutoClaim({required String eventId}) async {
    _ref.read(claimsActionLoadingProvider.notifier).state = true;
    _ref.read(claimsActionErrorProvider.notifier).state = null;

    try {
      await _ref.read(workerEligibilityGuardProvider).ensureClaimEligible();
      await _ref.read(claimsApiProvider).createAutoClaim(eventId: eventId);
      _ref.invalidate(claimsAsyncProvider);
      return true;
    } on ApiException catch (error) {
      developer.log(error.toString(), name: 'ClaimsProvider');
      _ref.read(claimsActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected auto-claim action error: $error',
        name: 'ClaimsProvider',
        error: error,
        stackTrace: stackTrace,
      );
      _ref.read(claimsActionErrorProvider.notifier).state =
          'Unable to create auto-claim right now. Please try again.';
      return false;
    } finally {
      _ref.read(claimsActionLoadingProvider.notifier).state = false;
    }
  }
}
