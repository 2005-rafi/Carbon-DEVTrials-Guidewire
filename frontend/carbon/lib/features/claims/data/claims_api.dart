import 'dart:io';

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/claims/data/claims_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClaimsApi {
  ClaimsApi(this._dio);

  final Dio _dio;

  static const List<String> _claimsListEndpointVariants = <String>[
    '/claims/list',
    '/claims-service/claims/list',
    '/claims-service/list',
  ];

  Future<List<ClaimRecord>> fetchClaims() async {
    try {
      final raw = await _getWithFallback(
        endpointVariants: _claimsListEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.claimsServiceBaseUrl,
        ],
      );

      final records = _extractClaims(
        raw,
      ).map(ClaimRecord.fromMap).toList(growable: false);

      if (records.isEmpty) {
        return ClaimRecord.fallbackList();
      }

      return records;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load claims right now.',
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
      final data = await attempt(endpoint);
      if (data != null) {
        return data;
      }
    }

    for (final baseUrl in fallbackBaseUrls) {
      for (final endpoint in endpointVariants) {
        final data = await attempt('$baseUrl$endpoint');
        if (data != null) {
          return data;
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }

    throw Exception('Unable to fetch claims.');
  }

  List<Map<String, dynamic>> _extractClaims(dynamic raw) {
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
      raw['claims'],
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
          'Claims service timed out. Pull to refresh and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Unable to connect to backend. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return const ApiException(
            'Please sign in to view claims.',
            statusCode: HttpStatus.unauthorized,
          );
        }

        return ApiException(serverMessage ?? genericMessage, statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('Claim request canceled.');
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

final claimsApiProvider = Provider<ClaimsApi>((ref) {
  return ClaimsApi(ref.read(apiClientProvider));
});
