import 'dart:io';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/events/data/events_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsApi {
  EventsApi(this._dio);

  final Dio _dio;

  Future<List<EventRecord>> fetchEvents() async {
    try {
      final raw = await _get(ApiEndpoints.triggerActive);

      final severityMap = await _fetchSeverityMap();

      final records = _extractEvents(raw)
          .map((entry) {
            final enriched = <String, dynamic>{...entry};
            final id = enriched['id'] ?? enriched['event_id'];
            if (id is String) {
              final severityOverride = severityMap[id];
              if (severityOverride != null && severityOverride.isNotEmpty) {
                enriched['severity'] = severityOverride;
              }
            }
            return EventRecord.fromMap(enriched);
          })
          .toList(growable: false);
      return records;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load disruption events right now.',
      );
    }
  }

  Future<void> reportEvent(Map<String, dynamic> payload) async {
    try {
      final eventType = _extractEventType(payload);
      final duration = _extractDuration(payload);
      await _post(
        ApiEndpoints.triggerMock,
        payload: <String, dynamic>{
          'event_type': eventType,
          'duration': duration,
        },
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to report disruption at this time.',
      );
    }
  }

  Future<Map<String, String>> _fetchSeverityMap() async {
    // Current contract does not expose an event-severity map endpoint.
    return <String, String>{};
  }

  Future<dynamic> _get(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    return response.data;
  }

  Future<void> _post(String endpoint, {Map<String, dynamic>? payload}) async {
    await _dio.post<dynamic>(
      endpoint,
      data: payload ?? const <String, dynamic>{},
    );
  }

  String _extractDuration(Map<String, dynamic> payload) {
    final candidates = <dynamic>[
      payload['duration'],
      payload['event_duration'],
      payload['window'],
    ];

    final raw = candidates
        .whereType<String>()
        .map((v) => v.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (raw.isNotEmpty) {
      return raw;
    }

    return '4h (Heavy Disruption)';
  }

  String _extractEventType(Map<String, dynamic> payload) {
    final candidates = <dynamic>[
      payload['event_type'],
      payload['type'],
      payload['title'],
      payload['description'],
    ];

    final raw = candidates
        .whereType<String>()
        .map((v) => v.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (raw.isEmpty) {
      return 'WEATHER';
    }

    final normalized = raw.toUpperCase();
    if (normalized.contains('TRAFFIC')) {
      return 'TRAFFIC';
    }
    if (normalized.contains('STRIKE')) {
      return 'STRIKE';
    }
    if (normalized.contains('PLATFORM')) {
      return 'PLATFORM';
    }
    if (normalized.contains('OUTAGE') || normalized.contains('SYSTEM')) {
      return 'PLATFORM';
    }
    if (normalized.contains('RAIN') ||
        normalized.contains('FLOOD') ||
        normalized.contains('WEATHER')) {
      return 'WEATHER';
    }

    return 'WEATHER';
  }

  List<Map<String, dynamic>> _extractEvents(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (raw is! Map<String, dynamic>) {
      return <Map<String, dynamic>>[];
    }

    final candidates = <dynamic>[
      raw['data'],
      raw['items'],
      raw['results'],
      raw['events'],
      raw['disruptions'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }
    }

    return <Map<String, dynamic>>[];
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage: 'Please sign in to access disruption events.',
      forbiddenMessage: 'You are not allowed to perform this event action.',
      validationMessage:
          'Event details are invalid. Please review and try again.',
      businessMessages: const <int, String>{
        HttpStatus.internalServerError:
            'Disruption services are temporarily unstable. Please retry shortly.',
      },
    );
  }
}

final eventsApiProvider = Provider<EventsApi>((ref) {
  return EventsApi(ref.read(apiClientProvider));
});
