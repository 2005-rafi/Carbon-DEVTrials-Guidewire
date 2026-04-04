import 'package:carbon/core/router/navigation_service.dart';
import 'package:carbon/core/router/route_names.dart';
import 'package:carbon/features/notifications/data/notification_models.dart';
import 'package:carbon/features/notifications/provider/notification_provider.dart';
import 'package:carbon/shared/widgets/app_loader.dart';
import 'package:carbon/shared/widgets/app_snackbar.dart';
import 'package:carbon/shared/widgets/core_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  int _selectedNavIndex = 1;
  bool _showSearch = false;

  Future<void> _openCoreRoute(String routeName) async {
    if (routeName == RouteNames.notifications) {
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
        await _openCoreRoute(RouteNames.notifications);
      case 2:
        await _openCoreRoute(RouteNames.claims);
      case 3:
        await _openCoreRoute(RouteNames.analytics);
      case 4:
        await _openCoreRoute(RouteNames.settings);
    }
  }

  String _statusLabel(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.read:
        return 'Read';
      case NotificationStatus.unread:
        return 'Unread';
      case NotificationStatus.unknown:
        return 'Unknown';
    }
  }

  String _typeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.claim:
        return 'Claim';
      case NotificationType.payout:
        return 'Payout';
      case NotificationType.event:
        return 'Event';
      case NotificationType.analytics:
        return 'Analytics';
      case NotificationType.system:
        return 'System';
      case NotificationType.unknown:
        return 'Other';
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.claim:
        return Icons.assignment_outlined;
      case NotificationType.payout:
        return Icons.payments_outlined;
      case NotificationType.event:
        return Icons.warning_amber_outlined;
      case NotificationType.analytics:
        return Icons.insights_outlined;
      case NotificationType.system:
        return Icons.settings_outlined;
      case NotificationType.unknown:
        return Icons.notifications_outlined;
    }
  }

  Color _statusColor(NotificationStatus status, ColorScheme colorScheme) {
    switch (status) {
      case NotificationStatus.read:
        return colorScheme.secondary;
      case NotificationStatus.unread:
        return colorScheme.primary;
      case NotificationStatus.unknown:
        return colorScheme.tertiary;
    }
  }

  String _formattedTimestamp(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    final local = parsed.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final day = twoDigits(local.day);
    final month = twoDigits(local.month);
    final year = local.year;
    final hour = twoDigits(local.hour);
    final minute = twoDigits(local.minute);
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _openFilterSheet() async {
    NotificationStatus? selectedStatus = ref.read(
      notificationStatusFilterProvider,
    );
    NotificationType? selectedType = ref.read(notificationTypeFilterProvider);
    bool unreadOnly = ref.read(notificationUnreadOnlyProvider);

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
                    const Text('Filter Notifications'),
                    const SizedBox(height: 10),
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
                        for (final status in <NotificationStatus>[
                          NotificationStatus.unread,
                          NotificationStatus.read,
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
                    const SizedBox(height: 10),
                    const Text('Category'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilterChip(
                          label: const Text('All'),
                          selected: selectedType == null,
                          onSelected: (_) {
                            setModalState(() {
                              selectedType = null;
                            });
                          },
                        ),
                        for (final type in <NotificationType>[
                          NotificationType.claim,
                          NotificationType.payout,
                          NotificationType.event,
                          NotificationType.analytics,
                          NotificationType.system,
                        ])
                          FilterChip(
                            label: Text(_typeLabel(type)),
                            selected: selectedType == type,
                            onSelected: (_) {
                              setModalState(() {
                                selectedType = type;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show unread only'),
                      value: unreadOnly,
                      onChanged: (value) {
                        setModalState(() {
                          unreadOnly = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                selectedStatus = null;
                                selectedType = null;
                                unreadOnly = false;
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

    ref.read(notificationStatusFilterProvider.notifier).state = selectedStatus;
    ref.read(notificationTypeFilterProvider.notifier).state = selectedType;
    ref.read(notificationUnreadOnlyProvider.notifier).state = unreadOnly;
  }

  Future<void> _confirmClearAll() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldClear =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Clear Notifications?'),
              content: const Text(
                'This will hide all notifications from the current view. Continue?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Clear'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldClear) {
      return;
    }

    ref.read(notificationActionProvider).clearAllLocalNotifications();
    if (!mounted) {
      return;
    }
    AppSnackbar.show(context, 'Notifications cleared from current view.');
  }

  Future<void> _markAllAsRead() async {
    final ok = await ref.read(notificationActionProvider).markAllAsRead();
    if (!mounted) {
      return;
    }

    if (!ok) {
      final error =
          ref.read(notificationActionErrorProvider) ??
          'Unable to mark all as read.';
      AppSnackbar.show(context, error, isError: true);
      return;
    }

    final partialError = ref.read(notificationActionErrorProvider);
    if (partialError != null) {
      AppSnackbar.show(context, partialError, isError: true);
      return;
    }

    AppSnackbar.show(context, 'All notifications marked as read.');
  }

  Future<void> _openNotificationDetails(AppNotification item) async {
    final shouldNavigate =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(item.title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(item.message),
                    const SizedBox(height: 10),
                    Text('Type: ${_typeLabel(item.normalizedType)}'),
                    Text('Status: ${_statusLabel(item.normalizedStatus)}'),
                    Text('Time: ${_formattedTimestamp(item.timestamp)}'),
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
                  child: const Text('View Details'),
                ),
              ],
            );
          },
        ) ??
        false;

    final _ = await ref.read(notificationActionProvider).markAsRead(item);

    if (!mounted || !shouldNavigate) {
      return;
    }

    switch (item.normalizedType) {
      case NotificationType.claim:
        await _openCoreRoute(RouteNames.claims);
      case NotificationType.payout:
        await _openCoreRoute(RouteNames.payout);
      case NotificationType.event:
        await _openCoreRoute(RouteNames.events);
      case NotificationType.analytics:
        await _openCoreRoute(RouteNames.analytics);
      case NotificationType.system:
      case NotificationType.unknown:
        await _openCoreRoute(RouteNames.dashboard);
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24)),
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
              color: colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification item) {
    final action = ref.read(notificationActionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = item.normalizedStatus;
    final statusColor = _statusColor(status, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: status == NotificationStatus.unread
          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
          : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(
                    _typeIcon(item.normalizedType),
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (status == NotificationStatus.unread)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _typeLabel(item.normalizedType),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
                Text(
                  _formattedTimestamp(item.timestamp),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                'Message Details',
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
                    item.message,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.82),
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
                  onPressed: () => _openNotificationDetails(item),
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: const Text('View Details'),
                ),
                if (status == NotificationStatus.unread)
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await action.markAsRead(item);
                      if (!context.mounted) {
                        return;
                      }
                      if (!ok) {
                        final error =
                            ref.read(notificationActionErrorProvider) ??
                            'Unable to mark as read.';
                        AppSnackbar.show(context, error, isError: true);
                        return;
                      }

                      AppSnackbar.show(context, 'Marked as read.');
                    },
                    icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                    label: const Text('Mark Read'),
                  ),
                TextButton.icon(
                  onPressed: () {
                    action.dismissNotification(item.id);
                    AppSnackbar.show(context, 'Notification dismissed.');
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Dismiss'),
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
    final notificationAsync = ref.watch(notificationAsyncProvider);
    final notifications = ref.watch(filteredNotificationProvider);
    final summary = ref.watch(notificationSummaryProvider);
    final searchQuery = ref.watch(notificationSearchQueryProvider);
    final backendError = ref.watch(notificationErrorProvider);
    final actionError = ref.watch(notificationActionErrorProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final appBarActions = <Widget>[
      IconButton(
        tooltip: _showSearch ? 'Hide Search' : 'Search Notifications',
        onPressed: () {
          setState(() {
            _showSearch = !_showSearch;
          });
          if (!_showSearch) {
            ref.read(notificationSearchQueryProvider.notifier).state = '';
          }
        },
        icon: Icon(_showSearch ? Icons.search_off_outlined : Icons.search),
      ),
      IconButton(
        tooltip: 'Filter Notifications',
        onPressed: _openFilterSheet,
        icon: const Icon(Icons.filter_alt_outlined),
      ),
      IconButton(
        tooltip: 'Mark all as read',
        onPressed: _markAllAsRead,
        icon: const Icon(Icons.done_all_outlined),
      ),
      IconButton(
        tooltip: 'Clear all',
        onPressed: _confirmClearAll,
        icon: const Icon(Icons.delete_sweep_outlined),
      ),
    ];

    return CoreScaffold(
      currentRoute: RouteNames.notifications,
      title: 'Notifications',
      appBarActions: appBarActions,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: _onBottomNavTap,
        backgroundColor: colorScheme.surface,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Claims',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationAsyncProvider);
          ref.read(notificationActionProvider).clearError();
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
                      'Notification Center',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track claim, payout, event, and analytics alerts in real time.',
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
                              childAspectRatio: columns == 1 ? 3.8 : 1.7,
                              children: <Widget>[
                                _summaryCard(
                                  context,
                                  label: 'Total',
                                  value: '${summary.total}',
                                  icon: Icons.notifications_outlined,
                                ),
                                _summaryCard(
                                  context,
                                  label: 'Unread',
                                  value: '${summary.unread}',
                                  icon: Icons.mark_email_unread_outlined,
                                ),
                                _summaryCard(
                                  context,
                                  label: 'Read',
                                  value: '${summary.read}',
                                  icon: Icons.drafts_outlined,
                                ),
                              ],
                            );
                          },
                    ),
                    if (_showSearch) ...<Widget>[
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (value) =>
                            ref
                                    .read(
                                      notificationSearchQueryProvider.notifier,
                                    )
                                    .state =
                                value,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search notifications',
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () =>
                                      ref
                                              .read(
                                                notificationSearchQueryProvider
                                                    .notifier,
                                              )
                                              .state =
                                          '',
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
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
            if (notificationAsync.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: SizedBox(height: 28, child: AppLoader()),
                ),
              ),
            if (!notificationAsync.isLoading && notifications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No notifications to show for the selected filters.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ),
            if (notifications.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.builder(
                  itemCount: notifications.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = notifications[index];
                    return _notificationCard(context, item);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
