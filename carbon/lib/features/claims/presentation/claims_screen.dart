import 'package:carbon/core/utils/formatters.dart';
import 'package:carbon/features/claims/data/claims_models.dart';
import 'package:carbon/features/claims/provider/claims_provider.dart';
import 'package:carbon/features/worker/provider/worker_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClaimsScreen extends ConsumerStatefulWidget {
  const ClaimsScreen({super.key});

  @override
  ConsumerState<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends ConsumerState<ClaimsScreen> {
  Widget _stateBanner(
    BuildContext context, {
    required String message,
    required Color background,
    required Color foreground,
    IconData? icon,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSynced(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  Future<void> _showAutoClaimDialog() async {
    final controller = TextEditingController();
    String? dialogError;

    final shouldSubmit =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return AlertDialog(
                  title: const Text('Create Auto-Claim'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Event ID',
                            hintText: 'Enter disruption event id',
                          ),
                        ),
                        if (dialogError != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            dialogError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) {
                          setDialogState(() {
                            dialogError = 'Event ID is required.';
                          });
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Create'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!shouldSubmit) {
      controller.dispose();
      return;
    }

    final success = await ref
        .read(claimsActionProvider)
        .createAutoClaim(eventId: controller.text.trim());
    controller.dispose();

    if (!mounted) {
      return;
    }

    if (!success) {
      final error =
          ref.read(claimsActionErrorProvider) ??
          'Unable to create auto-claim right now.';
      AppSnackbar.show(context, error, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Auto-claim created successfully.');
  }

  Color _statusColor(ClaimStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ClaimStatus.approved:
        return colorScheme.primary;
      case ClaimStatus.pending:
      case ClaimStatus.processing:
        return colorScheme.secondary;
      case ClaimStatus.rejected:
        return colorScheme.error;
      case ClaimStatus.unknown:
        return colorScheme.tertiary;
    }
  }

  String _statusLabel(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.processing:
        return 'Processing';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.unknown:
        return 'Unknown';
    }
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimCard(BuildContext context, ClaimRecord claim) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = claim.normalizedStatus;
    final statusColor = _statusColor(status, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    claim.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              claim.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: <Widget>[
                Text(
                  'Date: ${claim.date}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Amount: ${AppFormatters.currency(claim.amount)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  AppSnackbar.show(context, 'Opening details for ${claim.id}.');
                },
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                label: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(claimsAsyncProvider);
    final claims = ref.watch(filteredClaimsProvider);
    final summary = ref.watch(claimsSummaryProvider);
    final workerSnapshot = ref.watch(workerSnapshotProvider);
    final workerStatus = workerSnapshot.status;
    final workerFetchError = ref.watch(workerFetchErrorProvider);
    final selectedFilter = ref.watch(claimStatusFilterProvider);
    final searchQuery = ref.watch(claimsSearchQueryProvider);
    final backendError = ref.watch(claimsErrorProvider);
    final actionError = ref.watch(claimsActionErrorProvider);
    final actionLoading = ref.watch(claimsActionLoadingProvider);
    final claimsIsStale = ref.watch(claimsIsStaleProvider);
    final claimsLastSyncedAt = ref.watch(claimsLastSyncedAtProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(claimsAsyncProvider);
        await Future.wait<void>(<Future<void>>[
          ref.read(claimsAsyncProvider.future).then((_) {}),
          ref.read(workerActionProvider).refreshIfAuthenticated(),
        ]);
      },
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Your Claims',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track approved, pending, and rejected claims in one place.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) =>
                        ref.read(claimsSearchQueryProvider.notifier).state =
                            value,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search by claim ID or description',
                      suffixIcon: searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () =>
                                  ref
                                          .read(
                                            claimsSearchQueryProvider.notifier,
                                          )
                                          .state =
                                      '',
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedFilter == null,
                        onSelected: (_) =>
                            ref.read(claimStatusFilterProvider.notifier).state =
                                null,
                      ),
                      for (final status in <ClaimStatus>[
                        ClaimStatus.approved,
                        ClaimStatus.pending,
                        ClaimStatus.rejected,
                      ])
                        FilterChip(
                          label: Text(_statusLabel(status)),
                          selected: selectedFilter == status,
                          onSelected: (_) =>
                              ref
                                      .read(claimStatusFilterProvider.notifier)
                                      .state =
                                  status,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final columns = constraints.maxWidth > 700 ? 3 : 1;

                          final summaryCards = <Widget>[
                            _summaryCard(
                              context,
                              label: 'Total Claims',
                              value: '${summary.total}',
                              icon: Icons.assignment_outlined,
                            ),
                            _summaryCard(
                              context,
                              label: 'Approved',
                              value: '${summary.approved}',
                              icon: Icons.check_circle_outline,
                            ),
                            _summaryCard(
                              context,
                              label: 'Pending',
                              value: '${summary.pending}',
                              icon: Icons.timelapse_outlined,
                            ),
                          ];

                          if (columns == 1) {
                            return Column(
                              children: <Widget>[
                                for (var i = 0; i < summaryCards.length; i++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: i == summaryCards.length - 1
                                          ? 0
                                          : 10,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: summaryCards[i],
                                    ),
                                  ),
                              ],
                            );
                          }

                          return GridView.count(
                            crossAxisCount: columns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.65,
                            children: summaryCards,
                          );
                        },
                  ),
                  const SizedBox(height: 14),
                  if (backendError != null)
                    _stateBanner(
                      context,
                      message: backendError,
                      background: colorScheme.errorContainer,
                      foreground: colorScheme.onErrorContainer,
                      icon: Icons.error_outline,
                    ),
                  if (claimsIsStale)
                    _stateBanner(
                      context,
                      message: claimsLastSyncedAt == null
                          ? 'Showing cached claims. Pull to refresh for latest updates.'
                          : 'Showing cached claims from ${_formatLastSynced(claimsLastSyncedAt)}. Pull to refresh for latest updates.',
                      background: colorScheme.tertiaryContainer,
                      foreground: colorScheme.onTertiaryContainer,
                      icon: Icons.sync_problem_outlined,
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: workerStatus.canClaim
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      workerStatus.canClaim
                          ? 'Claim eligibility is active for your worker profile.'
                          : 'Claim eligibility is inactive or unknown. Update profile and status before creating claims.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: workerStatus.canClaim
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  if (workerFetchError != null)
                    _stateBanner(
                      context,
                      message: workerFetchError,
                      background: colorScheme.tertiaryContainer,
                      foreground: colorScheme.onTertiaryContainer,
                      icon: Icons.info_outline,
                    ),
                  if (actionError != null)
                    _stateBanner(
                      context,
                      message: actionError,
                      background: colorScheme.errorContainer,
                      foreground: colorScheme.onErrorContainer,
                      icon: Icons.warning_amber_outlined,
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: actionLoading ? null : _showAutoClaimDialog,
                      icon: actionLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_outlined),
                      label: Text(
                        actionLoading
                            ? 'Creating claim...'
                            : 'Trigger Auto-Claim',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (claimsAsync.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 14),
                child: SizedBox(height: 28, child: AppLoader()),
              ),
            ),
          if (!claimsAsync.isLoading && claims.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.assignment_late_outlined,
                        size: 36,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No claims found for the selected filters.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: actionLoading ? null : _showAutoClaimDialog,
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Create Auto-Claim'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (claims.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.builder(
                itemCount: claims.length,
                itemBuilder: (BuildContext context, int index) {
                  final claim = claims[index];
                  return _claimCard(context, claim);
                },
              ),
            ),
        ],
      ),
    );
  }
}
