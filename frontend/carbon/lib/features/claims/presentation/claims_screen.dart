import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/utils/formatters.dart';
import 'package:carbon/features/claims/data/claims_models.dart';
import 'package:carbon/features/claims/provider/claims_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClaimsScreen extends ConsumerStatefulWidget {
  const ClaimsScreen({super.key});

  @override
  ConsumerState<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends ConsumerState<ClaimsScreen> {
  int _selectedNavIndex = 1;

  Future<void> _openCoreRoute(String routeName) async {
    if (routeName == RouteNames.claims) {
      return;
    }
    await NavigationService.instance.pushReplacementNamed(routeName);
  }

  Future<void> _onBottomNavTap(int index) async {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        await _openCoreRoute(RouteNames.dashboard);
      case 1:
        await _openCoreRoute(RouteNames.claims);
      case 2:
        await _openCoreRoute(RouteNames.profile);
      case 3:
        await _openCoreRoute(RouteNames.settings);
    }
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

  Future<void> _openFilterSheet() async {
    final selected = ref.read(claimStatusFilterProvider);
    final result = await showModalBottomSheet<ClaimStatus?>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Filter by status'),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('All'),
                  trailing: selected == null
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onTap: () => Navigator.of(context).pop(null),
                ),
                for (final status in <ClaimStatus>[
                  ClaimStatus.approved,
                  ClaimStatus.pending,
                  ClaimStatus.rejected,
                ])
                  ListTile(
                    title: Text(_statusLabel(status)),
                    trailing: selected == status
                        ? const Icon(Icons.check, size: 18)
                        : null,
                    onTap: () => Navigator.of(context).pop(status),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    ref.read(claimStatusFilterProvider.notifier).state = result;
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
    final selectedFilter = ref.watch(claimStatusFilterProvider);
    final searchQuery = ref.watch(claimsSearchQueryProvider);
    final backendError = ref.watch(claimsErrorProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final appBarActions = <Widget>[
      IconButton(
        tooltip: 'Filter Claims',
        onPressed: _openFilterSheet,
        icon: const Icon(Icons.filter_alt_outlined),
      ),
      IconButton(
        tooltip: 'Refresh Claims',
        onPressed: () => ref.invalidate(claimsAsyncProvider),
        icon: const Icon(Icons.refresh_outlined),
      ),
    ];

    return CoreScaffold(
      currentRoute: RouteNames.claims,
      title: 'Claims',
      appBarActions: appBarActions,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: _onBottomNavTap,
        backgroundColor: colorScheme.surface,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Claims',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(claimsAsyncProvider);
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
                                              claimsSearchQueryProvider
                                                  .notifier,
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
                              ref
                                      .read(claimStatusFilterProvider.notifier)
                                      .state =
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
                                        .read(
                                          claimStatusFilterProvider.notifier,
                                        )
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
                              ],
                            );
                          },
                    ),
                    const SizedBox(height: 14),
                    if (backendError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                    child: Text(
                      'No claims found for the selected filters.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.center,
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
      ),
    );
  }
}
