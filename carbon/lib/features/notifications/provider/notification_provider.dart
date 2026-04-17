import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/notifications/data/notification_api.dart';
import 'package:carbon/features/notifications/data/notification_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationErrorProvider = StateProvider<String?>((ref) => null);
final notificationActionErrorProvider = StateProvider<String?>((ref) => null);
final notificationActionLoadingProvider = StateProvider<bool>((ref) => false);

final notificationStatusFilterProvider = StateProvider<NotificationStatus?>(
  (ref) => null,
);
final notificationTypeFilterProvider = StateProvider<NotificationType?>(
  (ref) => null,
);
final notificationSearchQueryProvider = StateProvider<String>((ref) => '');
final notificationUnreadOnlyProvider = StateProvider<bool>((ref) => false);

final readNotificationIdsProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);
final dismissedNotificationIdsProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);

final notificationAsyncProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  ref.read(notificationErrorProvider.notifier).state = null;

  try {
    return await ref.read(notificationApiProvider).fetchNotifications();
  } on ApiException catch (error) {
    developer.log(error.toString(), name: 'NotificationProvider');
    ref.read(notificationErrorProvider.notifier).state = error.message;
    return const <AppNotification>[];
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected notifications load error: $error',
      name: 'NotificationProvider',
      error: error,
      stackTrace: stackTrace,
    );
    ref.read(notificationErrorProvider.notifier).state =
        'Unable to load notifications right now.';
    return const <AppNotification>[];
  }
});

final notificationProvider = Provider<List<AppNotification>>((ref) {
  final records = ref
      .watch(notificationAsyncProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <AppNotification>[]);

  final readIds = ref.watch(readNotificationIdsProvider);
  final dismissedIds = ref.watch(dismissedNotificationIdsProvider);

  final visible = <AppNotification>[];
  for (final record in records) {
    if (dismissedIds.contains(record.id)) {
      continue;
    }

    if (readIds.contains(record.id) &&
        record.normalizedStatus != NotificationStatus.read) {
      visible.add(record.copyWith(status: 'Read'));
    } else {
      visible.add(record);
    }
  }

  return visible;
});

final filteredNotificationProvider = Provider<List<AppNotification>>((ref) {
  final records = ref.watch(notificationProvider);
  final selectedStatus = ref.watch(notificationStatusFilterProvider);
  final selectedType = ref.watch(notificationTypeFilterProvider);
  final unreadOnly = ref.watch(notificationUnreadOnlyProvider);
  final query = ref.watch(notificationSearchQueryProvider).trim().toLowerCase();

  return records
      .where((record) {
        final matchesStatus = selectedStatus == null
            ? true
            : record.normalizedStatus == selectedStatus;

        final matchesType = selectedType == null
            ? true
            : record.normalizedType == selectedType;

        final matchesUnreadOnly = unreadOnly
            ? record.normalizedStatus == NotificationStatus.unread
            : true;

        final matchesQuery = query.isEmpty
            ? true
            : record.title.toLowerCase().contains(query) ||
                  record.subtitle.toLowerCase().contains(query) ||
                  record.message.toLowerCase().contains(query);

        return matchesStatus &&
            matchesType &&
            matchesUnreadOnly &&
            matchesQuery;
      })
      .toList(growable: false);
});

final notificationSummaryProvider = Provider<NotificationSummary>((ref) {
  return NotificationSummary.fromRecords(ref.watch(notificationProvider));
});

final notificationActionProvider = Provider<NotificationAction>((ref) {
  return NotificationAction(ref);
});

class NotificationAction {
  NotificationAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(notificationActionErrorProvider.notifier).state = null;
  }

  Future<bool> markAsRead(AppNotification item) async {
    if (item.normalizedStatus == NotificationStatus.read) {
      return true;
    }

    _ref.read(notificationActionLoadingProvider.notifier).state = true;
    _ref.read(notificationActionErrorProvider.notifier).state = null;

    try {
      await _ref.read(notificationApiProvider).markAsRead(item.id);
      final current = _ref.read(readNotificationIdsProvider);
      _ref.read(readNotificationIdsProvider.notifier).state = <String>{
        ...current,
        item.id,
      };
      return true;
    } on ApiException catch (error) {
      developer.log(error.toString(), name: 'NotificationProvider');
      _ref.read(notificationActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected notification mark-read error: $error',
        name: 'NotificationProvider',
        error: error,
        stackTrace: stackTrace,
      );
      _ref.read(notificationActionErrorProvider.notifier).state =
          'Unable to update notification right now.';
      return false;
    } finally {
      _ref.read(notificationActionLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> markAllAsRead() async {
    final items = _ref.read(notificationProvider);
    final unreadItems = items
        .where((item) => item.normalizedStatus == NotificationStatus.unread)
        .toList(growable: false);

    if (unreadItems.isEmpty) {
      return true;
    }

    _ref.read(notificationActionLoadingProvider.notifier).state = true;
    _ref.read(notificationActionErrorProvider.notifier).state = null;

    try {
      var allSuccess = true;
      final readSet = <String>{..._ref.read(readNotificationIdsProvider)};

      for (final item in unreadItems) {
        try {
          await _ref.read(notificationApiProvider).markAsRead(item.id);
          readSet.add(item.id);
        } on ApiException catch (error) {
          developer.log(error.toString(), name: 'NotificationProvider');
          allSuccess = false;
        } catch (error, stackTrace) {
          developer.log(
            'Unexpected mark-all notification error: $error',
            name: 'NotificationProvider',
            error: error,
            stackTrace: stackTrace,
          );
          allSuccess = false;
        }
      }

      _ref.read(readNotificationIdsProvider.notifier).state = readSet;

      if (!allSuccess) {
        _ref.read(notificationActionErrorProvider.notifier).state =
            'Some notifications could not be updated from server, but local state is refreshed.';
      }

      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected mark-all notifications failure: $error',
        name: 'NotificationProvider',
        error: error,
        stackTrace: stackTrace,
      );
      _ref.read(notificationActionErrorProvider.notifier).state =
          'Unable to mark all notifications as read.';
      return false;
    } finally {
      _ref.read(notificationActionLoadingProvider.notifier).state = false;
    }
  }

  void dismissNotification(String id) {
    final dismissed = _ref.read(dismissedNotificationIdsProvider);
    _ref.read(dismissedNotificationIdsProvider.notifier).state = <String>{
      ...dismissed,
      id,
    };
  }

  void clearAllLocalNotifications() {
    final currentItems = _ref.read(notificationProvider);
    _ref.read(dismissedNotificationIdsProvider.notifier).state = currentItems
        .map((item) => item.id)
        .toSet();
  }
}
