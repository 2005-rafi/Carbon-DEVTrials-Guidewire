import 'dart:io';

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/payout/data/payout_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayoutApi {
  PayoutApi(this._dio);

  final Dio _dio;

  static const List<String> _historyEndpointVariants = <String>[
    '/payout/history',
    '/payout-service/payout/history',
    '/payout-service/history',
  ];

  static const List<String> _statusEndpointVariants = <String>[
    '/payout/status',
    '/payout-service/payout/status',
    '/payout-service/status',
  ];

  Future<List<PayoutRecord>> fetchPayouts() async {
    try {
      final raw = await _getWithFallback(
        endpointVariants: _historyEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.payoutServiceBaseUrl,
        ],
      );

      final records = _extractPayouts(
        raw,
      ).map(PayoutRecord.fromMap).toList(growable: false);

      if (records.isEmpty) {
        return PayoutRecord.fallbackList();
      }
      return records;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load payout history right now.',
      );
    }
  }

  Future<void> initiatePayout() async {
    try {
      await _postWithFallback(
        endpointVariants: _statusEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.payoutServiceBaseUrl,
        ],
        payload: const <String, dynamic>{'action': 'initiate'},
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to initiate payout right now.',
      );
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
    throw Exception('Unable to fetch payout data.');
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
    throw Exception('Unable to complete payout action.');
  }

  List<Map<String, dynamic>> _extractPayouts(dynamic raw) {
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
      raw['payouts'],
      raw['transactions'],
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
    final serverMessage = _extractServerMessage(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Payout request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to connect to payout service. Check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return const ApiException(
            'Please sign in to access payout information.',
            statusCode: HttpStatus.unauthorized,
          );
        }
        if (code == HttpStatus.forbidden) {
          return const ApiException(
            'You do not have permission for this payout action.',
            statusCode: HttpStatus.forbidden,
          );
        }
        return ApiException(serverMessage ?? genericMessage, statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('Payout request canceled.');
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

final payoutApiProvider = Provider<PayoutApi>((ref) {
  return PayoutApi(ref.read(apiClientProvider));
});
