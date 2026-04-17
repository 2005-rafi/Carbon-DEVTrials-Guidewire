import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/policy/data/policy_api.dart';
import 'package:carbon/features/policy/data/policy_models.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final policyLoadingProvider = StateProvider<bool>((ref) => false);
final policyActionErrorProvider = StateProvider<String?>((ref) => null);
final policyFetchErrorProvider = StateProvider<String?>((ref) => null);

final policyDetailsProvider = FutureProvider<PolicyDetails>((ref) async {
  ref.read(policyFetchErrorProvider.notifier).state = null;

  try {
    return await ref.read(policyApiProvider).fetchPolicyDetails();
  } on ApiException catch (error) {
    developer.log(error.toString(), name: 'PolicyProvider');
    ref.read(policyFetchErrorProvider.notifier).state = error.message;
    return PolicyDetails.empty();
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected policy load error: $error',
      name: 'PolicyProvider',
      error: error,
      stackTrace: stackTrace,
    );
    ref.read(policyFetchErrorProvider.notifier).state =
        'Unable to load policy details right now.';
    return PolicyDetails.empty();
  }
});

final policySummaryProvider = Provider<PolicySummary>((ref) {
  return ref
      .watch(policyDetailsProvider)
      .maybeWhen(
        data: (details) => details.summary,
        orElse: () => PolicyDetails.empty().summary,
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
      await _ref.read(workerEligibilityGuardProvider).ensurePolicyEligible();
      await _ref.read(policyApiProvider).acceptPolicy();
      return true;
    } on ApiException catch (error) {
      developer.log(error.toString(), name: 'PolicyProvider');
      _ref.read(policyActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected policy accept error: $error',
        name: 'PolicyProvider',
        error: error,
        stackTrace: stackTrace,
      );
      _ref.read(policyActionErrorProvider.notifier).state =
          'Unable to accept policy right now. Please try again.';
      return false;
    } finally {
      _ref.read(policyLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> declinePolicy() async {
    _ref.read(policyLoadingProvider.notifier).state = true;
    _ref.read(policyActionErrorProvider.notifier).state = null;
    try {
      await _ref.read(policyApiProvider).declinePolicy();
      return true;
    } on ApiException catch (error) {
      developer.log(error.toString(), name: 'PolicyProvider');
      _ref.read(policyActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected policy decline error: $error',
        name: 'PolicyProvider',
        error: error,
        stackTrace: stackTrace,
      );
      _ref.read(policyActionErrorProvider.notifier).state =
          'Unable to decline policy right now. Please try again.';
      return false;
    } finally {
      _ref.read(policyLoadingProvider.notifier).state = false;
    }
  }
}
