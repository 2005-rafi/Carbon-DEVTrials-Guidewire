import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/payout/data/payout_api.dart';
import 'package:carbon/features/payout/data/payout_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final payoutErrorProvider = StateProvider<String?>((ref) => null);
final payoutActionErrorProvider = StateProvider<String?>((ref) => null);
final payoutActionLoadingProvider = StateProvider<bool>((ref) => false);
final payoutStatusFilterProvider = StateProvider<PayoutStatus?>((ref) => null);

final payoutAsyncProvider = FutureProvider<List<PayoutRecord>>((ref) async {
  ref.read(payoutErrorProvider.notifier).state = null;
  try {
    return await ref.read(payoutApiProvider).fetchPayouts();
  } catch (error) {
    ref.read(payoutErrorProvider.notifier).state = error.toString();
    return PayoutRecord.fallbackList();
  }
});

final payoutProvider = Provider<List<PayoutRecord>>((ref) {
  return ref
      .watch(payoutAsyncProvider)
      .maybeWhen(data: (records) => records, orElse: PayoutRecord.fallbackList);
});

final filteredPayoutProvider = Provider<List<PayoutRecord>>((ref) {
  final selectedStatus = ref.watch(payoutStatusFilterProvider);
  final records = ref.watch(payoutProvider);

  return records
      .where((record) {
        if (selectedStatus == null) {
          return true;
        }
        return record.normalizedStatus == selectedStatus;
      })
      .toList(growable: false);
});

final payoutSummaryProvider = Provider<PayoutSummary>((ref) {
  return PayoutSummary.fromRecords(ref.watch(payoutProvider));
});

final payoutActionProvider = Provider<PayoutAction>((ref) {
  return PayoutAction(ref);
});

class PayoutAction {
  PayoutAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(payoutActionErrorProvider.notifier).state = null;
  }

  Future<bool> initiatePayout() async {
    _ref.read(payoutActionLoadingProvider.notifier).state = true;
    _ref.read(payoutActionErrorProvider.notifier).state = null;
    try {
      await _ref.read(payoutApiProvider).initiatePayout();
      return true;
    } on ApiException catch (error) {
      _ref.read(payoutActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (_) {
      _ref.read(payoutActionErrorProvider.notifier).state =
          'Unable to initiate payout right now. Please try again.';
      return false;
    } finally {
      _ref.read(payoutActionLoadingProvider.notifier).state = false;
    }
  }
}
