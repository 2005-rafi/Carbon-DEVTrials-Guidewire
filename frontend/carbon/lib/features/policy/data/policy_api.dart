import 'dart:io';

import 'package:carbon/core/network/api_config.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/policy/data/policy_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PolicyApi {
  PolicyApi(this._dio);

  final Dio _dio;

  static const List<String> _detailsEndpointVariants = <String>[
    '/policy/details',
    '/policy-pricing/policy/details',
    '/policy-pricing-service/policy/details',
  ];

  static const List<String> _acceptEndpointVariants = <String>[
    '/policy/accept',
    '/policy-pricing/policy/accept',
    '/policy-pricing-service/policy/accept',
  ];

  Future<PolicyDetails> fetchPolicyDetails() async {
    try {
      final raw = await _getWithFallback(
        endpointVariants: _detailsEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.policyServiceBaseUrl,
        ],
      );

      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          return PolicyDetails.fromMap(data);
        }
        return PolicyDetails.fromMap(raw);
      }

      return PolicyDetails.fallback();
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load policy details right now.',
      );
    }
  }

  Future<void> acceptPolicy() async {
    try {
      await _postWithFallback(
        endpointVariants: _acceptEndpointVariants,
        fallbackBaseUrls: <String>[
          ApiConfig.gatewayBaseUrl,
          ApiConfig.policyServiceBaseUrl,
        ],
        payload: const <String, dynamic>{'accept': true},
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to accept policy at the moment.',
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

    throw Exception('Unable to fetch policy data.');
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

    throw Exception('Unable to complete policy action.');
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
          'Request timed out while contacting policy service. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Could not reach backend services. Please check connectivity.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == HttpStatus.unauthorized) {
          return const ApiException(
            'Please sign in again to access policy details.',
            statusCode: HttpStatus.unauthorized,
          );
        }
        if (code == HttpStatus.forbidden) {
          return const ApiException(
            'You are not allowed to perform this policy action.',
            statusCode: HttpStatus.forbidden,
          );
        }
        return ApiException(serverMessage ?? genericMessage, statusCode: code);
      case DioExceptionType.cancel:
        return const ApiException('Request was canceled.');
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

    final directCandidates = <dynamic>[
      responseData['message'],
      responseData['detail'],
      responseData['description'],
      responseData['error'],
    ];

    for (final candidate in directCandidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
      if (candidate is Map<String, dynamic>) {
        final message = candidate['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }

    return null;
  }
}

final policyApiProvider = Provider<PolicyApi>((ref) {
  return PolicyApi(ref.read(apiClientProvider));
});
