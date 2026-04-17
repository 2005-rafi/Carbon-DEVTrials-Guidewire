import 'package:carbon/core/utils/formatters.dart';
import 'package:carbon/features/payout/data/payout_models.dart';
import 'package:carbon/features/payout/provider/payout_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  String _statusLabel(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.unknown:
        return 'Unknown';
    }
  }

  Color _statusColor(PayoutStatus status, ColorScheme colorScheme) {
    switch (status) {
      case PayoutStatus.completed:
        return colorScheme.primary;
      case PayoutStatus.pending:
      case PayoutStatus.processing:
        return colorScheme.secondary;
      case PayoutStatus.failed:
        return colorScheme.error;
      case PayoutStatus.unknown:
        return colorScheme.tertiary;
    }
  }

  Future<void> _initiatePayout() async {
    final ok = await ref.read(payoutActionProvider).initiatePayout();
    if (!mounted) {
      return;
    }

    if (!ok) {
      final message =
          ref.read(payoutActionErrorProvider) ??
          'Unable to initiate payout right now. Please try again.';
      AppSnackbar.show(context, message, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Payout request submitted successfully.');
    ref.invalidate(payoutAsyncProvider);
  }

  Future<void> _retryPayoutRecord(PayoutRecord record) async {
    final ok = await ref.read(payoutActionProvider).retryPayout(record.id);
    if (!mounted) {
      return;
    }

    if (!ok) {
      final message =
          ref.read(payoutActionErrorProvider) ??
          'Unable to retry payout right now. Please try again.';
      AppSnackbar.show(context, message, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Payout retry requested for ${record.id}.');
    ref.invalidate(payoutAsyncProvider);
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payoutCard(BuildContext context, PayoutRecord record) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = record.normalizedStatus;
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
                    record.id,
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
                    color: statusColor.withValues(alpha: 0.15),
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
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: <Widget>[
                Text(
                  'Amount: ${AppFormatters.currency(record.amount)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.84),
                  ),
                ),
                Text(
                  'Date: ${record.date}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Method: ${record.paymentMethod}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () {
                    AppSnackbar.show(
                      context,
                      'Receipt download for ${record.id} will be available shortly.',
                    );
                  },
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download Receipt'),
                ),
                if (status == PayoutStatus.failed)
                  FilledButton.tonalIcon(
                    onPressed: () => _retryPayoutRecord(record),
                    icon: const Icon(Icons.refresh_outlined, size: 18),
                    label: const Text('Retry Payout'),
                  ),
                TextButton.icon(
                  onPressed: () {
                    AppSnackbar.show(
                      context,
                      'Opening payout details for ${record.id}.',
                    );
                  },
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payoutAsync = ref.watch(payoutAsyncProvider);
    final payouts = ref.watch(filteredPayoutProvider);
    final summary = ref.watch(payoutSummaryProvider);
    final backendError = ref.watch(payoutErrorProvider);
    final actionError = ref.watch(payoutActionErrorProvider);
    final isActionLoading = ref.watch(payoutActionLoadingProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(payoutAsyncProvider);
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
                    'Payout Overview',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track payout transactions, status changes, and available amounts.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final columns = constraints.maxWidth > 700 ? 3 : 1;
                          return GridView.count(
                            crossAxisCount: columns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: columns == 1 ? 3.8 : 1.65,
                            children: <Widget>[
                              _summaryCard(
                                context,
                                label: 'Total Earnings',
                                value: AppFormatters.currency(
                                  summary.totalEarnings,
                                ),
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              _summaryCard(
                                context,
                                label: 'Total Payouts',
                                value: '${summary.totalPayouts}',
                                icon: Icons.check_circle_outline,
                              ),
                              _summaryCard(
                                context,
                                label: 'Pending Amount',
                                value: AppFormatters.currency(
                                  summary.pendingAmount,
                                ),
                                icon: Icons.pending_actions_outlined,
                              ),
                            ],
                          );
                        },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isActionLoading ? null : _initiatePayout,
                    icon: isActionLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      isActionLoading ? 'Submitting...' : 'Initiate Payout',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(payoutStatusFilterProvider.notifier).state =
                          null;
                      AppSnackbar.show(
                        context,
                        'Viewing complete payout history.',
                      );
                    },
                    icon: const Icon(Icons.history_outlined),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: colorScheme.secondary,
                      side: BorderSide(color: colorScheme.secondary),
                    ),
                  ),
                  if (backendError != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        backendError,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
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
                ],
              ),
            ),
          ),
          if (payoutAsync.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 14),
                child: SizedBox(height: 28, child: AppLoader()),
              ),
            ),
          if (!payoutAsync.isLoading && payouts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No payout transactions found for the selected filters.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ),
          if (payouts.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList.builder(
                itemCount: payouts.length,
                itemBuilder: (BuildContext context, int index) {
                  final record = payouts[index];
                  return _payoutCard(context, record);
                },
              ),
            ),
        ],
      ),
    );
  }
}
