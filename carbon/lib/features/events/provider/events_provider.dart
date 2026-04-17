import 'dart:developer' as developer;

import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/events/data/events_api.dart';
import 'package:carbon/features/events/data/events_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventsErrorProvider = StateProvider<String?>((ref) => null);
final eventsActionErrorProvider = StateProvider<String?>((ref) => null);
final eventsActionLoadingProvider = StateProvider<bool>((ref) => false);

final eventStatusFilterProvider = StateProvider<EventStatus?>((ref) => null);
final eventSeverityFilterProvider = StateProvider<EventSeverity?>(
  (ref) => null,
);
final eventsSearchQueryProvider = StateProvider<String>((ref) => '');

final eventsAsyncProvider = FutureProvider<List<EventRecord>>((ref) async {
  ref.read(eventsErrorProvider.notifier).state = null;
  try {
    return await ref.read(eventsApiProvider).fetchEvents();
  } on ApiException catch (error) {
    developer.log(error.toString(), name: 'EventsProvider');
    ref.read(eventsErrorProvider.notifier).state = error.message;
    return const <EventRecord>[];
  } catch (error, stackTrace) {
    developer.log(
      'Unexpected events load error: $error',
      name: 'EventsProvider',
      error: error,
      stackTrace: stackTrace,
    );
    ref.read(eventsErrorProvider.notifier).state =
        'Unable to load disruption events right now.';
    return const <EventRecord>[];
  }
});

final eventsProvider = Provider<List<EventRecord>>((ref) {
  return ref
      .watch(eventsAsyncProvider)
      .maybeWhen(
        data: (records) => records,
        orElse: () => const <EventRecord>[],
      );
});

final filteredEventsProvider = Provider<List<EventRecord>>((ref) {
  final records = ref.watch(eventsProvider);
  final selectedStatus = ref.watch(eventStatusFilterProvider);
  final selectedSeverity = ref.watch(eventSeverityFilterProvider);
  final query = ref.watch(eventsSearchQueryProvider).trim().toLowerCase();

  return records
      .where((record) {
        final matchesStatus = selectedStatus == null
            ? true
            : record.normalizedStatus == selectedStatus;

        final matchesSeverity = selectedSeverity == null
            ? true
            : record.normalizedSeverity == selectedSeverity;

        final matchesQuery = query.isEmpty
            ? true
            : record.id.toLowerCase().contains(query) ||
                  record.title.toLowerCase().contains(query) ||
                  record.description.toLowerCase().contains(query) ||
                  record.location.toLowerCase().contains(query);

        return matchesStatus && matchesSeverity && matchesQuery;
      })
      .toList(growable: false);
});

final eventsSummaryProvider = Provider<EventsSummary>((ref) {
  return EventsSummary.fromRecords(ref.watch(eventsProvider));
});

final eventsActionProvider = Provider<EventsAction>((ref) {
  return EventsAction(ref);
});

class EventsAction {
  EventsAction(this._ref);

  final Ref _ref;

  void clearError() {
    _ref.read(eventsActionErrorProvider.notifier).state = null;
  }

  Future<bool> reportEvent({
    required String title,
    required String description,
    required String location,
    required EventSeverity severity,
  }) async {
    _ref.read(eventsActionLoadingProvider.notifier).state = true;
    _ref.read(eventsActionErrorProvider.notifier).state = null;

    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'location': location,
      'severity': severity.name,
      'status': 'active',
      'date': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _ref.read(eventsApiProvider).reportEvent(payload);
      return true;
    } on ApiException catch (error) {
      developer.log(error.toString(), name: 'EventsProvider');
      _ref.read(eventsActionErrorProvider.notifier).state = error.message;
      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected events action error: $error',
        name: 'EventsProvider',
        error: error,
        stackTrace: stackTrace,
      );
      _ref.read(eventsActionErrorProvider.notifier).state =
          'Unable to report disruption right now. Please try again.';
      return false;
    } finally {
      _ref.read(eventsActionLoadingProvider.notifier).state = false;
    }
  }
}
