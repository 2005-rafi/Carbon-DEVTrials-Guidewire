import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/core/utils/formatters.dart';
import 'package:carbon/features/events/data/events_models.dart';
import 'package:carbon/features/events/provider/events_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  int _selectedNavIndex = 1;
  bool _showSearch = false;

  Future<void> _openCoreRoute(String routeName) async {
    if (routeName == RouteNames.events) {
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
        await _openCoreRoute(RouteNames.events);
      case 2:
        await _openCoreRoute(RouteNames.claims);
      case 3:
        await _openCoreRoute(RouteNames.payout);
      case 4:
        await _openCoreRoute(RouteNames.settings);
    }
  }

  String _statusLabel(EventStatus status) {
    switch (status) {
      case EventStatus.active:
        return 'Active';
      case EventStatus.resolved:
        return 'Resolved';
      case EventStatus.critical:
        return 'Critical';
      case EventStatus.unknown:
        return 'Unknown';
    }
  }

  String _severityLabel(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.low:
        return 'Low';
      case EventSeverity.medium:
        return 'Medium';
      case EventSeverity.high:
        return 'High';
      case EventSeverity.critical:
        return 'Critical';
      case EventSeverity.unknown:
        return 'Unknown';
    }
  }

  Color _statusColor(EventStatus status, ColorScheme colorScheme) {
    switch (status) {
      case EventStatus.active:
        return colorScheme.primary;
      case EventStatus.resolved:
        return colorScheme.secondary;
      case EventStatus.critical:
        return colorScheme.error;
      case EventStatus.unknown:
        return colorScheme.tertiary;
    }
  }

  Color _severityColor(EventSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case EventSeverity.low:
        return colorScheme.tertiary;
      case EventSeverity.medium:
        return colorScheme.secondary;
      case EventSeverity.high:
        return colorScheme.primary;
      case EventSeverity.critical:
        return colorScheme.error;
      case EventSeverity.unknown:
        return colorScheme.outline;
    }
  }

  String _formattedDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return AppFormatters.date(parsed.toLocal());
  }

  Future<void> _openFilterSheet() async {
    EventStatus? selectedStatus = ref.read(eventStatusFilterProvider);
    EventSeverity? selectedSeverity = ref.read(eventSeverityFilterProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Filter Disruptions'),
                    const SizedBox(height: 8),
                    const Text('Status'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilterChip(
                          label: const Text('All'),
                          selected: selectedStatus == null,
                          onSelected: (_) {
                            setModalState(() {
                              selectedStatus = null;
                            });
                          },
                        ),
                        for (final status in <EventStatus>[
                          EventStatus.active,
                          EventStatus.resolved,
                          EventStatus.critical,
                        ])
                          FilterChip(
                            label: Text(_statusLabel(status)),
                            selected: selectedStatus == status,
                            onSelected: (_) {
                              setModalState(() {
                                selectedStatus = status;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Severity'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilterChip(
                          label: const Text('All'),
                          selected: selectedSeverity == null,
                          onSelected: (_) {
                            setModalState(() {
                              selectedSeverity = null;
                            });
                          },
                        ),
                        for (final severity in <EventSeverity>[
                          EventSeverity.low,
                          EventSeverity.medium,
                          EventSeverity.high,
                          EventSeverity.critical,
                        ])
                          FilterChip(
                            label: Text(_severityLabel(severity)),
                            selected: selectedSeverity == severity,
                            onSelected: (_) {
                              setModalState(() {
                                selectedSeverity = severity;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                selectedStatus = null;
                                selectedSeverity = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    ref.read(eventStatusFilterProvider.notifier).state = selectedStatus;
    ref.read(eventSeverityFilterProvider.notifier).state = selectedSeverity;
  }

  Future<void> _showEventDetails(EventRecord event) async {
    final textTheme = Theme.of(context).textTheme;

    final openClaims =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(event.title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(event.description),
                    const SizedBox(height: 10),
                    Text('Event ID: ${event.id}', style: textTheme.bodySmall),
                    Text(
                      'Date: ${_formattedDate(event.date)}',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      'Location: ${event.location}',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      'Impact: ${event.impactSummary}',
                      style: textTheme.bodySmall,
                    ),
                    Text(
                      'Related Claim: ${event.relatedClaimId}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Close'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('View Claims'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted || !openClaims) {
      return;
    }
    await _openCoreRoute(RouteNames.claims);
  }

  Future<void> _shareEvent(EventRecord event) async {
    final shareText =
        'Disruption: ${event.title}\n'
        'Status: ${_statusLabel(event.normalizedStatus)}\n'
        'Severity: ${_severityLabel(event.normalizedSeverity)}\n'
        'Location: ${event.location}\n'
        'Date: ${_formattedDate(event.date)}\n'
        'Impact: ${event.impactSummary}';

    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) {
      return;
    }
    AppSnackbar.show(context, 'Event summary copied for sharing.');
  }

  Future<void> _reportDisruption() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    EventSeverity severity = EventSeverity.medium;
    String? formError;

    final shouldSubmit =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return AlertDialog(
                  title: const Text('Report Disruption'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Event title',
                            hintText: 'Heavy Rainfall Alert',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe the disruption impact...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'City / Zone',
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<EventSeverity>(
                          initialValue: severity,
                          decoration: const InputDecoration(
                            labelText: 'Severity',
                          ),
                          items:
                              <EventSeverity>[
                                    EventSeverity.low,
                                    EventSeverity.medium,
                                    EventSeverity.high,
                                    EventSeverity.critical,
                                  ]
                                  .map((value) {
                                    return DropdownMenuItem<EventSeverity>(
                                      value: value,
                                      child: Text(_severityLabel(value)),
                                    );
                                  })
                                  .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() {
                              severity = value;
                            });
                          },
                        ),
                        if (formError != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            formError!,
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
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();
                        if (title.isEmpty || description.isEmpty) {
                          setDialogState(() {
                            formError =
                                'Title and description are required fields.';
                          });
                          return;
                        }

                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!shouldSubmit) {
      titleController.dispose();
      descriptionController.dispose();
      locationController.dispose();
      return;
    }

    final success = await ref
        .read(eventsActionProvider)
        .reportEvent(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          location: locationController.text.trim().isEmpty
              ? 'Unspecified location'
              : locationController.text.trim(),
          severity: severity,
        );

    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();

    if (!mounted) {
      return;
    }

    if (!success) {
      final error =
          ref.read(eventsActionErrorProvider) ??
          'Unable to report disruption right now.';
      AppSnackbar.show(context, error, isError: true);
      return;
    }

    AppSnackbar.show(context, 'Disruption report submitted successfully.');
    ref.invalidate(eventsAsyncProvider);
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
              color: colorScheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(BuildContext context, EventRecord event) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final status = event.normalizedStatus;
    final severity = event.normalizedSeverity;
    final statusColor = _statusColor(status, colorScheme);
    final severityColor = _severityColor(severity, colorScheme);

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
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
              event.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                Text(
                  'Date: ${_formattedDate(event.date)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Location: ${event.location}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Severity: ${_severityLabel(severity)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                'Impact Details',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconColor: colorScheme.primary,
              collapsedIconColor: colorScheme.primary,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    event.impactSummary,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Related Claim: ${event.relatedClaimId}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _showEventDetails(event),
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: () => _shareEvent(event),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share'),
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
    final eventsAsync = ref.watch(eventsAsyncProvider);
    final events = ref.watch(filteredEventsProvider);
    final summary = ref.watch(eventsSummaryProvider);
    final selectedStatus = ref.watch(eventStatusFilterProvider);
    final selectedSeverity = ref.watch(eventSeverityFilterProvider);
    final searchQuery = ref.watch(eventsSearchQueryProvider);
    final backendError = ref.watch(eventsErrorProvider);
    final actionError = ref.watch(eventsActionErrorProvider);
    final actionLoading = ref.watch(eventsActionLoadingProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final appBarActions = <Widget>[
      IconButton(
        tooltip: 'Filter Events',
        onPressed: _openFilterSheet,
        icon: const Icon(Icons.filter_alt_outlined),
      ),
      IconButton(
        tooltip: _showSearch ? 'Hide Search' : 'Search Events',
        onPressed: () {
          setState(() {
            _showSearch = !_showSearch;
          });

          if (!_showSearch) {
            ref.read(eventsSearchQueryProvider.notifier).state = '';
          }
        },
        icon: Icon(_showSearch ? Icons.search_off_outlined : Icons.search),
      ),
      IconButton(
        tooltip: 'Refresh Events',
        onPressed: () => ref.invalidate(eventsAsyncProvider),
        icon: const Icon(Icons.refresh_outlined),
      ),
    ];

    return CoreScaffold(
      currentRoute: RouteNames.events,
      title: 'Disruptions',
      appBarActions: appBarActions,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: _onBottomNavTap,
        backgroundColor: colorScheme.surface,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Claims',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: 'Payouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventsAsyncProvider);
          ref.read(eventsActionProvider).clearError();
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
                      'Active Disruptions',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor disruption severity, resolution status, and claim impact in real time.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_showSearch)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          onChanged: (value) =>
                              ref
                                      .read(eventsSearchQueryProvider.notifier)
                                      .state =
                                  value,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search by title, location, or ID',
                            suffixIcon: searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () =>
                                        ref
                                                .read(
                                                  eventsSearchQueryProvider
                                                      .notifier,
                                                )
                                                .state =
                                            '',
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilterChip(
                          label: const Text('All Status'),
                          selected: selectedStatus == null,
                          onSelected: (_) =>
                              ref
                                      .read(eventStatusFilterProvider.notifier)
                                      .state =
                                  null,
                        ),
                        for (final status in <EventStatus>[
                          EventStatus.active,
                          EventStatus.resolved,
                          EventStatus.critical,
                        ])
                          FilterChip(
                            label: Text(_statusLabel(status)),
                            selected: selectedStatus == status,
                            onSelected: (_) =>
                                ref
                                        .read(
                                          eventStatusFilterProvider.notifier,
                                        )
                                        .state =
                                    status,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilterChip(
                          label: const Text('All Severity'),
                          selected: selectedSeverity == null,
                          onSelected: (_) =>
                              ref
                                      .read(
                                        eventSeverityFilterProvider.notifier,
                                      )
                                      .state =
                                  null,
                        ),
                        for (final severity in <EventSeverity>[
                          EventSeverity.low,
                          EventSeverity.medium,
                          EventSeverity.high,
                          EventSeverity.critical,
                        ])
                          FilterChip(
                            label: Text(_severityLabel(severity)),
                            selected: selectedSeverity == severity,
                            onSelected: (_) =>
                                ref
                                        .read(
                                          eventSeverityFilterProvider.notifier,
                                        )
                                        .state =
                                    severity,
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
                                  label: 'Active Events',
                                  value: '${summary.active}',
                                  icon: Icons.notifications_active_outlined,
                                ),
                                _summaryCard(
                                  context,
                                  label: 'Resolved Events',
                                  value: '${summary.resolved}',
                                  icon: Icons.check_circle_outline,
                                ),
                                _summaryCard(
                                  context,
                                  label: 'High Severity',
                                  value: '${summary.highSeverity}',
                                  icon: Icons.priority_high_outlined,
                                ),
                              ],
                            );
                          },
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: actionLoading ? null : _reportDisruption,
                      icon: actionLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.add_alert_outlined),
                      label: Text(
                        actionLoading ? 'Submitting...' : 'Report Disruption',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (backendError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                    if (actionError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            if (eventsAsync.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: SizedBox(height: 28, child: AppLoader()),
                ),
              ),
            if (!eventsAsync.isLoading && events.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No disruptions found for selected filters.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ),
            if (events.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.builder(
                  itemCount: events.length,
                  itemBuilder: (BuildContext context, int index) {
                    final event = events[index];
                    return _eventCard(context, event);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
