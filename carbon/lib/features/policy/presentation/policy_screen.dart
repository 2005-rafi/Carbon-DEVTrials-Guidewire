import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/policy/data/policy_models.dart';
import 'package:carbon/features/policy/provider/policy_provider.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PolicyScreen extends ConsumerStatefulWidget {
  const PolicyScreen({super.key});

  @override
  ConsumerState<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends ConsumerState<PolicyScreen> {
  Future<void> _onDeclinePolicy() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldDecline =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Decline Policy?'),
              content: const Text(
                'You can review policy terms later, but protection features may remain inactive until accepted.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    foregroundColor: colorScheme.onSecondary,
                    backgroundColor: colorScheme.secondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Decline'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDecline) {
      return;
    }

    final ok = await ref.read(policyActionProvider).declinePolicy();
    if (!mounted) {
      return;
    }

    if (!ok) {
      final error =
          ref.read(policyActionErrorProvider) ??
          'Unable to decline policy right now. Please try again.';
      AppSnackbar.show(context, error, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Policy declined successfully.');
    await NavigationService.instance.pushReplacementNamed(RouteNames.dashboard);
  }

  Future<void> _onAcceptPolicy() async {
    final ok = await ref.read(policyActionProvider).acceptPolicy();
    if (!mounted) {
      return;
    }

    if (!ok) {
      final error =
          ref.read(policyActionErrorProvider) ??
          'Unable to accept policy right now. Please try again.';
      AppSnackbar.show(context, error, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Policy accepted successfully.');
  }

  Widget _summaryItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(BuildContext context, PolicySection section) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        title: Text(
          section.title,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.primary,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              section.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
          ),
          if (section.bullets.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final policyAsync = ref.watch(policyDetailsProvider);
    final policyFetchError = ref.watch(policyFetchErrorProvider);
    final workerSnapshot = ref.watch(workerSnapshotProvider);
    final workerStatus = workerSnapshot.status;
    final workerFetchError = ref.watch(workerFetchErrorProvider);
    final policy = policyAsync.maybeWhen(
      data: (details) => details,
      orElse: PolicyDetails.empty,
    );

    final isSubmitting = ref.watch(policyLoadingProvider);
    final actionError = ref.watch(policyActionErrorProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CoreScaffold(
      currentRoute: RouteNames.policy,
      title: 'Policy Details',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(policyDetailsProvider);
          ref.read(policyActionProvider).clearError();
          await ref.read(workerActionProvider).refreshIfAuthenticated();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (policyAsync.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SizedBox(height: 30, child: AppLoader()),
              ),
            if (policyFetchError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  policyFetchError,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: workerStatus.isCoverageActive
                    ? colorScheme.primaryContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                workerStatus.isCoverageActive
                    ? 'Worker profile is active. Policy acceptance is available.'
                    : 'Worker profile is inactive or unknown. Activate profile from Profile screen to proceed.',
                style: textTheme.bodyMedium?.copyWith(
                  color: workerStatus.isCoverageActive
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            if (workerFetchError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  workerFetchError,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Policy Overview',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review your active terms, payout mechanism, and coverage sections before confirming.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Policy Summary',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _summaryItem(
                      context,
                      label: 'Product Type',
                      value: policy.productType,
                    ),
                    _summaryItem(
                      context,
                      label: 'Plan',
                      value: policy.planName,
                    ),
                    _summaryItem(
                      context,
                      label: 'Coverage',
                      value: policy.coverage,
                    ),
                    _summaryItem(
                      context,
                      label: 'Premium',
                      value: policy.summary.premium,
                    ),
                    _summaryItem(
                      context,
                      label: 'Waiting Period',
                      value: policy.waitingPeriod,
                    ),
                    _summaryItem(
                      context,
                      label: 'Payout',
                      value: policy.payoutMechanism,
                    ),
                    _summaryItem(
                      context,
                      label: 'Status',
                      value: policy.status,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Policy Sections',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final section in policy.sections)
              _sectionTile(context, section),
            if (actionError != null) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  actionError,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isSubmitting || workerStatus.isActive == false
                  ? null
                  : _onAcceptPolicy,
              icon: isSubmitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(isSubmitting ? 'Submitting...' : 'Accept Policy'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : _onDeclinePolicy,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Decline / Back'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: colorScheme.secondary,
                side: BorderSide(color: colorScheme.secondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
