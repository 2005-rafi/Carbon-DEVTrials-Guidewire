import 'dart:io';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/policy/data/policy_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PolicyApi {
  PolicyApi(this._dio, {String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  final Dio _dio;
  final String? Function()? _userIdProvider;

  Future<PolicyDetails> fetchPolicyDetails() async {
    final userId = _requireUserId();

    try {
      final raw = await _get(ApiEndpoints.policyByUserId(userId));

      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          return PolicyDetails.fromMap(data);
        }
        return PolicyDetails.fromMap(raw);
      }

      return PolicyDetails.empty();
    } on DioException catch (error) {
      final friendly = _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load policy details right now.',
      );

      if (friendly.statusCode == HttpStatus.notFound) {
        return PolicyDetails.empty();
      }

      throw friendly;
    }
  }

  Future<void> acceptPolicy() async {
    final userId = _requireUserId();
    final details = await fetchPolicyDetails();
    final premium = _resolvePremiumForCreate(details);
    final plan = details.planName.trim().isNotEmpty
        ? details.planName.trim()
        : 'Carbon Gold';

    try {
      await _post(
        ApiEndpoints.policyCreate,
        payload: <String, dynamic>{
          'user_id': userId,
          'premium': premium,
          'plan': plan,
        },
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to accept policy at the moment.',
      );
    }
  }

  Future<void> declinePolicy() async {
    final userId = _requireUserId();

    try {
      await _post(
        ApiEndpoints.policyCancelByUserId(userId),
        payload: const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to decline policy at the moment.',
      );
    }
  }

  Future<dynamic> _get(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    return response.data;
  }

  Future<void> _post(
    String endpoint, {
    required Map<String, dynamic> payload,
  }) async {
    await _dio.post<dynamic>(endpoint, data: payload);
  }

  double _resolvePremiumForCreate(PolicyDetails details) {
    final parsed = _parsePremium(details.premium);
    if (parsed != null && parsed > 0) {
      return parsed;
    }

    // Keep a safe default aligned with the backend endpoint documentation.
    return 250.0;
  }

  double? _parsePremium(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) {
      return null;
    }
    return double.tryParse(cleaned);
  }

  String _requireUserId() {
    final candidate = _userIdProvider?.call()?.trim();
    if (candidate == null || candidate.isEmpty) {
      throw const ApiException(
        'User identity is missing. Please sign in again.',
        statusCode: HttpStatus.unauthorized,
      );
    }
    return candidate;
  }

  ApiException _toFriendlyApiException(
    DioException error, {
    required String genericMessage,
  }) {
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage: 'Please sign in again to access policy details.',
      forbiddenMessage: 'You are not allowed to perform this policy action.',
      notFoundMessage: 'No active policy found for this account.',
      validationMessage:
          'Policy request could not be processed. Please verify your details.',
    );
  }
}

final policyApiProvider = Provider<PolicyApi>((ref) {
  return PolicyApi(
    ref.read(apiClientProvider),
    userIdProvider: () => ref.read(currentUserIdProvider),
  );
});
