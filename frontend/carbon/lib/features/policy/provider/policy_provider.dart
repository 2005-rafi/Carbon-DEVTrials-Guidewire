import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/policy/data/policy_api.dart';
import 'package:carbon/features/policy/data/policy_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final policyLoadingProvider = StateProvider<bool>((ref) => false);
final policyActionErrorProvider = StateProvider<String?>((ref) => null);

final policyDetailsProvider = FutureProvider<PolicyDetails>((ref) async {
  try {
    return await ref.read(policyApiProvider).fetchPolicyDetails();
  } catch (_) {
    return PolicyDetails.fallback();
  }
});

final policySummaryProvider = Provider<PolicySummary>((ref) {
  return ref
      .watch(policyDetailsProvider)
      .maybeWhen(
        data: (details) => details.summary,
        orElse: () => PolicyDetails.fallback().summary,
      );
});

final policyActionProvider = Provider<PolicyAction>((ref) {
  return PolicyAction(ref);
});

class PolicyAction {
  PolicyAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(policyActionErrorProvider.notifier).state = null;
  }

  Future<bool> acceptPolicy() async {
    _ref.read(policyLoadingProvider.notifier).state = true;
    _ref.read(policyActionErrorProvider.notifier).state = null;
    try {
      await _ref.read(policyApiProvider).acceptPolicy();
      return true;
    } on ApiException catch (error) {
      _ref.read(policyActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (_) {
      _ref.read(policyActionErrorProvider.notifier).state =
          'Unable to accept policy right now. Please try again.';
      return false;
    } finally {
      _ref.read(policyLoadingProvider.notifier).state = false;
    }
  }
}
