import 'dart:io';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/payout/data/payout_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayoutApi {
  PayoutApi(this._dio, {String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  final Dio _dio;
  final String? Function()? _userIdProvider;

  Future<List<PayoutRecord>> fetchPayouts() async {
    final userId = _requireUserId();

    try {
      final raw = await _get(ApiEndpoints.payoutByUserId(userId));

      final records = _extractPayouts(
        raw,
      ).map(PayoutRecord.fromMap).toList(growable: false);
      return records;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load payout history right now.',
      );
    }
  }

  Future<void> initiatePayout() async {
    final userId = _requireUserId();

    try {
      final claimsRaw = await _get(ApiEndpoints.claimsByUserId(userId));
      final claim = _resolveClaimForPayout(claimsRaw);
      if (claim == null) {
        throw const ApiException(
          'No eligible claim found for payout initiation.',
        );
      }

      await _post(
        ApiEndpoints.payoutProcess,
        payload: <String, dynamic>{'claim_id': claim.claimId},
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to initiate payout right now.',
      );
    }
  }

  Future<void> retryPayout(String payoutId) async {
    final cleanedId = payoutId.trim();
    if (cleanedId.isEmpty) {
      throw const ApiException('Invalid payout identifier.');
    }

    try {
      await _post(
        ApiEndpoints.payoutRetry,
        payload: <String, dynamic>{'payout_id': cleanedId},
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to retry payout right now.',
      );
    }
  }

  _ClaimPayoutRequest? _resolveClaimForPayout(dynamic claimsRaw) {
    final claims = _extractPayouts(claimsRaw);
    for (final claim in claims) {
      final claimId = _extractClaimId(claim);
      if (claimId == null) {
        continue;
      }

      final amount = _extractClaimAmount(claim);
      if (amount <= 0) {
        continue;
      }

      return _ClaimPayoutRequest(claimId: claimId, amount: amount);
    }

    return null;
  }

  String? _extractClaimId(Map<String, dynamic> claim) {
    final raw = (claim['claim_id'] ?? claim['id'])?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(raw)) {
      return null;
    }

    return raw;
  }

  double _extractClaimAmount(Map<String, dynamic> claim) {
    final raw = claim['amount'] ?? claim['claim_amount'] ?? claim['value'];
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw) ?? 0.0;
    }
    return 0.0;
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
      raw['value'],
      raw['claims'],
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
    return ApiErrorMapper.fromDio(
      error,
      fallbackMessage: genericMessage,
      unauthorizedMessage: 'Please sign in to access payout information.',
      forbiddenMessage: 'You do not have permission for this payout action.',
      validationMessage:
          'Payout request details are invalid. Please verify and retry.',
    );
  }
}

class _ClaimPayoutRequest {
  const _ClaimPayoutRequest({required this.claimId, required this.amount});

  final String claimId;
  final double amount;
}

final payoutApiProvider = Provider<PayoutApi>((ref) {
  return PayoutApi(
    ref.read(apiClientProvider),
    userIdProvider: () => ref.read(currentUserIdProvider),
  );
});
