import 'dart:io';

import 'package:carbon/core/network/api_error_mapper.dart';
import 'package:carbon/core/network/api_endpoints.dart';
import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/core/providers/auth_provider.dart';
import 'package:carbon/core/providers/network_provider.dart';
import 'package:carbon/features/claims/data/claims_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClaimsApi {
  ClaimsApi(this._dio, {String? Function()? userIdProvider})
    : _userIdProvider = userIdProvider;

  final Dio _dio;
  final String? Function()? _userIdProvider;

  Future<List<ClaimRecord>> fetchClaims() async {
    final userId = _requireUserId();

    try {
      final raw = await _get(ApiEndpoints.claimsByUserId(userId));

      final records = _extractClaims(
        raw,
      ).map(ClaimRecord.fromMap).toList(growable: false);
      return records;
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to load claims right now.',
      );
    }
  }

  Future<void> createAutoClaim({required String eventId}) async {
    final normalizedEventId = eventId.trim();
    if (normalizedEventId.isEmpty) {
      throw const ApiException('Event id is required to create an auto-claim.');
    }
    final userId = _requireUserId();

    try {
      await _dio.post<dynamic>(
        ApiEndpoints.claimsAuto,
        data: <String, dynamic>{
          'event_id': normalizedEventId,
          'user_id': userId,
        },
      );
    } on DioException catch (error) {
      throw _toFriendlyApiException(
        error,
        genericMessage: 'Unable to auto-create claim right now.',
      );
    }
  }

  Future<dynamic> _get(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    return response.data;
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
      raw['value'],
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
      unauthorizedMessage: 'Please sign in to view claims.',
      validationMessage:
          'Claim details look invalid. Please review and try again.',
      businessMessages: const <int, String>{
        HttpStatus.internalServerError:
            'Claims service is temporarily unavailable. Please retry shortly.',
      },
    );
  }
}

final claimsApiProvider = Provider<ClaimsApi>((ref) {
  return ClaimsApi(
    ref.read(apiClientProvider),
    userIdProvider: () => ref.read(currentUserIdProvider),
  );
});
