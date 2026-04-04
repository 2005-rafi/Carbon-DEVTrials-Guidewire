import 'package:carbon/features/claims/data/claims_api.dart';
import 'package:carbon/features/claims/data/claims_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final claimsErrorProvider = StateProvider<String?>((ref) => null);

final claimStatusFilterProvider = StateProvider<ClaimStatus?>((ref) => null);
final claimsSearchQueryProvider = StateProvider<String>((ref) => '');

final claimsAsyncProvider = FutureProvider<List<ClaimRecord>>((ref) async {
  ref.read(claimsErrorProvider.notifier).state = null;
  try {
    return await ref.read(claimsApiProvider).fetchClaims();
  } catch (error) {
    ref.read(claimsErrorProvider.notifier).state = error.toString();
    return ClaimRecord.fallbackList();
  }
});

final claimsProvider = Provider<List<ClaimRecord>>((ref) {
  return ref
      .watch(claimsAsyncProvider)
      .maybeWhen(data: (records) => records, orElse: ClaimRecord.fallbackList);
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
