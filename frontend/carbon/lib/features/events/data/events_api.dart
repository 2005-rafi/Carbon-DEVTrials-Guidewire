import 'dart:io';

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/events/data/events_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsApi {
  EventsApi(this._dio);

  final Dio _dio;

  static const List<String> _eventListEndpointVariants = <String>[
    '/events/list',
    '/trigger-service/events/list',
    '/trigger-service/list',
    '/events',
  ];

  static const List<String> _eventReportEndpointVariants = <String>[
    '/events/report',
    '/trigger-service/events/report',
    '/trigger-service/report',
  ];

  static const List<String> _severityEndpointVariants = <String>[
    '/events/severity',
    '/trigger-service/events/severity',
    '/ai-risk-service/events/severity',
  ];

  Future<List<EventRecord>> fetchEvents() async {
    try {
      final raw = await _getWithFallback(
        endpointVariants: _eventListEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.triggerServiceBaseUrl,
        ],
      );

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

      if (records.isEmpty) {
        return EventRecord.fallbackList();
      }

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
      await _postWithFallback(
        endpointVariants: _eventReportEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.triggerServiceBaseUrl,
        ],
        payload: payload,
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to report disruption at this time.',
      );
    }
  }

  Future<Map<String, String>> _fetchSeverityMap() async {
    try {
      final raw = await _getWithFallback(
        endpointVariants: _severityEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.triggerServiceBaseUrl,
          ApiConfig.aiRiskServiceBaseUrl,
        ],
      );

      return _extractSeverityMap(raw);
    } on DioException {
      return <String, String>{};
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<dynamic> _getWithFallback({
    required List<String> endpointVariants,
    required List<String> fallbackBaseUrls,
  }) async {
    DioException? lastError;
    final attempted = <String>{};

    Future<dynamic> attempt(String url) async {
      if (attempted.contains(url)) {
        return null;
      }
      attempted.add(url);

      try {
        final response = await _dio.get<dynamic>(url);
        return response.data;
      } on DioException catch (error) {
        lastError = error;
        return null;
      }
    }

    for (final endpoint in endpointVariants) {
      final result = await attempt(endpoint);
      if (result != null) {
        return result;
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        final result = await attempt('$baseUrl$endpoint');
        if (result != null) {
          return result;
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
    throw Exception('Unable to fetch events.');
  }

  Future<void> _postWithFallback({
    required List<String> endpointVariants,
    required List<String> fallbackBaseUrls,
    required Map<String, dynamic> payload,
  }) async {
    DioException? lastError;
    final attempted = <String>{};

    Future<bool> attempt(String url) async {
      if (attempted.contains(url)) {
        return false;
      }
      attempted.add(url);

      try {
        await _dio.post<dynamic>(url, data: payload);
        return true;
      } on DioException catch (error) {
        lastError = error;
        return false;
      }
    }

    for (final endpoint in endpointVariants) {
      if (await attempt(endpoint)) {
        return;
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        if (await attempt('$baseUrl$endpoint')) {
          return;
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
    throw Exception('Unable to submit event action.');
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

  Map<String, String> _extractSeverityMap(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return <String, String>{};
    }

    final output = <String, String>{};
    final candidates = <dynamic>[raw['data'], raw['items'], raw['severity']];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        for (final entry in candidate.entries) {
          final key = entry.key.trim();
          final value = entry.value;
          if (key.isNotEmpty && value is String && value.trim().isNotEmpty) {
            output[key] = value.trim();
          }
        }
      }

      if (candidate is List) {
        for (final item in candidate.whereType<Map<String, dynamic>>()) {
          final id = item['id'] ?? item['event_id'];
          final severity = item['severity'] ?? item['level'];
          if (id is String && severity is String) {
            final cleanedId = id.trim();
            final cleanedSeverity = severity.trim();
            if (cleanedId.isNotEmpty && cleanedSeverity.isNotEmpty) {
              output[cleanedId] = cleanedSeverity;
            }
          }
        }
      }
    }

    return output;
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    final serverMessage = _extractServerMessage(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Events request timed out. Pull to refresh and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to connect to events service. Check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return const ApiException(
            'Please sign in to access disruption events.',
            statusCode: HttpStatus.unauthorized,
          );
        }
        if (code == HttpStatus.forbidden) {
          return const ApiException(
            'You are not allowed to perform this event action.',
            statusCode: HttpStatus.forbidden,
          );
        }
        return ApiException(serverMessage ?? genericMessage, statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('Events request canceled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(serverMessage ?? genericMessage);
    }
  }

  String? _extractServerMessage(dynamic responseData) {
    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final candidates = <dynamic>[
      responseData['message'],
      responseData['detail'],
      responseData['description'],
      responseData['error'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
      if (candidate is Map<String, dynamic>) {
        final nested = candidate['message'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
    }

    return null;
  }
}

final eventsApiProvider = Provider<EventsApi>((ref) {
  return EventsApi(ref.read(apiClientProvider));
});
